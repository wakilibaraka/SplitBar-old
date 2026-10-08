import SwiftUI

public struct FlyoutSurfaceModifier: ViewModifier {
    let style: SurfaceStyle
    let darkMode: Bool
    let transparency: Double
    let cornerRadius: CGFloat
    var layerFXState: LayerFX.State = .normal

    public func body(content: Content) -> some View {
        let tokens = ThemeTokens.resolve(style: style, darkMode: darkMode)
        let layerFX = LayerFX.activeSpec(style: style, darkMode: darkMode, role: .panel, cornerRadius: cornerRadius, state: layerFXState)
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background(
                style.usesMaterial ? tokens.surface : Color.clear,
                in: shape
            )
            .background(
                panelBackground(style: style, darkMode: darkMode, transparency: transparency),
                in: shape
            )
            .overlay {
                if layerFX == nil, style == .windowsAero {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(shape)
                }
            }
            .clipShape(shape)
            .overlay {
                if let layerFX {
                    LayerFXView(spec: layerFX)
                        .allowsHitTesting(false)
                } else {
                    shape.strokeBorder(
                        borderColor,
                        lineWidth: borderWidth
                    )
                }
            }
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: shadowOffset.x,
                y: shadowOffset.y
            )
            .shadow(
                color: extrudeShadowColor,
                radius: extrudeShadowRadius,
                x: -3,
                y: -3
            )
    }

    /// Neumorphism's raised counterpart: a light highlight on the top-left,
    /// paired with the dark drop shadow for a true extruded dual-shadow look.
    /// `.clear` for every other style so nothing changes visually.
    private var extrudeShadowColor: Color {
        guard style == .neumorphism else { return .clear }
        return darkMode ? .white.opacity(0.10) : .white.opacity(0.85)
    }

    private var extrudeShadowRadius: CGFloat {
        style == .neumorphism ? 6 : 0
    }

    private var borderColor: Color {
        switch style {
        case .classic98:
            return Color.white
        case .neobrutalism, .cyberdeck:
            return Color.black
        case .windowsXP:
            return Color.white.opacity(0.8)
        case .visionOS:
            return Color.white.opacity(0.4)
        default:
            return Color.white.opacity(0.76)
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .classic98: return 2
        case .neobrutalism, .cyberdeck: return 3
        default: return 1
        }
    }

    private var shadowColor: Color {
        if style == .neobrutalism {
            return .black.opacity(darkMode ? 0.9 : 1.0)
        }
        if darkMode {
            return .black.opacity(style == .classic98 ? 0.3 : 0.6)
        } else {
            return .black.opacity(style == .classic98 ? 0.12 : (style == .glassmorphism ? 0.08 : 0.18))
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .glassmorphism: return 22
        case .neobrutalism: return 0
        case .classic98, .cyberdeck: return 0
        case .visionOS: return 32
        default: return 14
        }
    }

    private var shadowOffset: CGPoint {
        switch style {
        case .neobrutalism: return CGPoint(x: 4, y: 4)
        case .classic98: return CGPoint(x: 2, y: 3)
        case .cyberdeck: return CGPoint(x: 4, y: 4)
        default: return CGPoint(x: 0, y: 8)
        }
    }
}

public extension View {
    func flyoutSurface(style: SurfaceStyle, darkMode: Bool, transparency: Double, cornerRadius: CGFloat, layerFXState: LayerFX.State = .normal) -> some View {
        self.modifier(FlyoutSurfaceModifier(style: style, darkMode: darkMode, transparency: transparency, cornerRadius: cornerRadius, layerFXState: layerFXState))
    }
}

public struct WidgetCardModifier: ViewModifier {
    let style: SurfaceStyle
    let darkMode: Bool
    let transparency: Double
    let showsBorder: Bool
    var layerFXState: LayerFX.State = .normal

