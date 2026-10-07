import AppKit
import SwiftUI

struct DateWidget: View {
    let contentHeight: CGFloat

    var body: some View {
        WidgetCard(title: "Date", symbol: "calendar", tint: .red, minContentHeight: contentHeight) {
            VStack(spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide)).uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.red)
                    .tracking(1.5)
                Text(Date.now.formatted(.dateTime.day()))
                    .font(.system(size: 44, weight: .light, design: .rounded))
                Text(Date.now.formatted(.dateTime.month(.wide)).uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
}


struct SystemRingsWidget: View {
    let cpuPercent: Double
    let memoryPercent: Double
    let diskPercent: Double
    let batteryLevel: Int
    let processCount: Int
    let contentHeight: CGFloat
    var state = WidgetState.loaded

    private var uptimeText: String {
        let totalMinutes = Int(ProcessInfo.processInfo.systemUptime / 60)
        if totalMinutes < 60 {
            return "\(totalMinutes) mins"
        }
        return "\(totalMinutes / 60) hrs"
    }

    var body: some View {
        WidgetCard(title: "System", symbol: "cpu", tint: .blue, minContentHeight: contentHeight) {
            if state == .loaded {
                VStack(spacing: 10) {
                    HStack(spacing: 0) {
                        ringDial(value: cpuPercent / 100, color: .blue, label: "CPU")
                        ringDial(value: memoryPercent / 100, color: .purple, label: "MEM")
                        ringDial(value: diskPercent / 100, color: .green, label: "DISK")
                        ringDial(value: Double(batteryLevel) / 100, color: .orange, label: "BATT")
                    }
                    HStack {
                        Text("Uptime \(uptimeText)")
                        Spacer(minLength: 0)
                        Text("Processes \(processCount)")
                    }
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                }
            } else {
                WidgetStateBanner(state: state)
            }
        }
    }

    private func ringDial(value: Double, color: Color, label: String) -> some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 3)
                    .frame(width: 30, height: 30)
                Circle()
                    .trim(from: 0, to: min(1, max(0, value)))
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(-90))
                Text("\(Int((min(1, max(0, value)) * 100).rounded()))")
                    .font(.system(size: 7, weight: .bold, design: .rounded))
            }
            Text(label)
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


struct NetworkWidget: View {
    let downBytesPerSecond: UInt64
    let upBytesPerSecond: UInt64
    let peakDownBytesPerSecond: UInt64
    let peakUpBytesPerSecond: UInt64
    let contentHeight: CGFloat

    var body: some View {
        WidgetCard(title: "Network", symbol: "network", tint: .teal, minContentHeight: contentHeight) {
            VStack(spacing: 8) {
                networkRow(label: "DOWNLOAD", current: downBytesPerSecond, peak: peakDownBytesPerSecond)
                networkRow(label: "UPLOAD", current: upBytesPerSecond, peak: peakUpBytesPerSecond)
            }
        }
    }

