import SwiftUI

public struct FlyoutSurfaceModifier: ViewModifier {
    let style: SurfaceStyle
    let darkMode: Bool
    let transparency: Double
    let cornerRadius: CGFloat

    public func body(content: Content) -> some View {
        content
            .background(
                panelBackground(style: style, darkMode: darkMode, transparency: transparency),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .background(surfaceWash(style: style, darkMode: darkMode))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        borderColor,
                        lineWidth: borderWidth
                    )
            }
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: shadowOffset.x,
                y: shadowOffset.y
            )
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
        if darkMode {
            return .black.opacity(style == .classic98 ? 0.3 : 0.6)
        } else {
            return .black.opacity(style == .classic98 ? 0.12 : (style == .glassmorphism ? 0.08 : 0.18))
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .glassmorphism: return 22
        case .classic98, .cyberdeck: return 0
        case .visionOS: return 32
        default: return 14
        }
    }

    private var shadowOffset: CGPoint {
        switch style {
        case .classic98: return CGPoint(x: 2, y: 3)
        case .cyberdeck: return CGPoint(x: 4, y: 4)
        default: return CGPoint(x: 0, y: 8)
        }
    }
}

public extension View {
    func flyoutSurface(style: SurfaceStyle, darkMode: Bool, transparency: Double, cornerRadius: CGFloat) -> some View {
        self.modifier(FlyoutSurfaceModifier(style: style, darkMode: darkMode, transparency: transparency, cornerRadius: cornerRadius))
    }
}

public struct WidgetCardModifier: ViewModifier {
    let style: SurfaceStyle
    let darkMode: Bool
    let transparency: Double
    let showsBorder: Bool

    public func body(content: Content) -> some View {
        content
            .background(
                cardBackground(style: style, darkMode: darkMode, transparency: transparency),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                if showsBorder {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            borderColor,
                            lineWidth: borderWidth
                        )
                }
            }
            .shadow(color: primaryShadowColor, radius: primaryShadowRadius, x: 0, y: primaryShadowOffset)
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
        if style == .glassmorphism { return .black.opacity(0.035) }
        if style == .classic98 || style == .cyberdeck { return .clear }
        return .black.opacity(0.09)
    }

    private var primaryShadowRadius: CGFloat {
        switch style {
        case .claymorphism: return 12
        case .visionOS: return 16
        default: return 8
        }
    }

    private var primaryShadowOffset: CGFloat {
        switch style {
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
    func widgetCard(style: SurfaceStyle, darkMode: Bool, transparency: Double, showsBorder: Bool = true) -> some View {
        self.modifier(WidgetCardModifier(style: style, darkMode: darkMode, transparency: transparency, showsBorder: showsBorder))
    }
}

public struct TaskbarSurfaceModifier: ViewModifier {
    let style: SurfaceStyle
    let darkMode: Bool
    let transparency: Double
    let cornerRadius: CGFloat

    public func body(content: Content) -> some View {
        content
            .background(
                taskbarBackground(style: style, darkMode: darkMode, transparency: transparency),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .background(surfaceWash(style: style, darkMode: darkMode))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        borderColor,
                        lineWidth: borderWidth
                    )
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
    func taskbarSurface(style: SurfaceStyle, darkMode: Bool, transparency: Double, cornerRadius: CGFloat) -> some View {
        self.modifier(TaskbarSurfaceModifier(style: style, darkMode: darkMode, transparency: transparency, cornerRadius: cornerRadius))
    }
}