    public func body(content: Content) -> some View {
        let tokens = ThemeTokens.resolve(style: style, darkMode: darkMode)
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let layerFX = LayerFX.activeSpec(
            style: style,
            darkMode: darkMode,
            role: .card,
            cornerRadius: cornerRadius,
            showsBorder: showsBorder,
            state: layerFXState
        )

        content
            .background(
                style.usesMaterial ? tokens.card : Color.clear,
                in: shape
            )
            .background(
                cardBackground(style: style, darkMode: darkMode, transparency: transparency),
                in: shape
            )
            .overlay {
                if layerFX == nil, style == .windowsAero {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(shape)
                }
            }
            .clipShape(shape)
            .overlay {
                if let layerFX {
                    LayerFXView(spec: layerFX)
                        .allowsHitTesting(false)
                } else if showsBorder {
                    shape.strokeBorder(
                        borderColor,
                        lineWidth: borderWidth
                    )
                }
            }
            .shadow(color: primaryShadowColor, radius: primaryShadowRadius, x: primaryShadowOffsetX, y: primaryShadowOffset)
            .shadow(color: secondaryShadowColor, radius: 5, x: -3, y: -3)
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .windowsXP: return 9
        case .classic98, .cyberdeck: return 2
        case .visionOS: return 16
        default: return 15
        }
    }

    private var borderColor: Color {
        switch style {
        case .classic98:
            return Color.white
        case .neumorphism:
            return Color.black.opacity(0.035)
        case .visionOS:
            return Color.white.opacity(0.3)
        case .cyberdeck:
            return Color(red: 0.0, green: 1.0, blue: 0.5).opacity(0.6)
        default:
            return Color.white.opacity(0.9)
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .classic98, .cyberdeck: return 2
        default: return 1
        }
    }

    private var primaryShadowColor: Color {
        if style == .neobrutalism { return .black.opacity(darkMode ? 0.9 : 1.0) }
        if style == .glassmorphism { return .black.opacity(0.035) }
        if style == .classic98 || style == .cyberdeck { return .clear }
        return .black.opacity(0.09)
    }

    private var primaryShadowRadius: CGFloat {
        if style == .neobrutalism { return 0 }
        switch style {
        case .claymorphism: return 12
        case .visionOS: return 16
        default: return 8
        }
    }

    /// Neobrutalism: hard offset shadow, zero blur, per the design language.
    private var primaryShadowOffsetX: CGFloat {
        style == .neobrutalism ? 4 : 0
    }

    private var primaryShadowOffset: CGFloat {
        switch style {
        case .neobrutalism: return 4
        case .neumorphism: return 2
        default: return 4
        }
    }

    private var secondaryShadowColor: Color {
        if style == .neumorphism {
            return .white.opacity(0.75)
        }
        return .clear
    }
}

public extension View {
    func widgetCard(style: SurfaceStyle, darkMode: Bool, transparency: Double, showsBorder: Bool = true, layerFXState: LayerFX.State = .normal) -> some View {
        self.modifier(WidgetCardModifier(style: style, darkMode: darkMode, transparency: transparency, showsBorder: showsBorder, layerFXState: layerFXState))
    }
}

public struct TaskbarSurfaceModifier: ViewModifier {
    let style: SurfaceStyle
    let darkMode: Bool
    let transparency: Double
    let cornerRadius: CGFloat
    var layerFXState: LayerFX.State = .normal

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let layerFX = LayerFX.activeSpec(style: style, darkMode: darkMode, role: .taskbar, cornerRadius: cornerRadius, state: layerFXState)

        return content
            .background(
                style.usesMaterial ? style.taskbarFill(darkMode: darkMode) : Color.clear,
                in: shape
            )
            .background(
                taskbarBackground(style: style, darkMode: darkMode, transparency: transparency),
                in: shape
            )
            .overlay {
                if layerFX == nil, style == .windowsAero {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(shape)
                }
            }
            .clipShape(shape)
            .overlay {
                if let layerFX {
                    LayerFXView(spec: layerFX)
                        .allowsHitTesting(false)
                } else {
                    shape.strokeBorder(
                        borderColor,
                        lineWidth: borderWidth
                    )
                }
            }
    }

    private var borderColor: Color {
        switch style {
        case .classic98:
            return Color.white
        case .neobrutalism, .cyberdeck:
            return Color.black
        case .windowsXP:
            return Color.white.opacity(0.8)
        case .visionOS:
            return Color.white.opacity(0.4)
        case .glassmorphism, .liquidGlass:
            return Color.white.opacity(0.38)
        default:
            return Color.white.opacity(0.2)
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .classic98, .cyberdeck: return 2
        case .neobrutalism: return 3
        default: return 1
        }
    }
}

public extension View {
    func taskbarSurface(style: SurfaceStyle, darkMode: Bool, transparency: Double, cornerRadius: CGFloat, layerFXState: LayerFX.State = .normal) -> some View {
        self.modifier(TaskbarSurfaceModifier(style: style, darkMode: darkMode, transparency: transparency, cornerRadius: cornerRadius, layerFXState: layerFXState))
    }
}