    private func networkRow(label: String, current: UInt64, peak: UInt64) -> some View {
        HStack(alignment: .lastTextBaseline) {
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 1) {
                Text(rateText(current))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                Text("Peak \(rateText(peak))")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func rateText(_ bytesPerSecond: UInt64) -> String {
        let bytes = Double(bytesPerSecond)
        if bytes >= 1_000_000 {
            return String(format: "%.1f MB/s", bytes / 1_000_000)
        }
        return String(format: "%.1f KB/s", bytes / 1_000)
    }
}


struct WeatherWidget: View {
    let weather: WeatherState
    let contentHeight: CGFloat
    var state = WidgetState.loaded

    private static let dayParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private func dayLabel(for date: String, isFirst: Bool) -> String {
        if isFirst {
            return "Today"
        }
        if let parsed = Self.dayParser.date(from: date) {
            return Self.weekdayFormatter.string(from: parsed)
        }
        return date
    }

    var body: some View {
        WidgetCard(title: "Weather", symbol: "cloud.sun.fill", tint: .blue, minContentHeight: contentHeight) {
            if state == .loading {
                WidgetStateBanner(state: state)
            } else {
                VStack(alignment: .leading, spacing: 11) {
                    if state != .loaded {
                        WidgetStateBanner(state: state)
                    }
                HStack(spacing: 12) {
                    Image(systemName: weather.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 36))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weather.formattedTemperature)
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                        Text("\(weather.conditionText) · \(weather.cityName)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("H: \(Int(round(weather.highCelsius)))°  L: \(Int(round(weather.lowCelsius)))°")
                            .font(.system(size: 10, weight: .medium))
                        if !weather.isLive {
                            Text("Offline · sample")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                forecastSectionHeader("Hourly forecast")

                HStack(spacing: 0) {
                    ForEach(weather.hourly) { forecast in
                        VStack(spacing: 6) {
                            Text(forecast.hour)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.secondary)
                            Image(systemName: forecast.symbolName)
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 15))
                            Text("\(Int(round(forecast.temperatureCelsius)))°")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                forecastSectionHeader("14-day forecast")

                if weather.daily.isEmpty {
                    Text("Forecast unavailable while offline.")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 7) {
                        ForEach(Array(weather.daily.prefix(14).enumerated()), id: \.offset) { index, forecast in
                            VStack(spacing: 4) {
                                Text(dayLabel(for: forecast.date, isFirst: index == 0))
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Image(systemName: forecast.symbolName)
                                    .symbolRenderingMode(.multicolor)
                                    .font(.system(size: 15))
                                    .frame(height: 18)
                                HStack(spacing: 3) {
                                    Text("\(Int(round(forecast.highCelsius)))°")
                                        .font(.system(size: 8, weight: .semibold))
                                    Text("\(Int(round(forecast.lowCelsius)))°")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            }
        }
    }

    private func forecastSectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            Spacer()
            if title == "14-day forecast" {
                Text("Next 14 days")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 2)
    }

}


struct SystemResourcesWidget: View {    let contentHeight: CGFloat

    var body: some View {
        WidgetCard(
            title: "System resources",
            symbol: "chart.bar.fill",
            tint: .blue,
            minContentHeight: contentHeight
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Storage")
                        .font(.system(size: 10, weight: .semibold))
                    Spacer()
                    Text("412 GB / 512 GB")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.blue)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.08))
                        Capsule()
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * 0.80)
                    }
                }
                .frame(height: 7)

                HStack {
                    Text("Memory")
                        .font(.system(size: 10, weight: .semibold))
                    Spacer()
                    Text("12.9 GB in use")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.purple)
                }

                resourceBar("CPU", value: 0.31, valueText: "31%", tint: .blue)
                resourceBar("GPU", value: 0.57, valueText: "57%", tint: .purple)
            }
        }
    }

    private func resourceBar(_ title: String, value: CGFloat, valueText: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                Spacer()
                Text(valueText)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(tint)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule().fill(tint.opacity(0.7)).frame(width: geometry.size.width * value)
                }
            }
            .frame(height: 4)
        }
    }
}


struct PhotosWidget: View {
    let contentHeight: CGFloat

    var body: some View {
        WidgetCard(title: "Photos", symbol: "photo.on.rectangle.angled", tint: .blue, minContentHeight: contentHeight) {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 9)
                        .fill(
                            LinearGradient(
                                colors: photoColors(index),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: index == 1 ? "sun.horizon.fill" : "mountain.2.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .frame(height: 62)
                }
            }
            Text("A moment from your library")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private func photoColors(_ index: Int) -> [Color] {
        switch index {
        case 0: [Color.blue.opacity(0.7), Color.cyan.opacity(0.45)]
        case 1: [Color.orange.opacity(0.7), Color.pink.opacity(0.45)]
        default: [Color.purple.opacity(0.62), Color.blue.opacity(0.4)]
        }
    }
}


struct StickyNotesWidget: View {
    let contentHeight: CGFloat

