import SwiftUI

enum OpenPanel: Equatable {
    case widgets
    case calendar
    case controls
    case start
    case settings

    var panelKind: PanelKind {
        switch self {
        case .widgets: .widgets
        case .calendar: .calendar
        case .controls: .controls
        case .start: .start
        case .settings: .settings
        }
    }
}


// MARK: - SurfaceStyle — 14 named design-language themes
public enum SurfaceStyle: String, CaseIterable, Identifiable {

    // Glassmorphism family
    case glassmorphism   // was "glass" — frosted, thin light edge
    case liquidGlass     // Apple Liquid Glass — lensing + adaptive tint
    case windowsAero     // was "aero" — transparent blur, specular sweeps

    // Material / Soft family
    case neumorphism     // was "neumorphic" — dual soft shadows, one surface
    case claymorphism    // was "clay" — oversized radii, floating puffy look
    case skeuomorphism   // simulated real materials (leather / metal tints)

    // Flat / Bold family
    case flatDesign      // solid 2D, no depth
    case neobrutalism    // thick outlines, hard offset shadows, saturated color
    case minimalism      // maximum negative space, near-monochrome

    // Retro / Nostalgic family
    case aqua            // classic macOS candy-gel controls (Aqua)
    case frutigerAero    // glossy glass + nature palette (sky-blue / grass-green)
    case y2k             // liquid chrome, gel plastic, iridescent blue-silver

