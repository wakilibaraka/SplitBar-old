import Foundation

public enum DockMaterialStyle: Codable, Hashable, Sendable {
    case system
    case translucent
    case crystalClear
    case obsidianDark
    case auroraGlow
    case cyberpunkGlass
    case titaniumFrost
    case monochrome
    case emberSunset
    case deepOcean
    case forestMoss
    case roseQuartz
    case customRGBA(Double, Double, Double, Double)

    public var displayName: String {
        switch self {
        case .system:
            return "System Liquid Glass"
        case .translucent:
            return "Translucent Blur"
        case .crystalClear:
            return "Crystal Clear"
        case .obsidianDark:
            return "Obsidian Dark"
        case .auroraGlow:
            return "Aurora Borealis"
        case .cyberpunkGlass:
            return "Cyberpunk Neon"
        case .titaniumFrost:
            return "Titanium Frost"
        case .monochrome:
            return "Monochrome"
        case .emberSunset:
            return "Ember Sunset"
        case .deepOcean:
            return "Deep Ocean"
        case .forestMoss:
            return "Forest Moss"
        case .roseQuartz:
            return "Rose Quartz"
        case .customRGBA:
            return "Custom RGBA"
        }
    }
}

public extension DockMaterialStyle {
    /// Menülerde ve Ayarlar'da sunulan hazır temalar; tüm tema listeleri buradan türetilir.
    static let presets: [DockMaterialStyle] = [
        .system, .translucent, .crystalClear, .obsidianDark, .monochrome, .titaniumFrost,
        .auroraGlow, .deepOcean, .forestMoss, .cyberpunkGlass, .emberSunset, .roseQuartz
    ]
}

public func clampCustomRGBA(r: Double, g: Double, b: Double, a: Double) -> (Double, Double, Double, Double) {
    let clampedR = min(max(r, 0.0), 1.0)
    let clampedG = min(max(g, 0.0), 1.0)
    let clampedB = min(max(b, 0.0), 1.0)
    let clampedA = min(max(a, 0.0), 1.0)
    return (clampedR, clampedG, clampedB, clampedA)
}
