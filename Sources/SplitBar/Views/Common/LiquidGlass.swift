import AppKit
import SwiftUI

/// SplitBar'in ortak vurgu renkleri. Tüm göstergeler (AI limitleri, sistem monitörü, grafikler) aynı paleti
/// kullanır; sistemin doygun `.blue`/`.purple` gibi renkleri noir cam temasıyla uyumsuz olduğu için kullanılmaz.
public enum SplitBarPalette {
    public static let cyan = Color(red: 0.36, green: 0.72, blue: 1.0)
    public static let violet = Color(red: 0.62, green: 0.52, blue: 1.0)
    public static let mint = Color(red: 0.24, green: 0.86, blue: 0.56)
    public static let amber = Color(red: 1.0, green: 0.68, blue: 0.22)
    public static let coral = Color(red: 1.0, green: 0.32, blue: 0.38)
    public static let terracotta = Color(red: 0.85, green: 0.47, blue: 0.34)
    public static let silver = Color(red: 0.72, green: 0.76, blue: 0.82)
}

/// Kapsül biçimli cam ilerleme çubuğu; standart `ProgressView` yerine tüm yüzdelik göstergelerde kullanılır.
public struct GlassProgressBar: View {
    public let fraction: Double
    public let tint: Color
    public let height: CGFloat

    public init(fraction: Double, tint: Color, height: CGFloat) {
        self.fraction = fraction
        self.tint = tint
        self.height = height
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.70), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(height, geometry.size.width * CGFloat(min(max(fraction, 0.0), 1.0))))
                    .shadow(color: tint.opacity(0.45), radius: 4.0)
                    .opacity(fraction > 0.0 ? 1.0 : 0.0)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: fraction)
    }
}

/// Ortasında değer ve açıklama bulunan halka gösterge (AI limitleri ve sistem monitörü ortak kullanır).
public struct GaugeRingView: View {
    public let fraction: Double
    public let tint: Color
    public let valueText: String
    public let captionText: String
    public let diameter: CGFloat

    public init(fraction: Double, tint: Color, valueText: String, captionText: String, diameter: CGFloat) {
        self.fraction = fraction
        self.tint = tint
        self.valueText = valueText
        self.captionText = captionText
        self.diameter = diameter
    }

    public var body: some View {
        let clamped = min(max(fraction, 0.0), 1.0)
        let lineWidth = diameter * 0.095
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0.0, to: CGFloat(clamped))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.55), tint],
                        center: .center,
                        startAngle: .degrees(0.0),
                        endAngle: .degrees(max(360.0 * clamped, 1.0))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90.0))
                .shadow(color: tint.opacity(0.45), radius: 5.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: clamped)
            VStack(spacing: 0.0) {
                Text(valueText)
                    .font(.system(size: diameter * 0.225, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(captionText)
                    .font(.system(size: diameter * 0.113, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, lineWidth)
        }
        .frame(width: diameter, height: diameter)
    }
}

public struct LiquidGlassSurfaceModifier: ViewModifier {
    public let cornerRadius: CGFloat
    public let tintColor: Color?
    public let isHovered: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dockMaterialStyle) private var dockMaterialStyle

    public init(
        cornerRadius: CGFloat,
        tintColor: Color?,
        isHovered: Bool
    ) {
        self.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.isHovered = isHovered
    }

    public func body(content: Content) -> some View {
        // "System" dışındaki temalarda yüzey dock ile birebir aynı tema çizimini kullanır
        if dockMaterialStyle != .system {
            content
                .background(ThemedGlassBackground(style: dockMaterialStyle, cornerRadius: cornerRadius))
                .shadow(color: Color.black.opacity(0.40), radius: isHovered ? 16.0 : 10.0, x: 0.0, y: isHovered ? 6.0 : 4.0)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            systemSurface(content: content)
        }
    }

    private func systemSurface(content: Content) -> some View {
        let isDark = colorScheme == .dark
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return content
            .background(
                ZStack {
                    // 1. Base Deep Ultra-Thin Material (Variable Blur)
                    shape
                        .fill(.ultraThinMaterial)

                    // 2. Liquid Glass Volumetric Tint
                    if let tint = tintColor {
                        shape
                            .fill(tint.opacity(isDark ? 0.12 : 0.08))
                    }

                    // 3. Ambient Specular Sheen (2026/2027 Fluid Caustics)
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDark ? (isHovered ? 0.16 : 0.10) : (isHovered ? 0.32 : 0.22)),
                                    Color.white.opacity(isDark ? 0.03 : 0.08),
                                    Color.black.opacity(isDark ? 0.20 : 0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // 4. Subtle Inner Glow / Bevel Light Guide
                    shape
                        .strokeBorder(
                            Color.white.opacity(isDark ? 0.10 : 0.25),
                            lineWidth: 0.5
                        )
                        .blur(radius: 0.5)

                    // 5. Precision Refractive Rim Light (High IOR Specular Border)
                    shape
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(isDark ? 0.65 : 0.85), location: 0.0),
                                    .init(color: Color.white.opacity(isDark ? 0.25 : 0.40), location: 0.35),
                                    .init(color: Color.white.opacity(isDark ? 0.08 : 0.15), location: 0.70),
                                    .init(color: Color.white.opacity(isDark ? 0.30 : 0.50), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                }
            )
            // 6. Dual-Stage Volumetric Shadow (Ambient Occlusion + Atmospheric Diffusion)
            .shadow(
                color: Color.black.opacity(isDark ? 0.40 : 0.14),
                radius: isHovered ? 16.0 : 10.0,
                x: 0.0,
                y: isHovered ? 6.0 : 4.0
            )
            .shadow(
                color: tintColor?.opacity(isDark ? 0.22 : 0.15) ?? Color.black.opacity(isDark ? 0.25 : 0.06),
                radius: isHovered ? 28.0 : 18.0,
                x: 0.0,
                y: isHovered ? 12.0 : 8.0
            )
            .contentShape(shape)
    }
}