    // Legacy Windows
    case windowsXP       // Luna blue gradient bars
    case classic98       // grey beveled panels
    case visionOS        // spatial volumetric frosted glass
    case cyberdeck       // high contrast neon borders and grid

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .glassmorphism: "Glassmorphism"
        case .liquidGlass:   "Liquid Glass"
        case .windowsAero:   "Windows Aero"
        case .neumorphism:   "Neumorphism"
        case .claymorphism:  "Claymorphism"
        case .skeuomorphism: "Skeuomorphism"
        case .flatDesign:    "Flat Design"
        case .neobrutalism:  "Neobrutalism"
        case .minimalism:    "Minimalism"
        case .aqua:          "Aqua"
        case .frutigerAero:  "Frutiger Aero"
        case .y2k:           "Y2K"
        case .windowsXP:     "Windows XP"
        case .classic98:     "Windows 98"
        case .visionOS:      "VisionOS"
        case .cyberdeck:     "Cyberdeck"
        }
    }

    public var subtitle: String {
        switch self {
        case .glassmorphism: "Frosted translucent layers"
        case .liquidGlass:   "Apple's adaptive water-drop glass"
        case .windowsAero:   "Iridescent blue glass and light"
        case .neumorphism:   "Quiet embossed soft shadows"
        case .claymorphism:  "Puffy 3D play-doh surfaces"
        case .skeuomorphism: "Simulated real leather and metal"
        case .flatDesign:    "Solid 2D colors, zero depth"
        case .neobrutalism:  "Bold blocks and hard offset shadows"
        case .minimalism:    "Almost nothing, perfectly placed"
        case .aqua:          "Classic Mac candy-gel controls"
        case .frutigerAero:  "Glossy glass meets nature"
        case .y2k:           "Chrome bubblegum millennium"
        case .windowsXP:     "Blue Luna bars and soft corners"
        case .classic98:     "Classic grey beveled panels"
        case .visionOS:      "Spatial volumetric frosted glass with deep highlights"
        case .cyberdeck:     "High contrast neon wireframe with pure black surfaces"
        }
    }

    // MARK: Panel fill (flyouts & settings panel)
    func panelFill(darkMode: Bool) -> Color {
        if darkMode {
            switch self {
            case .glassmorphism: Color(red: 0.10, green: 0.12, blue: 0.17)
            case .liquidGlass:   Color(red: 0.10, green: 0.12, blue: 0.18)
            case .windowsAero:   Color(red: 0.08, green: 0.16, blue: 0.25)
            case .neumorphism:   Color(red: 0.122, green: 0.125, blue: 0.188)
            case .claymorphism:  Color(red: 0.17, green: 0.14, blue: 0.18)
            case .skeuomorphism: Color(red: 0.14, green: 0.10, blue: 0.08)
            case .flatDesign:    Color(red: 0.12, green: 0.16, blue: 0.22)
            case .neobrutalism:  Color(red: 0.10, green: 0.10, blue: 0.10)
            case .minimalism:    Color(red: 0.08, green: 0.08, blue: 0.09)
            case .aqua:          Color(red: 0.06, green: 0.16, blue: 0.32)
            case .frutigerAero:  Color(red: 0.05, green: 0.18, blue: 0.28)
            case .y2k:           Color(red: 0.12, green: 0.14, blue: 0.22)
            case .windowsXP:     Color(red: 0.07, green: 0.14, blue: 0.29)
            case .classic98:     Color(red: 0.16, green: 0.16, blue: 0.17)
            case .visionOS:      Color(white: 0.1).opacity(0.65)
            case .cyberdeck:     Color.black
            }
        } else {
            switch self {
            case .glassmorphism: .white.opacity(0.58)
            case .liquidGlass:   .white.opacity(0.65)
            case .windowsAero:   Color(red: 0.73, green: 0.87, blue: 0.97)
            case .neumorphism:   Color(red: 0.910, green: 0.918, blue: 0.941)
            case .claymorphism:  Color(red: 0.98, green: 0.92, blue: 0.92)
            case .skeuomorphism: Color(red: 0.84, green: 0.76, blue: 0.68)
            case .flatDesign:    Color(red: 0.17, green: 0.45, blue: 0.91)
            case .neobrutalism:  Color(red: 0.98, green: 0.96, blue: 0.30)
            case .minimalism:    .white.opacity(0.95)
            case .aqua:          Color(red: 0.72, green: 0.86, blue: 0.97)
            case .frutigerAero:  Color(red: 0.74, green: 0.91, blue: 0.96)
            case .y2k:           Color(red: 0.82, green: 0.88, blue: 1.0)
            case .windowsXP:     Color(red: 0.86, green: 0.91, blue: 0.98)
            case .classic98:     Color(red: 0.77, green: 0.77, blue: 0.77)
            case .visionOS:      Color.white.opacity(0.85)
            case .cyberdeck:     Color.black
            }
        }
    }

    // MARK: Card fill (widget cards, settings section backgrounds)
    func cardFill(darkMode: Bool) -> Color {
        if darkMode {
            switch self {
            case .glassmorphism: Color(red: 0.15, green: 0.18, blue: 0.24)
            case .liquidGlass:   Color(red: 0.16, green: 0.19, blue: 0.26)
            case .windowsAero:   Color(red: 0.12, green: 0.23, blue: 0.31)
            case .neumorphism:   Color(red: 0.145, green: 0.150, blue: 0.222)
            case .claymorphism:  Color(red: 0.23, green: 0.18, blue: 0.23)
            case .skeuomorphism: Color(red: 0.20, green: 0.16, blue: 0.12)
            case .flatDesign:    Color(red: 0.17, green: 0.22, blue: 0.30)
            case .neobrutalism:  Color(red: 0.18, green: 0.18, blue: 0.18)
            case .minimalism:    Color(red: 0.10, green: 0.10, blue: 0.11)
            case .aqua:          Color(red: 0.10, green: 0.22, blue: 0.40)
            case .frutigerAero:  Color(red: 0.08, green: 0.22, blue: 0.34)
            case .y2k:           Color(red: 0.16, green: 0.18, blue: 0.28)
            case .windowsXP:     Color(red: 0.12, green: 0.23, blue: 0.40)
            case .classic98:     Color(red: 0.23, green: 0.23, blue: 0.25)
            case .visionOS:      Color(white: 0.2).opacity(0.55)
            case .cyberdeck:     Color(red: 0.05, green: 0.05, blue: 0.05)
            }
        } else {
            switch self {
            case .glassmorphism: .white.opacity(0.72)
            case .liquidGlass:   .white.opacity(0.78)
            case .windowsAero:   Color(red: 0.84, green: 0.93, blue: 0.99)
            case .neumorphism:   Color(red: 0.940, green: 0.945, blue: 0.965)
            case .claymorphism:  Color(red: 0.99, green: 0.95, blue: 0.94)
            case .skeuomorphism: Color(red: 0.90, green: 0.84, blue: 0.76)
            case .flatDesign:    Color(red: 0.25, green: 0.54, blue: 0.97)
            case .neobrutalism:  Color(red: 1.0, green: 0.98, blue: 0.40)
            case .minimalism:    .white.opacity(0.92)
            case .aqua:          Color(red: 0.82, green: 0.92, blue: 0.99)
            case .frutigerAero:  Color(red: 0.84, green: 0.96, blue: 0.98)
            case .y2k:           Color(red: 0.88, green: 0.92, blue: 1.0)
            case .windowsXP:     Color(red: 0.96, green: 0.97, blue: 0.99)
            case .classic98:     Color(red: 0.82, green: 0.82, blue: 0.82)
            case .visionOS:      Color(white: 0.95).opacity(0.65)
            case .cyberdeck:     Color(red: 0.05, green: 0.05, blue: 0.05)
            }
        }
    }

    // MARK: Corner radius
    var cornerRadius: CGFloat {
        switch self {
        case .glassmorphism: 22
        case .liquidGlass:   26
        case .windowsAero:   10
        case .neumorphism:   16
        case .claymorphism:  28
        case .skeuomorphism: 8
        case .flatDesign:    4
        case .neobrutalism:  0
        case .minimalism:    6
        case .aqua:          14
        case .frutigerAero:  20
        case .y2k:           12
        case .windowsXP:     10
        case .classic98:     2
        case .visionOS:      32
        case .cyberdeck:     0
        }
    }

    // MARK: Taskbar bar fill
    func taskbarFill(darkMode: Bool) -> Color {
        if darkMode {
            switch self {
            case .glassmorphism, .liquidGlass:
                Color(red: 0.08, green: 0.11, blue: 0.16).opacity(0.9)
            case .windowsAero:
                Color(red: 0.08, green: 0.20, blue: 0.31).opacity(0.85)
            case .neumorphism:
                Color(red: 0.108, green: 0.112, blue: 0.172)
            case .claymorphism:
                Color(red: 0.15, green: 0.11, blue: 0.16)
            case .skeuomorphism:
                Color(red: 0.10, green: 0.07, blue: 0.05)
            case .flatDesign:
                Color(red: 0.10, green: 0.14, blue: 0.20)
            case .neobrutalism:
                Color(red: 0.08, green: 0.08, blue: 0.08)
            case .minimalism:
                Color(red: 0.05, green: 0.05, blue: 0.06)
            case .aqua:
                Color(red: 0.04, green: 0.12, blue: 0.28)
            case .frutigerAero:
                Color(red: 0.03, green: 0.14, blue: 0.22)
            case .y2k:
                Color(red: 0.08, green: 0.10, blue: 0.18)
            case .windowsXP:
                Color(red: 0.04, green: 0.13, blue: 0.30)
            case .classic98:
                Color(red: 0.21, green: 0.21, blue: 0.22)
            case .visionOS:
                Color(white: 0.1).opacity(0.85)
            case .cyberdeck:
                Color.black.opacity(0.95)
            }
        } else {
            switch self {
            case .glassmorphism, .liquidGlass:
                Color.white.opacity(0.78)
            case .windowsAero:
                Color(red: 0.42, green: 0.69, blue: 0.88).opacity(0.65)
            case .neumorphism:
                Color(red: 0.878, green: 0.886, blue: 0.910)
            case .claymorphism:
                Color(red: 0.96, green: 0.88, blue: 0.88)
            case .skeuomorphism:
                Color(red: 0.32, green: 0.26, blue: 0.20)
            case .flatDesign:
                Color(red: 0.17, green: 0.45, blue: 0.91)
            case .neobrutalism:
                Color(red: 0.98, green: 0.96, blue: 0.30)
            case .minimalism:
                .white
            case .aqua:
                Color(red: 0.18, green: 0.52, blue: 0.92)
            case .frutigerAero:
                Color(red: 0.36, green: 0.76, blue: 0.88)
            case .y2k:
                Color(red: 0.58, green: 0.72, blue: 0.96)
            case .windowsXP:
                Color(red: 0.70, green: 0.82, blue: 0.98)
            case .classic98:
                Color(red: 0.76, green: 0.76, blue: 0.76)
            case .visionOS:
                Color.white.opacity(0.85)
            case .cyberdeck:
                Color.black.opacity(0.95)
            }
        }
    }

    // MARK: Accent colour
    func accent(darkMode: Bool) -> Color {
        if darkMode {
            switch self {
            case .glassmorphism, .claymorphism:
                Color(red: 1.0, green: 0.58, blue: 0.68)
            case .liquidGlass:
                Color(red: 0.40, green: 0.85, blue: 1.0)
            case .windowsAero, .windowsXP:
                Color(red: 0.43, green: 0.76, blue: 1.0)
            case .neumorphism:
                Color(red: 0.55, green: 0.65, blue: 1.0)
            case .skeuomorphism:
                Color(red: 0.98, green: 0.82, blue: 0.50)
            case .flatDesign:
                Color(red: 0.40, green: 0.72, blue: 1.0)
            case .neobrutalism:
                Color(red: 0.98, green: 0.88, blue: 0.10)
            case .minimalism:
                .white
            case .aqua:
                Color(red: 0.30, green: 0.72, blue: 1.0)
            case .frutigerAero:
                Color(red: 0.38, green: 0.92, blue: 0.58)
            case .y2k:
                Color(red: 0.50, green: 0.80, blue: 1.0)
            case .classic98:
                Color(red: 0.68, green: 0.75, blue: 1.0)
            case .visionOS:
                Color.white
            case .cyberdeck:
                Color(red: 0.0, green: 1.0, blue: 0.5)
            }
        } else {
            switch self {
            case .glassmorphism, .claymorphism:
                .roseAccent
            case .liquidGlass:
                Color(red: 0.05, green: 0.45, blue: 0.92)
            case .windowsAero, .windowsXP:
                Color(red: 0.05, green: 0.35, blue: 0.81)
            case .neumorphism:
                Color(red: 0.38, green: 0.48, blue: 0.88)
            case .skeuomorphism:
                Color(red: 0.70, green: 0.52, blue: 0.18)
            case .flatDesign:
                Color(red: 0.17, green: 0.45, blue: 0.91)
            case .neobrutalism:
                Color(red: 0.10, green: 0.10, blue: 0.10)
            case .minimalism:
                .primary
            case .aqua:
                Color(red: 0.10, green: 0.42, blue: 0.86)
            case .frutigerAero:
                Color(red: 0.16, green: 0.62, blue: 0.32)
            case .y2k:
                Color(red: 0.26, green: 0.52, blue: 0.96)
            case .classic98:
                Color(red: 0.12, green: 0.22, blue: 0.52)
            case .visionOS:
                Color.black
            case .cyberdeck:
                Color(red: 0.0, green: 1.0, blue: 0.5)
            }
        }
    }

    // MARK: Theme-matched wallpaper gradient
    func accentGradient(darkMode: Bool) -> [Color] {
        switch self {
        case .glassmorphism:
            [Color(red: 0.30, green: 0.48, blue: 0.67), Color(red: 0.91, green: 0.69, blue: 0.87), Color(red: 0.47, green: 0.70, blue: 0.86)]
        case .liquidGlass:
            [Color(red: 0.25, green: 0.55, blue: 0.95), Color(red: 0.55, green: 0.45, blue: 0.95), Color(red: 0.40, green: 0.85, blue: 1.0)]
        case .windowsAero:
            [Color(red: 0.08, green: 0.35, blue: 0.62), Color(red: 0.43, green: 0.76, blue: 1.0), Color(red: 0.36, green: 0.76, blue: 0.78)]
        case .neumorphism:
            [Color(red: 0.55, green: 0.60, blue: 0.75), Color(red: 0.82, green: 0.85, blue: 0.95), Color(red: 0.65, green: 0.70, blue: 0.90)]
        case .claymorphism:
            [Color(red: 1.0, green: 0.75, blue: 0.80), Color(red: 0.75, green: 0.70, blue: 0.95), Color(red: 1.0, green: 0.85, blue: 0.75)]
        case .skeuomorphism:
            [Color(red: 0.55, green: 0.45, blue: 0.35), Color(red: 0.84, green: 0.76, blue: 0.68), Color(red: 0.40, green: 0.32, blue: 0.24)]
        case .flatDesign:
            [Color(red: 0.15, green: 0.35, blue: 0.85), Color(red: 0.25, green: 0.54, blue: 0.97), Color(red: 0.10, green: 0.25, blue: 0.70)]
        case .neobrutalism:
            [Color(red: 1.0, green: 0.90, blue: 0.20), Color(red: 1.0, green: 0.45, blue: 0.35), Color(red: 0.95, green: 0.75, blue: 0.15)]
        case .minimalism:
            [Color(red: 0.80, green: 0.82, blue: 0.88), Color(red: 0.95, green: 0.95, blue: 0.97), Color(red: 0.70, green: 0.72, blue: 0.80)]
        case .aqua:
            [Color(red: 0.15, green: 0.45, blue: 0.90), Color(red: 0.45, green: 0.75, blue: 1.0), Color(red: 0.10, green: 0.35, blue: 0.80)]
        case .frutigerAero:
            [Color(red: 0.35, green: 0.70, blue: 0.92), Color(red: 0.45, green: 0.80, blue: 0.45), Color(red: 0.25, green: 0.55, blue: 0.85)]
        case .y2k:
            [Color(red: 0.60, green: 0.70, blue: 1.0), Color(red: 0.85, green: 0.60, blue: 0.95), Color(red: 0.45, green: 0.75, blue: 1.0)]
        case .windowsXP:
            [Color(red: 0.15, green: 0.35, blue: 0.75), Color(red: 0.36, green: 0.62, blue: 0.95), Color(red: 0.10, green: 0.25, blue: 0.60)]
        case .classic98:
            [Color(red: 0.55, green: 0.55, blue: 0.58), Color(red: 0.75, green: 0.75, blue: 0.78), Color(red: 0.45, green: 0.45, blue: 0.48)]
        case .visionOS:
            [Color.white.opacity(0.8), Color.white.opacity(0.2), Color.clear]
        case .cyberdeck:
            [Color(red: 0.0, green: 1.0, blue: 0.5), Color.purple, Color.cyan]
        }
    }
}


func panelBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle {
    GlassProviders.current.panelBackground(style: style, darkMode: darkMode, transparency: transparency)
}


func cardBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle {
    GlassProviders.current.cardBackground(style: style, darkMode: darkMode, transparency: transparency)
}


func surfaceWash(style: SurfaceStyle, darkMode: Bool) -> Color {
    if darkMode {
        switch style {
        case .windowsAero:   return Color(red: 0.08, green: 0.20, blue: 0.31).opacity(0.45)
        case .aqua:          return Color(red: 0.04, green: 0.18, blue: 0.40).opacity(0.40)
        case .frutigerAero:  return Color(red: 0.04, green: 0.18, blue: 0.28).opacity(0.40)
        default:             return Color.black.opacity(0.24)
        }
    }
    switch style {
    case .windowsAero:   return Color(red: 0.44, green: 0.75, blue: 0.95).opacity(0.30)
    case .windowsXP:     return Color(red: 0.23, green: 0.52, blue: 0.87).opacity(0.13)
    case .classic98:     return Color(red: 0.55, green: 0.55, blue: 0.55).opacity(0.12)
    case .aqua:          return Color(red: 0.18, green: 0.52, blue: 0.92).opacity(0.25)
    case .frutigerAero:  return Color(red: 0.20, green: 0.70, blue: 0.88).opacity(0.20)
    case .y2k:           return Color(red: 0.50, green: 0.70, blue: 1.0).opacity(0.18)
    case .neobrutalism:  return .clear
    case .minimalism:    return .clear
    default:             return Color.roseMist.opacity(0.42)
    }
}


