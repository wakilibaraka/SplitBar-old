import SwiftUI

enum WallpaperPreset: String, CaseIterable, Identifiable {
    case pastelBloom
    case ocean
    case sunset
    case midnight
    case graphite
    case custom
    case weatherReactive
    case themeMatched

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pastelBloom: "Pastel bloom"
        case .ocean: "Ocean"
        case .sunset: "Sunset"
        case .midnight: "Midnight"
        case .graphite: "Graphite"
        case .custom: "Custom"
        case .weatherReactive: "Weather reactive"
        case .themeMatched: "Theme matched"
        }
    }

    var colors: [Color] {
        switch self {
        case .pastelBloom:
            [Color(red: 0.30, green: 0.48, blue: 0.67), Color(red: 0.91, green: 0.69, blue: 0.87), Color(red: 0.47, green: 0.70, blue: 0.86)]
        case .ocean:
            [Color(red: 0.02, green: 0.24, blue: 0.38), Color(red: 0.05, green: 0.49, blue: 0.62), Color(red: 0.36, green: 0.76, blue: 0.78)]
        case .sunset:
            [Color(red: 0.28, green: 0.20, blue: 0.42), Color(red: 0.83, green: 0.36, blue: 0.48), Color(red: 0.98, green: 0.67, blue: 0.41)]
        case .midnight:
            [Color(red: 0.015, green: 0.025, blue: 0.08), Color(red: 0.08, green: 0.08, blue: 0.20), Color(red: 0.05, green: 0.17, blue: 0.22)]
        case .graphite:
            [Color(red: 0.055, green: 0.065, blue: 0.08), Color(red: 0.15, green: 0.17, blue: 0.20), Color(red: 0.085, green: 0.10, blue: 0.12)]
        case .custom:
            []
        case .weatherReactive:
            [Color(red: 0.45, green: 0.70, blue: 0.95), Color(red: 0.35, green: 0.45, blue: 0.58)]
        case .themeMatched:
            [Color(red: 0.91, green: 0.69, blue: 0.87), Color(red: 0.47, green: 0.70, blue: 0.86)]
        }
    }

    var isDark: Bool {
        self == .midnight || self == .graphite
    }
}
