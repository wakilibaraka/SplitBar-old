import SwiftUI

/// Weather condition bucket used to drive reactive desktop backgrounds.
enum WeatherBackdropKind {
    case clearDay
    case clearNight
    case cloudy
    case rain
    case snow
    case storm
    case fog
}

/// Maps a weather snapshot onto a backdrop bucket using its symbol first,
/// falling back to the human-readable condition text.
func weatherBackdropKind(for weather: WeatherState) -> WeatherBackdropKind {
    let symbol = weather.symbolName.lowercased()
    let text = weather.conditionText.lowercased()
    if symbol.contains("bolt") || text.contains("thunder") || text.contains("storm") {
        return .storm
    }
    if symbol.contains("snow") || text.contains("snow") || text.contains("blizzard") {
        return .snow
    }
    if symbol.contains("rain") || symbol.contains("drizzle") || text.contains("rain") || text.contains("drizzle") || text.contains("shower") {
        return .rain
    }
    if symbol.contains("fog") || symbol.contains("haze") || text.contains("fog") || text.contains("mist") || text.contains("haze") {
        return .fog
    }
    if symbol.contains("cloud") || text.contains("cloud") || text.contains("overcast") {
        return .cloudy
    }
    if symbol.contains("moon") || text.contains("clear night") {
        return .clearNight
    }
    return .clearDay
}

/// Backdrop gradient palette per weather bucket.
func weatherBackdropPalette(for kind: WeatherBackdropKind) -> [Color] {
    switch kind {
    case .clearDay:
        [Color(red: 1.0, green: 0.85, blue: 0.55), Color(red: 0.45, green: 0.70, blue: 0.95)]
    case .clearNight:
        [Color(red: 0.02, green: 0.03, blue: 0.10), Color(red: 0.15, green: 0.10, blue: 0.30)]
    case .cloudy:
        [Color(red: 0.55, green: 0.60, blue: 0.68), Color(red: 0.35, green: 0.42, blue: 0.55)]
    case .rain:
        [Color(red: 0.20, green: 0.28, blue: 0.38), Color(red: 0.35, green: 0.45, blue: 0.58)]
    case .snow:
        [Color(red: 0.80, green: 0.88, blue: 0.96), Color(red: 0.97, green: 0.98, blue: 1.0)]
    case .storm:
        [Color(red: 0.15, green: 0.10, blue: 0.25), Color(red: 0.10, green: 0.10, blue: 0.12)]
    case .fog:
        [Color(red: 0.65, green: 0.67, blue: 0.70), Color(red: 0.50, green: 0.52, blue: 0.56)]
    }
}

/// Animated particle layer for weather-reactive wallpapers. Positions are a pure
/// function of elapsed time so no per-frame state is needed. Particle counts are
/// capped when Low Power Mode is on.
struct WeatherParticles: View {
    let kind: WeatherBackdropKind
    let intensity: Double

    private var cappedIntensity: Double {
        ProcessInfo.processInfo.isLowPowerModeEnabled ? min(intensity, 0.35) : intensity
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            GeometryReader { geometry in
                let size = geometry.size
                switch kind {
                case .rain:
                    rainLayer(elapsed: elapsed, size: size, count: Int(60 * cappedIntensity) + 10, length: 14, color: .white.opacity(0.45), width: 1.5)
                case .storm:
                    ZStack {
                        rainLayer(elapsed: elapsed, size: size, count: Int(60 * cappedIntensity) + 10, length: 16, color: .white.opacity(0.5), width: 1.5)
                        Color.white.opacity(lightningOpacity(elapsed: elapsed) * 0.22)
                    }
                case .snow:
                    snowLayer(elapsed: elapsed, size: size, count: Int(50 * cappedIntensity) + 8)
                case .clearNight:
                    starsLayer(elapsed: elapsed, size: size, count: Int(40 * cappedIntensity) + 12)
                case .clearDay:
                    sunRaysLayer(elapsed: elapsed, size: size)
                case .cloudy:
                    cloudsLayer(elapsed: elapsed, size: size, count: 5)
                case .fog:
                    mistLayer(elapsed: elapsed, size: size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func rainLayer(elapsed: Double, size: CGSize, count: Int, length: CGFloat, color: Color, width: CGFloat) -> some View {
        Canvas { context, _ in
            for index in 0..<max(1, count) {
                let seed = Double(index) * 137.5
                let x = fmod(seed * 1.7 + elapsed * 12, size.width + 40) - 20
                let y = fmod(seed + elapsed * 420, size.height + 40) - 20
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x - 3, y: y + length))
                context.stroke(path, with: .color(color), lineWidth: width)
            }
        }
    }

    private func snowLayer(elapsed: Double, size: CGSize, count: Int) -> some View {
        Canvas { context, _ in
            for index in 0..<max(1, count) {
                let seed = Double(index) * 91.3
                let fall = fmod(seed + elapsed * (24 + fmod(seed, 18)), size.height + 20) - 10
                let drift = sin(elapsed * 0.7 + seed) * 22
                let x = fmod(seed * 2.3, size.width + 20) - 10 + drift
                let radius = 1.5 + fmod(seed, 2.5)
                context.fill(Path(ellipseIn: CGRect(x: x, y: fall, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.8)))
            }
        }
    }

    private func starsLayer(elapsed: Double, size: CGSize, count: Int) -> some View {
        Canvas { context, _ in
            for index in 0..<max(1, count) {
                let seed = Double(index) * 53.7
                let x = fmod(seed * 3.1, size.width)
                let y = fmod(seed * 1.9, size.height)
                let twinkle = 0.35 + 0.65 * abs(sin(elapsed * 1.4 + seed))
                let radius = 0.8 + fmod(seed, 1.4)
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(twinkle)))
            }
        }
    }

    private func sunRaysLayer(elapsed: Double, size: CGSize) -> some View {
        Canvas { context, _ in
            let center = CGPoint(x: size.width * 0.78, y: size.height * 0.2)
            for index in 0..<12 {
                let angle = elapsed * 0.12 + Double(index) * .pi / 6
                let inner: CGFloat = 46
                let outer: CGFloat = 90 + 10 * sin(elapsed + Double(index))
                var path = Path()
                path.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
                path.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
                context.stroke(path, with: .color(.white.opacity(0.5)), lineWidth: 5)
            }
            context.fill(Path(ellipseIn: CGRect(x: center.x - 42, y: center.y - 42, width: 84, height: 84)), with: .color(.white.opacity(0.75)))
        }
    }

    private func cloudsLayer(elapsed: Double, size: CGSize, count: Int) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                let seed = Double(index) * 211.0
                let speed = 8 + fmod(seed, 10)
                let x = fmod(seed + elapsed * speed, size.width + 320) - 160
                let y = fmod(seed * 0.7, size.height * 0.7)
                Ellipse()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 220 + fmod(seed, 120), height: 70 + fmod(seed, 40))
                    .blur(radius: 24)
                    .position(x: x, y: y)
            }
        }
    }

    private func mistLayer(elapsed: Double, size: CGSize) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let offset = sin(elapsed * 0.18 + Double(index) * 2.1) * size.width * 0.2
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: size.width * 1.2, height: 120 + CGFloat(index) * 60)
                    .blur(radius: 40)
                    .position(x: size.width / 2 + offset, y: size.height * (0.3 + 0.2 * Double(index)))
            }
        }
    }

    private func lightningOpacity(elapsed: Double) -> Double {
        let cycle = fmod(elapsed, 7)
        if cycle < 0.12 { return 1 }
        if cycle < 0.24 { return 0.2 }
        if cycle < 0.3 { return 0.7 }
        return 0
    }
}
