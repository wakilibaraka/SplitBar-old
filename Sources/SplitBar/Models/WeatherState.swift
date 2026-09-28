import Foundation

public struct HourlyForecast: Equatable, Sendable, Identifiable {
    public let id: String
    public let hour: String
    public let temperatureCelsius: Double
    public let symbolName: String

    public init(
        id: String,
        hour: String,
        temperatureCelsius: Double,
        symbolName: String
    ) {
        self.id = id
        self.hour = hour
        self.temperatureCelsius = temperatureCelsius
        self.symbolName = symbolName
    }
}

public struct WeatherState: Equatable, Sendable {
    public let cityName: String
    public let temperatureCelsius: Double
    public let conditionText: String
    public let symbolName: String
    public let highCelsius: Double
    public let lowCelsius: Double
    public let hourly: [HourlyForecast]
    public let lastUpdated: Date

    public var formattedTemperature: String {
        "\(Int(round(temperatureCelsius)))°"
    }

    public init(
        cityName: String,
        temperatureCelsius: Double,
        conditionText: String,
        symbolName: String,
        highCelsius: Double,
        lowCelsius: Double,
        hourly: [HourlyForecast],
        lastUpdated: Date
    ) {
        self.cityName = cityName
        self.temperatureCelsius = temperatureCelsius
        self.conditionText = conditionText
        self.symbolName = symbolName
        self.highCelsius = highCelsius
        self.lowCelsius = lowCelsius
        self.hourly = hourly
        self.lastUpdated = lastUpdated
    }

    public static func defaultSample() -> WeatherState {
        let sampleHourly: [HourlyForecast] = [
            HourlyForecast(id: "h1", hour: "Now", temperatureCelsius: 21.0, symbolName: "sun.max.fill"),
            HourlyForecast(id: "h2", hour: "19:00", temperatureCelsius: 20.0, symbolName: "sun.max.fill"),
            HourlyForecast(id: "h3", hour: "20:00", temperatureCelsius: 19.0, symbolName: "cloud.sun.fill"),
            HourlyForecast(id: "h4", hour: "21:00", temperatureCelsius: 18.0, symbolName: "cloud.fill"),
            HourlyForecast(id: "h5", hour: "22:00", temperatureCelsius: 17.0, symbolName: "cloud.fill"),
            HourlyForecast(id: "h6", hour: "23:00", temperatureCelsius: 16.0, symbolName: "cloud.rain.fill")
        ]
        return WeatherState(
            cityName: "Istanbul",
            temperatureCelsius: 21.0,
            conditionText: "Mostly Sunny",
            symbolName: "sun.max.fill",
            highCelsius: 24.0,
            lowCelsius: 15.0,
            hourly: sampleHourly,
            lastUpdated: Date()
        )
    }
}