    var body: some View {
        WidgetCard(title: "Sticky notes", symbol: "note.text", tint: .orange, minContentHeight: contentHeight) {
            Text("Remember to take a pause, stretch, and enjoy the little things.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                .padding(10)
                .background(Color.yellow.opacity(0.22), in: RoundedRectangle(cornerRadius: 10))
            Text("Personal note · just now")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}


struct WatchlistWidget: View {
    let contentHeight: CGFloat
    private let assets: [(String, String, String, Color)] = [
        ("NVDA", "$203.65", "+2.4%", .green),
        ("META", "$151.74", "+1.2%", .green),
        ("TSLA", "$177.90", "−0.8%", .red)
    ]

    var body: some View {
        WidgetCard(title: "Watchlist", symbol: "chart.xyaxis.line", tint: .green, minContentHeight: contentHeight) {
            VStack(spacing: 9) {
                ForEach(assets, id: \.0) { ticker, price, change, color in
                    HStack {
                        Text(ticker)
                            .font(.system(size: 9, weight: .bold))
                        Spacer()
                        Text(price)
                            .font(.system(size: 9, weight: .medium))
                        Text(change)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(color)
                            .frame(width: 37, alignment: .trailing)
                    }
                }
            }
        }
    }
}


struct MediaWidget: View {
    @ObservedObject var model: TaskbarConceptState
    let contentHeight: CGFloat

    private var isIdle: Bool { model.nowPlaying == .idle() }

    var body: some View {
        WidgetCard(title: "Now playing", symbol: "music.note", tint: .purple, minContentHeight: contentHeight) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(LinearGradient(colors: [.purple.opacity(0.8), .pink.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay {
                            Image(systemName: isIdle ? "music.note" : "waveform")
                                .foregroundStyle(.white)
                        }
                        .frame(width: 43, height: 43)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(isIdle ? "Nothing playing" : model.nowPlaying.trackTitle)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                        Text(isIdle ? "Play Music or Spotify" : nowPlayingSubtitle)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Button {
                        model.onTogglePlayback?()
                    } label: {
                        Image(systemName: model.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.75), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.roseAccent)
                    .disabled(model.onTogglePlayback == nil && !isIdle)
                }
                if !isIdle, model.nowPlaying.duration > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.primary.opacity(0.08))
                            Capsule()
                                .fill(Color.purple.opacity(0.8))
                                .frame(width: geometry.size.width * CGFloat(model.nowPlaying.progressFraction))
                        }
                    }
                    .frame(height: 4)
                }
            }
        }
    }

    private var nowPlayingSubtitle: String {
        let artist = model.nowPlaying.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        if artist.isEmpty {
            return model.nowPlaying.playerSource
        }
        return "\(artist) · \(model.nowPlaying.playerSource)"
    }
}


struct BluetoothWidget: View {
    let powerOn: Bool
    let monitoringEnabled: Bool
    let devices: [BluetoothDeviceInfo]
    let onToggleDevice: (Bool, String) -> Void

    var body: some View {
        WidgetCard(title: "Bluetooth devices", symbol: "bluetooth", tint: .blue) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 9) {
                    Circle()
                        .fill(powerOn ? Color.green : Color.secondary.opacity(0.45))
                        .frame(width: 6, height: 6)
                    Text(powerOn ? "Bluetooth on" : "Bluetooth off")
                        .font(.system(size: 10, weight: .semibold))
                    Spacer(minLength: 0)
                }
                ForEach(devices, id: \.address) { device in
                    Button {
                        onToggleDevice(!device.connected, device.address)
                    } label: {
                        HStack(spacing: 9) {
                            Circle()
                                .fill(device.connected ? Color.blue : Color.secondary.opacity(0.45))
                                .frame(width: 6, height: 6)
                            Text(device.name)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Text(device.connected ? "Connected" : "Tap to connect")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                if monitoringEnabled && devices.isEmpty {
                    Text("No paired devices found. Enable Bluetooth access when prompted.")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !monitoringEnabled {
                    Text("Pairing and per-device batteries arrive with the Bluetooth panel.")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}


struct BatteryWidget: View {
    let level: Int
    let isCharging: Bool
    let isPluggedIn: Bool

    private var stateText: String {
        if isCharging { return "Charging" }
        if isPluggedIn { return "Plugged in" }
        return "On battery"
    }

    private var ringColor: Color {
        if level <= 15 { return .red }
        if level <= 30 { return .orange }
        return .green
    }

    var body: some View {
        WidgetCard(title: "Battery", symbol: "battery.75percent", tint: .green) {
            HStack(spacing: 13) {
                ZStack {
                    Circle().stroke(Color.green.opacity(0.16), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: CGFloat(level) / 100)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(level)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Text("%")
                        .font(.system(size: 8, weight: .medium))
                        .offset(y: 11)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(level)% · \(stateText)")
                        .font(.system(size: 10, weight: .semibold))
                    Text(isPluggedIn ? "Adapter connected" : "Discharging")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}


struct FocusWidget: View {
    @State private var isFocused = false

    var body: some View {
        WidgetCard(title: "Focus session", symbol: "moon.stars.fill", tint: .purple) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isFocused ? "Focus is on" : "Make space to focus")
                        .font(.system(size: 11, weight: .semibold))
                    Text(isFocused ? "25 minutes remaining" : "A quiet moment, one task at a time")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(isFocused ? "Pause" : "Start") {
                    isFocused.toggle()
                }
                .font(.system(size: 9, weight: .semibold))
                .buttonStyle(.borderedProminent)
                .tint(Color.roseAccent)
                .controlSize(.small)
            }
        }
    }
}