struct SurfaceStyleKey: EnvironmentKey {
    static let defaultValue = SurfaceStyle.glassmorphism
}


struct TransparencyKey: EnvironmentKey {
    static let defaultValue = 0.40
}


struct AeroSheen: ViewModifier {
    var cornerRadius: CGFloat?
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.overlay {
            if surfaceStyle == .windowsAero {
                RoundedRectangle(cornerRadius: cornerRadius ?? surfaceStyle.cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.12 : 0.36),
                                Color.white.opacity(0.015),
                                Color.blue.opacity(colorScheme == .dark ? 0.08 : 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .allowsHitTesting(false)
            }
        }
    }
}


extension View {
    func aeroSheen(cornerRadius: CGFloat? = nil) -> some View {
        modifier(AeroSheen(cornerRadius: cornerRadius))
    }
}


struct WidgetOutlineKey: EnvironmentKey {
    static let defaultValue = WidgetOutlineStyle()
}


struct IconBackgroundKey: EnvironmentKey {
    static let defaultValue = IconBackgroundStyle()
}


extension EnvironmentValues {
    var surfaceStyle: SurfaceStyle {
        get { self[SurfaceStyleKey.self] }
        set { self[SurfaceStyleKey.self] = newValue }
    }

    var surfaceTransparency: Double {
        get { self[TransparencyKey.self] }
        set { self[TransparencyKey.self] = newValue }
    }

    var widgetOutline: WidgetOutlineStyle {
        get { self[WidgetOutlineKey.self] }
        set { self[WidgetOutlineKey.self] = newValue }
    }

    var iconBackground: IconBackgroundStyle {
        get { self[IconBackgroundKey.self] }
        set { self[IconBackgroundKey.self] = newValue }
    }
}

func taskbarBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle {
    GlassProviders.current.taskbarBackground(style: style, darkMode: darkMode, transparency: transparency)
}

extension SurfaceStyle {
    var usesMaterial: Bool {
        switch self {
        case .glassmorphism, .liquidGlass, .windowsAero, .visionOS:
            return true
        default:
            return false
        }
    }
}