public struct LiquidGlassCardModifier: ViewModifier {
    public let cornerRadius: CGFloat
    public let isHovered: Bool

    @Environment(\.colorScheme) private var colorScheme

    public init(
        cornerRadius: CGFloat,
        isHovered: Bool
    ) {
        self.cornerRadius = cornerRadius
        self.isHovered = isHovered
    }

    public func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background(
                ZStack {
                    shape
                        .fill(Color.white.opacity(isDark ? (isHovered ? 0.08 : 0.04) : (isHovered ? 0.45 : 0.28)))

                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDark ? (isHovered ? 0.35 : 0.18) : (isHovered ? 0.60 : 0.35)),
                                    Color.white.opacity(isDark ? 0.05 : 0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
            )
            .shadow(
                color: Color.black.opacity(isDark ? 0.20 : 0.04),
                radius: isHovered ? 8.0 : 4.0,
                x: 0.0,
                y: isHovered ? 3.0 : 1.5
            )
            .contentShape(shape)
    }
}

public struct LiquidGlassPillModifier: ViewModifier {
    public let accentColor: Color?

    @Environment(\.colorScheme) private var colorScheme

    public init(accentColor: Color?) {
        self.accentColor = accentColor
    }

    public func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        let shape = Capsule()

        content
            .background(
                ZStack {
                    if let accent = accentColor {
                        shape
                            .fill(accent.opacity(isDark ? 0.22 : 0.15))
                    } else {
                        shape
                            .fill(Color.white.opacity(isDark ? 0.10 : 0.25))
                    }

                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    (accentColor ?? Color.white).opacity(isDark ? 0.50 : 0.70),
                                    (accentColor ?? Color.white).opacity(isDark ? 0.15 : 0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
            )
            .contentShape(shape)
    }
}

/// İçeriğin yüzeyin altına gömülü göründüğü "kuyu" alanı; kod, çıktı ve metin girişleri için kullanılır.
/// Koyu modda derin siyah, açık modda hafif gri tonla her iki görünümde de okunabilir kalır.
public struct LiquidGlassWellModifier: ViewModifier {
    public let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    public init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background(
                shape
                    .fill(Color.black.opacity(isDark ? 0.35 : 0.05))
                    .overlay(
                        shape.strokeBorder(Color.primary.opacity(isDark ? 0.10 : 0.12), lineWidth: 0.75)
                    )
            )
    }
}

public extension View {
    func liquidGlassWell(cornerRadius: CGFloat) -> some View {
        self.modifier(LiquidGlassWellModifier(cornerRadius: cornerRadius))
    }

    func liquidGlassSurface(
        cornerRadius: CGFloat,
        tintColor: Color?,
        isHovered: Bool
    ) -> some View {
        self.modifier(
            LiquidGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                tintColor: tintColor,
                isHovered: isHovered
            )
        )
    }

    func liquidGlassCard(
        cornerRadius: CGFloat,
        isHovered: Bool
    ) -> some View {
        self.modifier(
            LiquidGlassCardModifier(
                cornerRadius: cornerRadius,
                isHovered: isHovered
            )
        )
    }

    func liquidGlassPill(accentColor: Color?) -> some View {
        self.modifier(
            LiquidGlassPillModifier(accentColor: accentColor)
        )
    }
}
