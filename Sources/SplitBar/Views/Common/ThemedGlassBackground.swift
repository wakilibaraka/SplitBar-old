import SwiftUI

/// Seçili dock temasının cam yüzeyi. Dock, flyout'lar, komut paleti, pencere önizlemeleri ve Ekle paneli
/// aynı görünümü paylaşsın diye tema çizimi tek kaynaktan gelir.
public struct ThemedGlassBackground: View {
    public let style: DockMaterialStyle
    public let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    public init(style: DockMaterialStyle, cornerRadius: CGFloat) {
        self.style = style
        self.cornerRadius = cornerRadius
    }

    private var ambientBacklightGlow: some View {
        Group {
            switch style {
            case .auroraGlow:
                RoundedRectangle(cornerRadius: cornerRadius + 4.0, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.10, green: 0.85, blue: 0.60).opacity(0.35),
                                Color(red: 0.15, green: 0.45, blue: 0.95).opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 16.0)
            case .cyberpunkGlass:
                RoundedRectangle(cornerRadius: cornerRadius + 4.0, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.15, blue: 0.65).opacity(0.35),
                                Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 16.0)
            case .crystalClear:
                RoundedRectangle(cornerRadius: cornerRadius + 4.0, style: .continuous)
                    .fill(Color.cyan.opacity(0.20))
                    .blur(radius: 14.0)
            case .obsidianDark:
                RoundedRectangle(cornerRadius: cornerRadius + 4.0, style: .continuous)
                    .fill(Color.white.opacity(0.12))
                    .blur(radius: 14.0)
            case .monochrome, .emberSunset, .deepOcean, .forestMoss, .roseQuartz:
                if let spec = GradientThemeSpec.spec(for: style) {
                    RoundedRectangle(cornerRadius: cornerRadius + 4.0, style: .continuous)
                        .fill(LinearGradient(colors: spec.glow, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .blur(radius: 16.0)
                }
            default:
                EmptyView()
            }
        }
    }

    private var rimStroke: some View {
        Group {
            switch style {
            case .cyberpunkGlass:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 1.0, green: 0.20, blue: 0.70), location: 0.0),
                                .init(color: Color(red: 0.0, green: 0.90, blue: 1.0), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
            case .auroraGlow:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.10, green: 0.95, blue: 0.65), location: 0.0),
                                .init(color: Color(red: 0.20, green: 0.60, blue: 1.0), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
            case .obsidianDark:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.90), location: 0.0),
                                .init(color: Color.white.opacity(0.30), location: 0.35),
                                .init(color: Color.white.opacity(0.08), location: 0.70),
                                .init(color: Color.white.opacity(0.50), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            case .monochrome, .emberSunset, .deepOcean, .forestMoss, .roseQuartz:
                if let spec = GradientThemeSpec.spec(for: style) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(LinearGradient(colors: spec.rim, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.3)
                }
            default:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.75 : 0.95), location: 0.0),
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.30 : 0.48), location: 0.40),
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.10 : 0.20), location: 0.70),
                                .init(color: Color.white.opacity(colorScheme == .dark ? 0.45 : 0.68), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
        }
    }

    public var body: some View {
        ZStack {
            ambientBacklightGlow

            switch style {
            case .system:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.16 : 0.32),
                                        Color.white.opacity(colorScheme == .dark ? 0.04 : 0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

            case .translucent:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.40))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.18))
                    )

            case .crystalClear:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.20))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.40),
                                        Color.cyan.opacity(0.12),
                                        Color.white.opacity(0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

            case .obsidianDark:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color(white: 0.05).opacity(0.88))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.15), location: 0.0),
                                        .init(color: Color.white.opacity(0.02), location: 0.40),
                                        .init(color: Color.clear, location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

            case .auroraGlow:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(red: 0.05, green: 0.12, blue: 0.16).opacity(0.80))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.10, green: 0.85, blue: 0.60).opacity(0.20),
                                        Color(red: 0.15, green: 0.45, blue: 0.95).opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

            case .cyberpunkGlass:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.02, blue: 0.12).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.10, blue: 0.60).opacity(0.25),
                                        Color(red: 0.0, green: 0.80, blue: 1.0).opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

            case .titaniumFrost:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(red: 0.22, green: 0.24, blue: 0.26).opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.30),
                                        Color.gray.opacity(0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

            case .monochrome, .emberSunset, .deepOcean, .forestMoss, .roseQuartz:
                if let spec = GradientThemeSpec.spec(for: style) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(spec.materialOpacity))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(spec.base)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(LinearGradient(colors: spec.sheen, startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                }

            case .customRGBA(let r, let g, let b, let a):
                let clamped = clampCustomRGBA(r: r, g: g, b: b, a: a)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(red: clamped.0, green: clamped.1, blue: clamped.2).opacity(clamped.3))
            }

            rimStroke
        }
    }
}

/// Yeni temalar tek tip çizilir: taban dolgu, parlama, ortam ışığı ve kenar çizgisi renklerinden oluşur.
private struct GradientThemeSpec {
    let base: Color
    let sheen: [Color]
    let glow: [Color]
    let rim: [Color]
    let materialOpacity: Double

