import Foundation
import OSLog

public struct OpenMeteoResponse: Decodable {
    public struct CurrentWeather: Decodable {
        public let temperature: Double
        public let weathercode: Int
        public let time: String?
    }
    public struct Daily: Decodable {
        public let temperature_2m_max: [Double]
        public let temperature_2m_min: [Double]
    }
    public struct Hourly: Decodable {
        public let time: [String]
        public let temperature_2m: [Double]
        public let weathercode: [Int]
    }

    public let current_weather: CurrentWeather?
    public let daily: Daily?
    public let hourly: Hourly?
}

@MainActor
public final class WeatherService {
    public private(set) var currentState: WeatherState
    private var refreshTimer: Timer?

    public init(initialState: WeatherState) {
        self.currentState = initialState
        Task { [weak self] in
            await self?.refresh()
        }
        self.startPeriodicUpdates()
    }

    public func stopPeriodicUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func startPeriodicUpdates() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 900.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    public func refresh() async {
        var latitude = 41.0082
        var longitude = 28.9784
        var city = currentState.cityName

        // 1. IP tabanlı konum (HTTPS; düz HTTP istekleri App Transport Security tarafından engellenir)
        if let geoURL = URL(string: "https://ipwho.is/?fields=success,city,latitude,longitude") {
            struct GeoResponse: Decodable {
                let success: Bool
                let city: String?
                let latitude: Double?
                let longitude: Double?
            }
            do {
                let (geoData, _) = try await URLSession.shared.data(from: geoURL)
                let geo = try JSONDecoder().decode(GeoResponse.self, from: geoData)
                if geo.success, let lt = geo.latitude, let ln = geo.longitude {
                    latitude = lt
                    longitude = ln
                    if let c = geo.city, !c.isEmpty { city = c }
                } else {
                    Logger.general.warning("Weather geolocation returned no coordinates url=\(geoURL.absoluteString, privacy: .public)")
                }
            } catch {
                Logger.general.warning("Weather geolocation failed url=\(geoURL.absoluteString, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            }
        }

        // 2. Live Weather Query
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true&daily=temperature_2m_max,temperature_2m_min&hourly=temperature_2m,weathercode&timezone=auto"

        guard let url = URL(string: urlString) else {
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                Logger.general.error("Weather request failed status=\(status, privacy: .public) body=\(String(decoding: data.prefix(512), as: UTF8.self), privacy: .public)")
                return
            }

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(OpenMeteoResponse.self, from: data)

            guard let current = decoded.current_weather else {
                return
            }

            let condition = Self.mapWeatherCode(code: current.weathercode)
            let high = decoded.daily?.temperature_2m_max.first ?? (current.temperature + 3.0)
            let low = decoded.daily?.temperature_2m_min.first ?? (current.temperature - 4.0)

            var hourlyList: [HourlyForecast] = []
            if let hourly = decoded.hourly {
                // Saatlik seri gece yarısından başlar; mevcut saatten itibaren sonraki 6 saati göster
                let availableCount = min(hourly.time.count, hourly.temperature_2m.count)
                let currentHourPrefix = current.time.map { String($0.prefix(13)) } ?? ""
                let startIndex = hourly.time.prefix(availableCount).firstIndex { $0 >= currentHourPrefix } ?? 0
                let endIndex = min(startIndex + 6, availableCount)
                for i in startIndex..<endIndex {
                    let fullTime = hourly.time[i]
                    let hourString = fullTime.components(separatedBy: "T").last ?? fullTime
                    let code = hourly.weathercode.indices.contains(i) ? hourly.weathercode[i] : current.weathercode
                    let symbol = Self.mapWeatherCode(code: code).symbol
                    hourlyList.append(
                        HourlyForecast(
                            id: "hourly_\(i)_\(hourString)",
                            hour: hourString,
                            temperatureCelsius: hourly.temperature_2m[i],
                            symbolName: symbol
                        )
                    )
                }
            }

            self.currentState = WeatherState(
                cityName: city,
                temperatureCelsius: current.temperature,
                conditionText: condition.text,
                symbolName: condition.symbol,
                highCelsius: high,
                lowCelsius: low,
                hourly: hourlyList.isEmpty ? self.currentState.hourly : hourlyList,
                lastUpdated: Date()
            )
        } catch {
            // Geçici ağ hatasında önbellekteki durum korunur
            Logger.general.warning("Weather refresh failed error=\(error.localizedDescription, privacy: .public)")
        }
    }

    public static nonisolated func mapWeatherCode(code: Int) -> (text: String, symbol: String) {
        switch code {
        case 0:
            return ("Clear sky", "sun.max.fill")
        case 1:
            return ("Mainly clear", "sun.max.fill")
        case 2:
            return ("Partly cloudy", "cloud.sun.fill")
        case 3:
            return ("Overcast", "cloud.fill")
        case 45, 48:
            return ("Fog", "cloud.fog.fill")
        case 51, 53, 55:
            return ("Drizzle", "cloud.drizzle.fill")
        case 61, 63, 65:
            return ("Rain", "cloud.rain.fill")
        case 71, 73, 75:
            return ("Snow", "cloud.snow.fill")
        case 80, 81, 82:
            return ("Showers", "cloud.heavyrain.fill")
        case 95, 96, 99:
            return ("Thunderstorm", "cloud.bolt.rain.fill")
        default:
            return ("Cloudy", "cloud.fill")
        }
    }
}