    static func spec(for style: DockMaterialStyle) -> GradientThemeSpec? {
        switch style {
        case .monochrome:
            return GradientThemeSpec(
                base: Color.black.opacity(0.90),
                sheen: [Color.white.opacity(0.14), Color.white.opacity(0.02), Color.clear],
                glow: [Color.white.opacity(0.16), Color.white.opacity(0.04)],
                rim: [Color.white.opacity(0.95), Color.white.opacity(0.20), Color.white.opacity(0.60)],
                materialOpacity: 1.0
            )
        case .emberSunset:
            return GradientThemeSpec(
                base: Color(red: 0.14, green: 0.05, blue: 0.04).opacity(0.86),
                sheen: [Color(red: 1.0, green: 0.55, blue: 0.20).opacity(0.22), Color(red: 0.95, green: 0.25, blue: 0.45).opacity(0.12)],
                glow: [Color(red: 1.0, green: 0.55, blue: 0.15).opacity(0.38), Color(red: 0.95, green: 0.20, blue: 0.45).opacity(0.32)],
                rim: [Color(red: 1.0, green: 0.72, blue: 0.35), Color(red: 1.0, green: 0.35, blue: 0.55)],
                materialOpacity: 0.6
            )
        case .deepOcean:
            return GradientThemeSpec(
                base: Color(red: 0.02, green: 0.07, blue: 0.17).opacity(0.86),
                sheen: [Color(red: 0.20, green: 0.55, blue: 1.0).opacity(0.20), Color(red: 0.10, green: 0.85, blue: 0.85).opacity(0.10)],
                glow: [Color(red: 0.15, green: 0.45, blue: 1.0).opacity(0.36), Color(red: 0.05, green: 0.85, blue: 0.85).opacity(0.28)],
                rim: [Color(red: 0.45, green: 0.75, blue: 1.0), Color(red: 0.20, green: 0.95, blue: 0.90)],
                materialOpacity: 0.6
            )
        case .forestMoss:
            return GradientThemeSpec(
                base: Color(red: 0.04, green: 0.10, blue: 0.06).opacity(0.86),
                sheen: [Color(red: 0.45, green: 0.85, blue: 0.40).opacity(0.18), Color(red: 0.85, green: 0.90, blue: 0.40).opacity(0.08)],
                glow: [Color(red: 0.30, green: 0.80, blue: 0.40).opacity(0.34), Color(red: 0.75, green: 0.90, blue: 0.30).opacity(0.24)],
                rim: [Color(red: 0.60, green: 0.95, blue: 0.55), Color(red: 0.85, green: 0.95, blue: 0.45)],
                materialOpacity: 0.6
            )
        case .roseQuartz:
            return GradientThemeSpec(
                base: Color(red: 1.0, green: 0.86, blue: 0.90).opacity(0.38),
                sheen: [Color.white.opacity(0.45), Color(red: 1.0, green: 0.70, blue: 0.82).opacity(0.18)],
                glow: [Color(red: 1.0, green: 0.60, blue: 0.78).opacity(0.30), Color(red: 0.85, green: 0.70, blue: 1.0).opacity(0.24)],
                rim: [Color.white.opacity(0.95), Color(red: 1.0, green: 0.70, blue: 0.85).opacity(0.70)],
                materialOpacity: 1.0
            )
        case .system, .translucent, .crystalClear, .obsidianDark, .auroraGlow, .cyberpunkGlass, .titaniumFrost, .customRGBA:
            return nil
        }
    }
}

public extension DockMaterialStyle {
    /// Koyu dolgulu temalarda metnin okunur kalması için içerik koyu renk şemasıyla çizilir.
    var prefersDarkContent: Bool {
        switch self {
        case .obsidianDark, .auroraGlow, .cyberpunkGlass, .titaniumFrost, .monochrome, .emberSunset, .deepOcean, .forestMoss:
            return true
        case .system, .translucent, .crystalClear, .roseQuartz:
            return false
        case .customRGBA(let r, let g, let b, _):
            return (0.299 * r + 0.587 * g + 0.114 * b) < 0.5
        }
    }
}

private struct DockMaterialStyleKey: EnvironmentKey {
    static let defaultValue: DockMaterialStyle = .system
}

public extension EnvironmentValues {
    /// Tüm cam yüzeylerin uyduğu, kullanıcının seçtiği dock teması.
    var dockMaterialStyle: DockMaterialStyle {
        get { self[DockMaterialStyleKey.self] }
        set { self[DockMaterialStyleKey.self] = newValue }
    }
}

public extension View {
    /// Görünümü seçili dock temasıyla işaretler; koyu temalarda içerik koyu şemayla çizilir.
    @ViewBuilder
    func dockTheme(_ style: DockMaterialStyle) -> some View {
        if style.prefersDarkContent {
            self.environment(\.dockMaterialStyle, style).environment(\.colorScheme, .dark)
        } else {
            self.environment(\.dockMaterialStyle, style)
        }
    }
}
