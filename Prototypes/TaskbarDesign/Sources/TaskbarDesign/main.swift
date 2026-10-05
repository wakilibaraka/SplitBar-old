import AppKit
import SwiftUI

@main
struct TaskbarDesignApp: App {
    var body: some Scene {
        WindowGroup {
            DesktopView()
                .frame(minWidth: 1080, minHeight: 700)
        }
        .defaultSize(width: 1440, height: 920)
        .windowStyle(.hiddenTitleBar)
    }
}

private enum OpenPanel: Equatable {
    case widgets
    case calendar
    case controls
    case start
    case settings
}

private enum SurfaceStyle: String, CaseIterable, Identifiable {
    case glass
    case clay
    case neumorphic
    case windowsXP
    case classic98
    case aero

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glass: "Glass"
        case .clay: "Clay"
        case .neumorphic: "Neumorphic"
        case .windowsXP: "Windows XP"
        case .classic98: "Windows 98"
        case .aero: "Aero glass"
        }
    }

    var subtitle: String {
        switch self {
        case .glass: "Soft translucent layers"
        case .clay: "Warm, gently raised cards"
        case .neumorphic: "Quiet embossed surfaces"
        case .windowsXP: "Blue Luna bars and soft corners"
        case .classic98: "Classic grey beveled panels"
        case .aero: "Iridescent blue glass and light"
        }
    }

    func panelFill(darkMode: Bool) -> Color {
        if darkMode {
            switch self {
            case .glass: Color(red: 0.10, green: 0.12, blue: 0.17)
            case .clay: Color(red: 0.17, green: 0.14, blue: 0.18)
            case .neumorphic: Color(red: 0.13, green: 0.14, blue: 0.18)
            case .windowsXP: Color(red: 0.07, green: 0.14, blue: 0.29)
            case .classic98: Color(red: 0.16, green: 0.16, blue: 0.17)
            case .aero: Color(red: 0.08, green: 0.16, blue: 0.25)
            }
        } else {
            switch self {
            case .glass: .white.opacity(0.58)
            case .clay: Color(red: 0.98, green: 0.92, blue: 0.92)
            case .neumorphic: Color(red: 0.91, green: 0.92, blue: 0.96)
            case .windowsXP: Color(red: 0.86, green: 0.91, blue: 0.98)
            case .classic98: Color(red: 0.77, green: 0.77, blue: 0.77)
            case .aero: Color(red: 0.73, green: 0.87, blue: 0.97)
            }
        }
    }

    func cardFill(darkMode: Bool) -> Color {
        if darkMode {
            switch self {
            case .glass: Color(red: 0.15, green: 0.18, blue: 0.24)
            case .clay: Color(red: 0.23, green: 0.18, blue: 0.23)
            case .neumorphic: Color(red: 0.19, green: 0.20, blue: 0.25)
            case .windowsXP: Color(red: 0.12, green: 0.23, blue: 0.40)
            case .classic98: Color(red: 0.23, green: 0.23, blue: 0.25)
            case .aero: Color(red: 0.12, green: 0.23, blue: 0.31)
            }
        } else {
            switch self {
            case .glass: .white.opacity(0.72)
            case .clay: Color(red: 0.99, green: 0.95, blue: 0.94)
            case .neumorphic: Color(red: 0.94, green: 0.95, blue: 0.98)
            case .windowsXP: Color(red: 0.96, green: 0.97, blue: 0.99)
            case .classic98: Color(red: 0.82, green: 0.82, blue: 0.82)
            case .aero: Color(red: 0.84, green: 0.93, blue: 0.99)
            }
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .glass: 22
        case .clay: 20
        case .neumorphic: 16
        case .windowsXP: 10
        case .classic98: 2
        case .aero: 18
        }
    }

    func taskbarFill(darkMode: Bool) -> Color {
        if darkMode {
            switch self {
            case .glass, .clay, .neumorphic, .aero: Color(red: 0.08, green: 0.11, blue: 0.16).opacity(0.9)
            case .windowsXP: Color(red: 0.04, green: 0.13, blue: 0.30)
            case .classic98: Color(red: 0.21, green: 0.21, blue: 0.22)
            }
        } else {
            switch self {
            case .glass, .clay, .neumorphic: Color.white.opacity(0.78)
            case .windowsXP: Color(red: 0.70, green: 0.82, blue: 0.98)
            case .classic98: Color(red: 0.76, green: 0.76, blue: 0.76)
            case .aero: Color(red: 0.42, green: 0.69, blue: 0.88).opacity(0.65)
            }
        }
    }

    func accent(darkMode: Bool) -> Color {
        if darkMode {
            switch self {
            case .glass, .clay, .neumorphic: Color(red: 1.0, green: 0.58, blue: 0.68)
            case .windowsXP, .aero: Color(red: 0.43, green: 0.76, blue: 1.0)
            case .classic98: Color(red: 0.68, green: 0.75, blue: 1.0)
            }
        } else {
            switch self {
            case .glass, .clay, .neumorphic: .roseAccent
            case .windowsXP: Color(red: 0.05, green: 0.35, blue: 0.81)
            case .classic98: Color(red: 0.12, green: 0.22, blue: 0.52)
            case .aero: Color(red: 0.12, green: 0.57, blue: 0.91)
            }
        }
    }
}

private func panelBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle {
    return switch style {
    case .glass:
        AnyShapeStyle(
            (transparency > 0.72 ? Material.ultraThin : Material.regular)
                .opacity(1 - transparency * 0.68)
        )
    case .aero:
        AnyShapeStyle(Material.ultraThin.opacity(1 - transparency * 0.68))
    case .clay, .neumorphic, .windowsXP, .classic98:
        AnyShapeStyle(style.panelFill(darkMode: darkMode).opacity(1 - transparency * 0.68))
    }
}

private func cardBackground(style: SurfaceStyle, darkMode: Bool, transparency: Double) -> AnyShapeStyle {
    return switch style {
    case .glass:
        AnyShapeStyle(
            (transparency > 0.72 ? Material.ultraThin : Material.regular)
                .opacity(1 - transparency * 0.42)
        )
    case .aero:
        AnyShapeStyle(Material.ultraThin.opacity(1 - transparency * 0.42))
    case .clay, .neumorphic, .windowsXP, .classic98:
        AnyShapeStyle(style.cardFill(darkMode: darkMode).opacity(1 - transparency * 0.42))
    }
}

private func surfaceWash(style: SurfaceStyle, darkMode: Bool) -> Color {
    if darkMode {
        return style == .aero ? Color(red: 0.08, green: 0.20, blue: 0.31).opacity(0.45) : Color.black.opacity(0.24)
    }
    return switch style {
    case .aero: Color(red: 0.44, green: 0.75, blue: 0.95).opacity(0.3)
    case .windowsXP: Color(red: 0.23, green: 0.52, blue: 0.87).opacity(0.13)
    case .classic98: Color(red: 0.55, green: 0.55, blue: 0.55).opacity(0.12)
    default: Color.roseMist.opacity(0.42)
    }
}

private struct SurfaceStyleKey: EnvironmentKey {
    static let defaultValue = SurfaceStyle.glass
}

private struct TransparencyKey: EnvironmentKey {
    static let defaultValue = 0.68
}

private struct AeroSheen: ViewModifier {
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.overlay {
            if surfaceStyle == .aero {
                RoundedRectangle(cornerRadius: surfaceStyle.cornerRadius, style: .continuous)
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

private extension View {
    func aeroSheen() -> some View {
        modifier(AeroSheen())
    }
}

private extension EnvironmentValues {
    var surfaceStyle: SurfaceStyle {
        get { self[SurfaceStyleKey.self] }
        set { self[SurfaceStyleKey.self] = newValue }
    }

    var surfaceTransparency: Double {
        get { self[TransparencyKey.self] }
        set { self[TransparencyKey.self] = newValue }
    }
}

private struct DesktopView: View {
    @State private var openPanel: OpenPanel?
    @State private var surfaceStyle = SurfaceStyle.glass
    @State private var usesDockPresentation = false
    @State private var isDarkMode = false
    @State private var usesPastelGradient = true
    @State private var pastelTint = Color(red: 0.91, green: 0.69, blue: 0.87)
    @State private var gradientEndTint = Color(red: 0.47, green: 0.70, blue: 0.86)
    @State private var gradientAngle = 35.0
    @State private var interfaceTransparency = 0.68
    @State private var usesTaskbarGradient = false
    @State private var taskbarGradientStart = Color(red: 0.78, green: 0.48, blue: 0.86)
    @State private var taskbarGradientEnd = Color(red: 0.96, green: 0.38, blue: 0.42)
    @State private var taskbarHeight: CGFloat = 46
    @State private var showsClockSettings = false
    @State private var uses24HourTime = false
    @State private var showsSeconds = false
    @State private var dateStyle = ClockDateStyle.compact
    @State private var clockTint = Color.roseAccent
    @State private var displayedMonth = Calendar.current.startOfMonth(for: .now)
    @State private var selectedDate = Date.now

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                DesktopBackdrop(
                    isDarkMode: isDarkMode,
                    usesPastelGradient: usesPastelGradient,
                    pastelTint: pastelTint,
                    gradientEndTint: gradientEndTint,
                    gradientAngle: gradientAngle
                )

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.roseAccent)
                        Text("TASKBAR CONCEPT")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(2.2)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .padding(.top, 30)
                    .padding(.leading, 34)

                    Spacer()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("A calmer kind of desktop.")
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                            .tracking(-1.8)
                        Text("A Windows-inspired taskbar, thoughtfully reimagined for macOS.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    .foregroundStyle(.white)
                    .padding(.leading, 72)
                    .padding(.bottom, 180)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if openPanel == .widgets {
                    WidgetsPanel(onClose: { openPanel = nil }, accent: clockTint)
                        .frame(
                            width: min(520, geometry.size.width - 36),
                            height: max(300, geometry.size.height - taskbarHeight - 28)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.leading, 14)
                        .padding(.top, 14)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                if openPanel == .calendar {
                    ClockFlyout(
                        displayedMonth: $displayedMonth,
                        selectedDate: $selectedDate,
                        showsClockSettings: $showsClockSettings,
                        uses24HourTime: $uses24HourTime,
                        showsSeconds: $showsSeconds,
                        dateStyle: $dateStyle,
                        clockTint: $clockTint,
                        accent: clockTint
                    )
                    .frame(width: min(520, geometry.size.width - 36), height: max(300, geometry.size.height - taskbarHeight - 28))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 14)
                    .padding(.top, 14)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .environment(\.surfaceStyle, surfaceStyle)
                    .zIndex(2)
                }

                if openPanel == .controls {
                    ControlsFlyout(accent: clockTint, isDarkMode: $isDarkMode)
                        .frame(width: min(520, geometry.size.width - 36), height: max(300, geometry.size.height - taskbarHeight - 28))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.trailing, 14)
                        .padding(.top, 14)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                if openPanel == .start {
                    StartFlyout(onClose: { openPanel = nil }, accent: clockTint)
                        .frame(width: min(860, geometry.size.width - 48), height: min(820, geometry.size.height - taskbarHeight - 36))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, taskbarHeight + 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                if openPanel == .settings {
                    SettingsFlyout(
                        surfaceStyle: $surfaceStyle,
                        usesDockPresentation: $usesDockPresentation,
                        isDarkMode: $isDarkMode,
                        usesPastelGradient: $usesPastelGradient,
                        pastelTint: $pastelTint,
                        gradientEndTint: $gradientEndTint,
                        gradientAngle: $gradientAngle,
                        interfaceTransparency: $interfaceTransparency,
                        usesTaskbarGradient: $usesTaskbarGradient,
                        taskbarGradientStart: $taskbarGradientStart,
                        taskbarGradientEnd: $taskbarGradientEnd,
                        taskbarHeight: $taskbarHeight,
                        accent: clockTint,
                        onClose: { openPanel = nil }
                    )
                    .frame(width: min(560, geometry.size.width - 40), height: min(680, geometry.size.height - taskbarHeight - 34))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, taskbarHeight)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                    .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                Taskbar(
                    openPanel: $openPanel,
                    height: $taskbarHeight,
                    usesDockPresentation: usesDockPresentation,
                    surfaceStyle: surfaceStyle,
                    isDarkMode: isDarkMode,
                    usesTaskbarGradient: usesTaskbarGradient,
                    taskbarGradientStart: taskbarGradientStart,
                    taskbarGradientEnd: taskbarGradientEnd,
                    tint: clockTint,
                    dateStyle: dateStyle,
                    uses24HourTime: uses24HourTime,
                    showsSeconds: showsSeconds
                )
                .zIndex(3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .animation(.spring(response: 0.38, dampingFraction: 0.86), value: openPanel)
            .environment(\.surfaceTransparency, interfaceTransparency)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

private struct DesktopBackdrop: View {
    let isDarkMode: Bool
    let usesPastelGradient: Bool
    let pastelTint: Color
    let gradientEndTint: Color
    let gradientAngle: Double

    private var gradientStart: UnitPoint {
        UnitPoint(x: 0.5 - cos(gradientAngle * .pi / 180) / 2, y: 0.5 - sin(gradientAngle * .pi / 180) / 2)
    }

    private var gradientEnd: UnitPoint {
        UnitPoint(x: 0.5 + cos(gradientAngle * .pi / 180) / 2, y: 0.5 + sin(gradientAngle * .pi / 180) / 2)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isDarkMode
                    ? [
                        Color(red: 0.035, green: 0.055, blue: 0.10),
                        Color(red: 0.10, green: 0.075, blue: 0.14),
                        Color(red: 0.045, green: 0.10, blue: 0.16)
                    ]
                    : usesPastelGradient
                    ? [
                        Color(red: 0.30, green: 0.48, blue: 0.67),
                        pastelTint,
                        gradientEndTint
                    ]
                    : [
                        Color(red: 0.10, green: 0.22, blue: 0.39),
                        Color(red: 0.13, green: 0.31, blue: 0.50),
                        Color(red: 0.16, green: 0.22, blue: 0.42)
                    ],
                startPoint: gradientStart,
                endPoint: gradientEnd
            )

            Circle()
                .fill((isDarkMode ? Color(red: 0.21, green: 0.36, blue: 0.57) : (usesPastelGradient ? pastelTint : Color(red: 0.37, green: 0.71, blue: 0.87))).opacity(0.47))
                .frame(width: 520, height: 520)
                .blur(radius: 85)
                .offset(x: 380, y: -170)

            Circle()
                .fill((isDarkMode ? Color(red: 0.39, green: 0.18, blue: 0.33) : (usesPastelGradient ? Color.roseAccent : Color(red: 0.28, green: 0.30, blue: 0.67))).opacity(0.31))
                .frame(width: 460, height: 460)
                .blur(radius: 100)
                .offset(x: -430, y: 140)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.13), Color.white.opacity(0.015)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 860, height: 410)
                .rotationEffect(.degrees(-26))
                .offset(x: 220, y: 130)

            Ellipse()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .frame(width: 960, height: 480)
                .rotationEffect(.degrees(-26))
                .offset(x: 210, y: 135)
        }
        .ignoresSafeArea()
    }
}

private struct Taskbar: View {
    @Binding var openPanel: OpenPanel?
    @Binding var height: CGFloat
    @State private var dragStartHeight: CGFloat?
    let usesDockPresentation: Bool
    let surfaceStyle: SurfaceStyle
    let isDarkMode: Bool
    let usesTaskbarGradient: Bool
    let taskbarGradientStart: Color
    let taskbarGradientEnd: Color
    @Environment(\.surfaceTransparency) private var transparency
    let tint: Color
    let dateStyle: ClockDateStyle
    let uses24HourTime: Bool
    let showsSeconds: Bool

    private let appItems: [(String, String, String, Color)] = [
        ("com.apple.Safari", "safari.fill", "Safari", Color(red: 0.15, green: 0.58, blue: 0.86)),
        ("com.apple.finder", "folder.fill", "Finder", Color(red: 0.18, green: 0.56, blue: 0.91)),
        ("com.apple.mail", "envelope.fill", "Mail", Color(red: 0.28, green: 0.54, blue: 0.85)),
        ("com.apple.iCal", "calendar", "Calendar", Color.roseAccent),
        ("com.apple.MobileSMS", "message.fill", "Messages", .green),
        ("com.apple.Terminal", "terminal.fill", "Terminal", .primary),
        ("com.apple.systempreferences", "gearshape.fill", "System Settings", .secondary)
    ]

    var body: some View {
        ZStack {
            Group {
                if usesDockPresentation {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
                        }
                        .padding(.horizontal, 150)
                        .padding(.vertical, 3)
                } else if usesTaskbarGradient {
                    Rectangle()
                        .fill(LinearGradient(colors: [taskbarGradientStart, taskbarGradientEnd], startPoint: .leading, endPoint: .trailing))
                } else if surfaceStyle == .aero {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.44, green: 0.74, blue: 0.96).opacity(isDarkMode ? 0.22 : 0.45),
                                    Color.white.opacity(isDarkMode ? 0.03 : 0.16),
                                    Color(red: 0.18, green: 0.43, blue: 0.71).opacity(isDarkMode ? 0.18 : 0.30)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                } else {
                    let base = surfaceStyle.taskbarFill(darkMode: isDarkMode)
                    Rectangle()
                        .fill(
                            surfaceStyle == .windowsXP
                                ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.15, green: 0.44, blue: 0.88), Color(red: 0.04, green: 0.22, blue: 0.61)], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(base)
                        )
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(Color.white.opacity(0.42))
                                .frame(height: 1)
                        }
                }
            }
            .opacity(1 - transparency * 0.62)

            HStack(spacing: 0) {
                Button {
                    toggle(.widgets)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "cloud.sun.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color(red: 0.94, green: 0.63, blue: 0.18), Color(red: 0.45, green: 0.69, blue: 0.89))
                            .font(.system(size: height * 0.48))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("13°")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Mostly clear")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 170, height: height - 4, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Open widgets")
                .padding(.leading, 18)

                Spacer(minLength: 0)

                HStack(spacing: 13) {
                    Button {
                        toggle(.controls)
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: "wifi")
                            Image(systemName: "speaker.wave.2.fill")
                            Image(systemName: "battery.75percent")
                        }
                        .font(.system(size: height * 0.27, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.78))
                        .frame(height: height - 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Open quick controls, volume, Bluetooth and battery")

                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Button {
                            toggle(.calendar)
                        } label: {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(clockTime(context.date, uses24HourTime: uses24HourTime, showsSeconds: showsSeconds))
                                    .font(.system(size: height * 0.27, weight: .semibold, design: .rounded))
                                Text(dateStyle.string(from: context.date))
                                    .font(.system(size: height * 0.22, weight: .medium))
                            }
                            .foregroundStyle(tint)
                            .frame(minWidth: 78, minHeight: height - 8, alignment: .trailing)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Open calendar and notifications")
                    }
                }
                .padding(.trailing, 20)
                .frame(width: 245, alignment: .trailing)
            }
            .padding(.horizontal, usesDockPresentation ? 18 : 8)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .environment(\.surfaceTransparency, transparency)
        .overlay(alignment: .center) {
            HStack(spacing: 4) {
                Button {
                    toggle(.start)
                } label: {
                    MacOSAppIcon(
                        bundleIdentifier: "com.apple.launchpad",
                        fallbackSymbol: "square.grid.3x3.fill",
                        fallbackColor: isDarkMode ? Color(red: 0.54, green: 0.76, blue: 1) : .blue,
                        size: height * 0.46
                    )
                    .frame(width: max(28, height * 0.74), height: height - 8)
                }
                .help("Open Start")
                .taskbarButton()

                ForEach(appItems, id: \.2) { bundleIdentifier, symbol, title, color in
                    Button {
                        if title == "System Settings" {
                            toggle(.settings)
                        }
                    } label: {
                        MacOSAppIcon(
                            bundleIdentifier: bundleIdentifier,
                            fallbackSymbol: symbol,
                            fallbackColor: color,
                            size: height * 0.44
                        )
                        .frame(width: max(28, height * 0.74), height: height - 8)
                    }
                    .help(title)
                    .taskbarButton()
                }
            }
            .buttonStyle(.plain)
        }
        .overlay(alignment: .top) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 12)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.primary.opacity(0.16))
                        .frame(width: 42, height: 3)
                        .padding(.top, 3)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if dragStartHeight == nil {
                                dragStartHeight = height
                            }
                            if let dragStartHeight {
                                height = min(48, max(32, dragStartHeight - value.translation.height))
                            }
                        }
                        .onEnded { _ in
                            dragStartHeight = nil
                        }
                )
                .help("Drag to resize the taskbar")
        }
        .overlay(alignment: .top) {
            if usesDockPresentation == false && surfaceStyle == .classic98 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(height: 1)
                    .offset(y: -1)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                openPanel = .settings
            } label: {
                Label("Customise taskbar", systemImage: "slider.horizontal.3")
            }

            Divider()

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label("Quit Taskbar", systemImage: "power")
            }
        }
    }

    private func toggle(_ panel: OpenPanel) {
        openPanel = openPanel == panel ? nil : panel
    }
}

private struct MacOSAppIcon: View {
    let bundleIdentifier: String
    let fallbackSymbol: String
    let fallbackColor: Color
    let size: CGFloat

    var body: some View {
        Group {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: fallbackSymbol)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(fallbackColor)
                    .padding(size * 0.14)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct TaskbarButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(0.001))
            }
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

private extension View {
    func taskbarButton() -> some View {
        modifier(TaskbarButtonStyle())
    }
}

private struct WidgetsPanel: View {
    let onClose: () -> Void
    let accent: Color
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Widgets")
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                    Text("A little overview of your day")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {} label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.6), in: Circle())
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.6), in: Circle())
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 16)

            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                    WeatherWidget()
                        .gridCellColumns(2)
                    SystemResourcesWidget()
                    MediaWidget()
                    PhotosWidget()
                    StickyNotesWidget()
                    WatchlistWidget()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: surfaceStyle.cornerRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: surfaceStyle.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: surfaceStyle.cornerRadius, style: .continuous)
                .strokeBorder(surfaceStyle == .classic98 ? Color.white.opacity(0.95) : Color.white.opacity(0.72), lineWidth: surfaceStyle == .classic98 ? 2 : 1)
        }
        .shadow(color: .black.opacity(surfaceStyle == .classic98 ? 0.12 : 0.18), radius: surfaceStyle == .glass ? 22 : 14, x: 0, y: surfaceStyle == .classic98 ? 3 : 8)
        .aeroSheen()
    }
}

private struct WidgetCard<Content: View>: View {
    let title: String
    let symbol: String
    let tint: Color
    let minContentHeight: CGFloat
    let content: Content
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    init(
        title: String,
        symbol: String,
        tint: Color = .blue,
        minContentHeight: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.tint = tint
        self.minContentHeight = minContentHeight
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 7) {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                Text(title)
                    .foregroundStyle(.primary.opacity(0.84))
                Spacer(minLength: 0)
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 12, weight: .semibold))

            content
                .frame(maxWidth: .infinity, minHeight: minContentHeight, alignment: .topLeading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            cardBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency),
            in: RoundedRectangle(cornerRadius: surfaceStyle == .windowsXP ? 9 : (surfaceStyle == .classic98 ? 2 : 15), style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: surfaceStyle == .windowsXP ? 9 : (surfaceStyle == .classic98 ? 2 : 15), style: .continuous)
                .strokeBorder(surfaceStyle == .classic98 ? Color.white : (surfaceStyle == .neumorphic ? Color.black.opacity(0.035) : Color.white.opacity(0.9)), lineWidth: surfaceStyle == .classic98 ? 2 : 1)
        }
        .shadow(color: .black.opacity(surfaceStyle == .glass ? 0.035 : 0.09), radius: surfaceStyle == .clay ? 12 : 8, x: 0, y: surfaceStyle == .neumorphic ? 2 : 4)
        .shadow(color: .white.opacity(surfaceStyle == .neumorphic ? 0.75 : 0), radius: 5, x: -3, y: -3)
        .aeroSheen()
    }
}

private struct WeatherWidget: View {
    private let forecast: [(String, String, String)] = [
        ("Now", "sun.max.fill", "13°"),
        ("1 PM", "sun.max.fill", "15°"),
        ("2 PM", "cloud.sun.fill", "14°"),
        ("3 PM", "cloud.fill", "14°"),
        ("4 PM", "cloud.sun.fill", "13°")
    ]

    var body: some View {
        WidgetCard(title: "Weather", symbol: "cloud.sun.fill", tint: .blue) {
            HStack(spacing: 12) {
                Image(systemName: "cloud.sun.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.orange, Color.blue.opacity(0.75))
                    .font(.system(size: 37))
                VStack(alignment: .leading, spacing: 2) {
                    Text("13°")
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                    Text("Mostly clear · Durres")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 0) {
                ForEach(forecast, id: \.0) { hour, symbol, temperature in
                    VStack(spacing: 7) {
                        Text(hour)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                        Image(systemName: symbol)
                            .font(.system(size: 13))
                            .foregroundStyle(symbol == "cloud.fill" ? Color.gray : Color.orange)
                        Text(temperature)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 10)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.black.opacity(0.07)).frame(height: 1)
            }
        }
    }
}

private struct SystemResourcesWidget: View {
    private let backgroundApps: [(String, String, Color)] = [
        ("Browser", "1.2 GB", .blue),
        ("Cloud Sync", "640 MB", .purple),
        ("Video Call", "420 MB", .green),
        ("Photo Editor", "310 MB", .orange)
    ]

    var body: some View {
        WidgetCard(
            title: "System resources",
            symbol: "chart.bar.fill",
            tint: .blue,
            minContentHeight: 246
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

                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)
                    .padding(.vertical, 1)

                Text("Background apps")
                    .font(.system(size: 10, weight: .semibold))

                VStack(spacing: 9) {
                    ForEach(backgroundApps, id: \.0) { name, memory, tint in
                        HStack(spacing: 7) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(tint.opacity(0.16))
                                .overlay {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(tint)
                                }
                                .frame(width: 19, height: 19)
                            Text(name)
                                .font(.system(size: 9, weight: .medium))
                                .lineLimit(1)
                            Spacer(minLength: 2)
                            Text(memory)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

private struct PhotosWidget: View {
    var body: some View {
        WidgetCard(title: "Photos", symbol: "photo.on.rectangle.angled", tint: .blue) {
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

private struct StickyNotesWidget: View {
    var body: some View {
        WidgetCard(title: "Sticky notes", symbol: "note.text", tint: .orange) {
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

private struct WatchlistWidget: View {
    private let assets: [(String, String, String, Color)] = [
        ("NVDA", "$203.65", "+2.4%", .green),
        ("META", "$151.74", "+1.2%", .green),
        ("TSLA", "$177.90", "−0.8%", .red)
    ]

    var body: some View {
        WidgetCard(title: "Watchlist", symbol: "chart.xyaxis.line", tint: .green) {
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

private struct MediaWidget: View {
    @State private var isPlaying = false

    var body: some View {
        WidgetCard(title: "Now playing", symbol: "music.note", tint: .purple, minContentHeight: 246) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(LinearGradient(colors: [.purple.opacity(0.8), .pink.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay {
                        Image(systemName: "waveform")
                            .foregroundStyle(.white)
                    }
                    .frame(width: 43, height: 43)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Close to You")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Reality Club")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.75), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.roseAccent)
            }
        }
    }
}

private struct BluetoothWidget: View {
    let isEnabled: Bool

    private let devices: [(String, String, String)] = [
        ("keyboard", "Wireless keyboard", "82%"),
        ("computermouse.fill", "Bluetooth mouse", "100%"),
        ("headphones", "Headphones", "45%")
    ]

    var body: some View {
        WidgetCard(title: "Bluetooth devices", symbol: "bluetooth", tint: .blue) {
            VStack(spacing: 12) {
                ForEach(devices, id: \.1) { symbol, title, charge in
                    HStack(spacing: 9) {
                        Image(systemName: symbol)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                        Text(title)
                            .font(.system(size: 9, weight: .medium))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Circle().fill(isEnabled ? Color.green : Color.secondary.opacity(0.45)).frame(width: 5, height: 5)
                        Text(isEnabled ? charge : "Off")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct BatteryWidget: View {
    var body: some View {
        WidgetCard(title: "Battery", symbol: "battery.75percent", tint: .green) {
            HStack(spacing: 13) {
                ZStack {
                    Circle().stroke(Color.green.opacity(0.16), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("72")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Text("%")
                        .font(.system(size: 8, weight: .medium))
                        .offset(y: 11)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Powering your day")
                        .font(.system(size: 10, weight: .semibold))
                    Text("About 4 hours remaining")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct FocusWidget: View {
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

private struct QuickSetting: Identifiable {
    let title: String
    let symbol: String

    var id: String { title }
}

private struct ControlsFlyout: View {
    let accent: Color
    @Binding var isDarkMode: Bool
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency
    @State private var wifiEnabled = true
    @State private var bluetoothEnabled = true
    @State private var vpnEnabled = false
    @State private var volume: Double = 0.68
    @State private var appVolume: Double = 0.52
    @State private var brightness: Double = 0.82
    @State private var isEditingQuickSettings = false
    @AppStorage("quickSettings.hiddenTiles") private var hiddenQuickSettingTitles = ""
    @State private var enabledQuickSettings: Set<String> = [
        "Finder Path Bar", "Show Extension", "True Tone"
    ]

    private let quickSettings: [QuickSetting] = [
        QuickSetting(title: "Bluetooth", symbol: "bluetooth"),
        QuickSetting(title: "Dark Mode", symbol: "moon.fill"),
        QuickSetting(title: "Dock Autohide", symbol: "rectangle.bottomthird.inset.filled"),
        QuickSetting(title: "Dock Recents", symbol: "clock.fill"),
        QuickSetting(title: "Eject Discs", symbol: "eject.fill"),
        QuickSetting(title: "Empty Trash", symbol: "trash.fill"),
        QuickSetting(title: "Finder Path Bar", symbol: "sidebar.left"),
        QuickSetting(title: "Hidden Files", symbol: "eye.fill"),
        QuickSetting(title: "Hide Desktop", symbol: "rectangle.dashed"),
        QuickSetting(title: "Keep Awake", symbol: "cup.and.saucer.fill"),
        QuickSetting(title: "Keyboard Lock", symbol: "keyboard"),
        QuickSetting(title: "Menubar Hide", symbol: "rectangle.topthird.inset.filled"),
        QuickSetting(title: "Mute", symbol: "speaker.slash.fill"),
        QuickSetting(title: "Mute Mic", symbol: "mic.slash.fill"),
        QuickSetting(title: "Pomodoro", symbol: "timer"),
        QuickSetting(title: "Restart Finder", symbol: "rectangle.dashed"),
        QuickSetting(title: "Screen Saver", symbol: "display"),
        QuickSetting(title: "Show Extension", symbol: "doc.text"),
        QuickSetting(title: "Show Library", symbol: "books.vertical.fill"),
        QuickSetting(title: "Small Launchpad", symbol: "square.grid.3x3.fill"),
        QuickSetting(title: "Speed Test", symbol: "globe"),
        QuickSetting(title: "True Tone", symbol: "sun.max.fill"),
        QuickSetting(title: "VPN", symbol: "lock.shield.fill"),
        QuickSetting(title: "Xcode Cache", symbol: "hammer.fill")
    ]

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)
    }

    private var visibleQuickSettings: Set<String> {
        Set(quickSettings.map(\.title)).subtracting(hiddenQuickSettingTitles.split(separator: "|").map(String.init))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Quick Settings")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Text("Your devices and controls")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    isEditingQuickSettings.toggle()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(accent)
                        .frame(width: 34, height: 34)
                        .background(accent.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Choose which quick settings are shown")
                .popover(isPresented: $isEditingQuickSettings, arrowEdge: .trailing) {
                    quickSettingsEditor
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        BatteryWidget()
                            .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 112, alignment: .topLeading)
                        networkTile(
                            title: "Wi-Fi",
                            detail: wifiEnabled ? "Connected · Home Wi-Fi" : "Off",
                            symbol: "wifi",
                            isOn: wifiEnabled
                        ) {
                            wifiEnabled.toggle()
                        }
                        .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 112)
                    }

                    BluetoothWidget(isEnabled: bluetoothEnabled)

                    LazyVGrid(columns: gridColumns, spacing: 6) {
                        ForEach(quickSettings.filter { visibleQuickSettings.contains($0.title) }) { setting in
                            quickSettingTile(setting)
                        }
                    }
                    if quickSettings.filter({ visibleQuickSettings.contains($0.title) }).isEmpty {
                        Text("No quick settings selected")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)

            WidgetCard(title: "Volume mixer", symbol: "speaker.wave.2.fill", tint: .blue) {
                controlSlider("System", symbol: "speaker.wave.2.fill", value: $volume)
                controlSlider("App audio", symbol: "waveform", value: $appVolume)
                controlSlider("Brightness", symbol: "sun.max.fill", value: $brightness)
            }
            .padding(.horizontal, 14)
            .padding(.top, 9)
            .padding(.bottom, 14)
        }
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: surfaceStyle.cornerRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .overlay {
            RoundedRectangle(cornerRadius: surfaceStyle.cornerRadius, style: .continuous)
                .strokeBorder(surfaceStyle == .classic98 ? Color.white : Color.white.opacity(0.76), lineWidth: surfaceStyle == .classic98 ? 2 : 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
    }

    private var quickSettingsEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Show in Quick Settings")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button("All") {
                    hiddenQuickSettingTitles = ""
                }
                .font(.system(size: 10, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundStyle(accent)
            }

            Text("Choose which tiles appear in the grid.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(quickSettings) { setting in
                        Toggle(setting.title, isOn: Binding(
                            get: { visibleQuickSettings.contains(setting.title) },
                            set: { isVisible in
                                setQuickSettingVisibility(setting.title, isVisible: isVisible)
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .font(.system(size: 11, weight: .medium))
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(height: 330)
            .scrollIndicators(.hidden)
        }
        .padding(14)
        .frame(width: 260)
    }

    private func setQuickSettingVisibility(_ title: String, isVisible: Bool) {
        var hiddenTitles = Set(hiddenQuickSettingTitles.split(separator: "|").map(String.init))
        if isVisible {
            hiddenTitles.remove(title)
        } else {
            hiddenTitles.insert(title)
        }
        hiddenQuickSettingTitles = hiddenTitles.sorted().joined(separator: "|")
    }

    private func networkTile(
        title: String,
        detail: String,
        symbol: String,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isOn ? .white : accent)
                    .frame(width: 31, height: 31)
                    .background(isOn ? accent : accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                    Text(detail)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer(minLength: 0)
            }
            .padding(9)
            .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 112, alignment: .leading)
            .background(cardBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }

    private func quickSettingTile(_ setting: QuickSetting) -> some View {
        let isOn = quickSettingIsOn(setting.title)
        return Button {
            activateQuickSetting(setting.title)
        } label: {
            HStack(spacing: 7) {
                Image(systemName: setting.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 17)
                Text(setting.title)
                    .font(.system(size: 9, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isOn ? Color.white : Color.primary.opacity(0.82))
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56, alignment: .leading)
            .background(
                isOn
                    ? AnyShapeStyle(Color(red: 1, green: 0.27, blue: 0.02))
                    : cardBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency),
                in: RoundedRectangle(cornerRadius: surfaceStyle == .classic98 ? 3 : 11)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(setting.title)
        .accessibilityValue(isOn ? "On" : "Off")
    }

    private func quickSettingIsOn(_ title: String) -> Bool {
        switch title {
        case "Bluetooth": bluetoothEnabled
        case "Dark Mode": isDarkMode
        case "VPN": vpnEnabled
        default: enabledQuickSettings.contains(title)
        }
    }

    private func activateQuickSetting(_ title: String) {
        switch title {
        case "Bluetooth":
            bluetoothEnabled.toggle()
        case "Dark Mode":
            isDarkMode.toggle()
        case "VPN":
            vpnEnabled.toggle()
        default:
            if enabledQuickSettings.contains(title) {
                enabledQuickSettings.remove(title)
            } else {
                enabledQuickSettings.insert(title)
            }
        }
    }

    private func controlSlider(_ title: String, symbol: String, value: Binding<Double>) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 12))
                .frame(width: 18)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .frame(width: 66, alignment: .leading)
            Slider(value: value)
                .tint(accent)
                .controlSize(.small)
        }
    }
}

private struct ClockFlyout: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    @Binding var showsClockSettings: Bool
    @Binding var uses24HourTime: Bool
    @Binding var showsSeconds: Bool
    @Binding var dateStyle: ClockDateStyle
    @Binding var clockTint: Color
    let accent: Color
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent)
                    Text("Notifications")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                }
                Spacer()
                Button("Clear all") {}
                    .font(.system(size: 10, weight: .semibold))
                    .buttonStyle(.bordered)
                    .tint(Color.roseAccent)
            }
            .padding(18)

            NotificationCard()
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            Rectangle()
                .fill(Color.black.opacity(0.07))
                .frame(height: 1)

            ScrollView {
                VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Text("Your calendar")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    monthButton("chevron.left", step: -1)
                    monthButton("chevron.right", step: 1)
                }

                MonthGrid(month: displayedMonth, selectedDate: $selectedDate)

                CalendarActivities(accent: accent)

                FocusWidget()

                HStack {
                    Label("30 min", systemImage: "timer")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showsClockSettings.toggle()
                    } label: {
                        Label("Clock style", systemImage: "paintpalette")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(clockTint)
                }
                .padding(.top, 2)

                if showsClockSettings {
                    ClockStyleSettings(
                        uses24HourTime: $uses24HourTime,
                        showsSeconds: $showsSeconds,
                        dateStyle: $dateStyle,
                        clockTint: $clockTint
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                }
                .padding(18)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: surfaceStyle.cornerRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: surfaceStyle.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: surfaceStyle.cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.76), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
        .animation(.easeInOut(duration: 0.22), value: showsClockSettings)
    }

    private func monthButton(_ symbol: String, step: Int) -> some View {
        Button {
            if let nextMonth = Calendar.current.date(byAdding: .month, value: step, to: displayedMonth) {
                displayedMonth = nextMonth
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct NotificationCard: View {
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14))
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Settings").font(.system(size: 10, weight: .semibold))
                    Spacer()
                    Text("now").font(.system(size: 9)).foregroundStyle(.tertiary)
                }
                Text("Your desktop is ready")
                    .font(.system(size: 11, weight: .semibold))
                Text("Your taskbar design is looking good. Explore the new widget board.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 1)
        }
    }
}

private struct MonthGrid: View {
    let month: Date
    @Binding var selectedDate: Date

    private var days: [Date?] {
        let calendar = Calendar.current
        guard
            let range = calendar.range(of: .day, in: .month, for: month),
            let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else {
            return []
        }

        let leadingDays = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
        let dates = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstDay) }
        return Array(repeating: nil, count: leadingDays) + dates.map(Optional.some)
    }

    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = max(0, calendar.firstWeekday - 1)
        return Array(symbols[start...] + symbols[..<start])
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 6) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 2)
            }

            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                    Button {
                        selectedDate = day
                    } label: {
                        Text(day.formatted(.dateTime.day()))
                            .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? .white : .primary.opacity(0.78))
                            .frame(maxWidth: .infinity)
                            .frame(height: 31)
                            .background {
                                if isSelected {
                                    Circle().fill(Color.roseAccent)
                                } else if Calendar.current.isDateInToday(day) {
                                    Circle().stroke(Color.roseAccent.opacity(0.55), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(height: 31)
                }
            }
        }
    }
}

private struct CalendarActivities: View {
    let accent: Color
    @State private var completedTasks: Set<String> = []
    @State private var isAgendaExpanded = true
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    private let events = [
        ("10:30", "Design check-in", "Studio"),
        ("14:00", "Project planning", "Online")
    ]
    private let tasks = ["Review design notes", "Send project update"]
    private let alarms = [("7:30 AM", "Weekdays"), ("9:00 AM", "Saturday")]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeader("Events", symbol: "calendar.badge.clock", trailing: "New event")
            ForEach(events, id: \.1) { time, title, location in
                HStack(spacing: 9) {
                    Text(time)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .leading)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accent)
                        .frame(width: 3, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 10, weight: .semibold))
                        Text(location).font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }

            Rectangle().fill(Color.black.opacity(0.07)).frame(height: 1)

            sectionHeader("Tasks", symbol: "checklist", trailing: "Add task")
            ForEach(tasks, id: \.self) { task in
                Button {
                    if completedTasks.contains(task) {
                        completedTasks.remove(task)
                    } else {
                        completedTasks.insert(task)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: completedTasks.contains(task) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(completedTasks.contains(task) ? accent : Color.secondary)
                        Text(task)
                            .strikethrough(completedTasks.contains(task))
                        Spacer()
                        Image(systemName: "star")
                            .foregroundStyle(.secondary.opacity(0.7))
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.82))
                }
                .buttonStyle(.plain)
            }

            Rectangle().fill(Color.black.opacity(0.07)).frame(height: 1)

            Button {
                isAgendaExpanded.toggle()
            } label: {
                HStack {
                    Label("Agenda", systemImage: "list.bullet.rectangle")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Text(isAgendaExpanded ? "Today · 2 items" : "Show today")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                    Image(systemName: isAgendaExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isAgendaExpanded {
                Text("2 events and 2 tasks scheduled for today")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Rectangle().fill(Color.black.opacity(0.07)).frame(height: 1)

            sectionHeader("Alarms", symbol: "alarm", trailing: "Add alarm")
            ForEach(alarms, id: \.0) { time, repeatDays in
                HStack {
                    Image(systemName: "alarm")
                        .foregroundStyle(accent)
                        .frame(width: 19)
                    Text(time)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    Text(repeatDays)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "togglepower")
                        .foregroundStyle(accent)
                }
            }
        }
        .padding(14)
        .background(cardBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func sectionHeader(_ title: String, symbol: String, trailing: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .semibold))
            Spacer()
            Button(trailing) {}
                .font(.system(size: 9, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundStyle(accent)
        }
    }
}

private struct ClockStyleSettings: View {
    @Binding var uses24HourTime: Bool
    @Binding var showsSeconds: Bool
    @Binding var dateStyle: ClockDateStyle
    @Binding var clockTint: Color
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Taskbar clock")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                ColorPicker("Text colour", selection: $clockTint, supportsOpacity: false)
                    .labelsHidden()
                    .help("Choose clock and date text colour")
            }

            HStack(spacing: 8) {
                styleChip("12-hour", isSelected: !uses24HourTime) { uses24HourTime = false }
                styleChip("24-hour", isSelected: uses24HourTime) { uses24HourTime = true }
                styleChip("Seconds", isSelected: showsSeconds) { showsSeconds.toggle() }
            }

            HStack(spacing: 7) {
                ForEach(ClockDateStyle.allCases) { style in
                    styleChip(style.title, isSelected: dateStyle == style) {
                        dateStyle = style
                    }
                }
            }
        }
        .padding(12)
        .background(cardBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func styleChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .primary.opacity(0.75))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(isSelected ? Color.roseAccent : Color.black.opacity(0.055), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsFlyout: View {
    @Binding var surfaceStyle: SurfaceStyle
    @Binding var usesDockPresentation: Bool
    @Binding var isDarkMode: Bool
    @Binding var usesPastelGradient: Bool
    @Binding var pastelTint: Color
    @Binding var gradientEndTint: Color
    @Binding var gradientAngle: Double
    @Binding var interfaceTransparency: Double
    @Binding var usesTaskbarGradient: Bool
    @Binding var taskbarGradientStart: Color
    @Binding var taskbarGradientEnd: Color
    @Binding var taskbarHeight: CGFloat
    let accent: Color
    let onClose: () -> Void
    @Environment(\.surfaceStyle) private var currentStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personalisation")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                    Text("Make this taskbar feel like yours")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.07), in: Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Taskbar mode")
                    .font(.system(size: 13, weight: .semibold))
                Toggle(isOn: Binding(
                    get: { !usesDockPresentation },
                    set: { usesDockPresentation = !$0 }
                )) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Windows taskbar UI")
                            .font(.system(size: 11, weight: .medium))
                        Text("Turn off to preview a macOS-style Dock presentation")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
            .padding(14)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.13 : 0.045), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 10) {
                Text("Appearance")
                    .font(.system(size: 13, weight: .semibold))
                Toggle(isOn: $isDarkMode) {
                    Label(isDarkMode ? "Dark appearance" : "Light appearance", systemImage: isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                        .font(.system(size: 11, weight: .medium))
                }
                .toggleStyle(.switch)
            }
            .padding(14)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.13 : 0.045), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 11) {
                Text("Surface style")
                    .font(.system(size: 13, weight: .semibold))
                ForEach(SurfaceStyle.allCases) { style in
                    Button {
                        surfaceStyle = style
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: style == .classic98 ? 2 : 10)
                                .fill(style.cardFill(darkMode: isDarkMode))
                                .overlay {
                                    Circle()
                                        .fill(accent.opacity(0.75))
                                        .frame(width: 18, height: 18)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: style == .classic98 ? 2 : 10)
                                        .strokeBorder(style == .classic98 ? Color.white : Color.white.opacity(0.9), lineWidth: style == .classic98 ? 2 : 1)
                                }
                                .frame(width: 48, height: 38)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(style.title)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(style.subtitle)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if surfaceStyle == style {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(accent)
                            }
                        }
                        .padding(9)
                        .background(surfaceStyle == style ? style.accent(darkMode: isDarkMode).opacity(0.1) : Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: style.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Pastel desktop")
                    .font(.system(size: 13, weight: .semibold))
                Toggle(isOn: $usesPastelGradient) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Use gradient wallpaper")
                            .font(.system(size: 11, weight: .medium))
                        Text("Try a soft, shifting pastel background")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                HStack {
                    ColorPicker("Start colour", selection: $pastelTint, supportsOpacity: false)
                    ColorPicker("End colour", selection: $gradientEndTint, supportsOpacity: false)
                }
                .font(.system(size: 10, weight: .medium))
                HStack {
                    Text("Gradient angle")
                        .font(.system(size: 10, weight: .medium))
                    Slider(value: $gradientAngle, in: 0...360, step: 1)
                        .tint(accent)
                    Text("\(Int(gradientAngle))°")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, alignment: .trailing)
                }
            }
            .padding(14)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.13 : 0.045), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 10) {
                Text("Taskbar gradient")
                    .font(.system(size: 13, weight: .semibold))
                Toggle("Use custom taskbar gradient", isOn: $usesTaskbarGradient)
                    .toggleStyle(.switch)
                    .font(.system(size: 10, weight: .medium))
                HStack {
                    ColorPicker("Start", selection: $taskbarGradientStart, supportsOpacity: false)
                    ColorPicker("End", selection: $taskbarGradientEnd, supportsOpacity: false)
                }
                .font(.system(size: 10, weight: .medium))
            }
            .padding(14)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.13 : 0.045), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Transparency")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Text("\(Int(interfaceTransparency * 100))%")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Toggle(isOn: Binding(
                    get: { interfaceTransparency > 0 },
                    set: { interfaceTransparency = $0 ? 0.68 : 0 }
                )) {
                    Text("Enable transparency")
                        .font(.system(size: 10, weight: .medium))
                }
                .toggleStyle(.switch)
                Slider(value: $interfaceTransparency, in: 0...0.9, step: 0.01)
                    .tint(accent)
                    .disabled(interfaceTransparency == 0)
                Text("Adjust panels and taskbar together")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.13 : 0.045), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text("Taskbar height")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Text("\(Int(taskbarHeight)) pt")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $taskbarHeight, in: 32...48, step: 2)
                    .tint(accent)
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        }
        .scrollIndicators(.hidden)
        .background(panelBackground(style: currentStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: currentStyle.cornerRadius, style: .continuous))
        .background(surfaceWash(style: currentStyle, darkMode: colorScheme == .dark))
        .overlay {
            RoundedRectangle(cornerRadius: currentStyle.cornerRadius, style: .continuous)
                .strokeBorder(currentStyle == .classic98 ? Color.white : Color.white.opacity(0.76), lineWidth: currentStyle == .classic98 ? 2 : 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
    }
}

private struct StartFlyout: View {
    let onClose: () -> Void
    let accent: Color
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    private let apps: [(String, String, String, Color)] = [
        ("com.apple.Safari", "safari.fill", "Safari", .blue),
        ("com.apple.finder", "folder.fill", "Finder", .orange),
        ("com.apple.mail", "envelope.fill", "Mail", .cyan),
        ("com.apple.iCal", "calendar", "Calendar", .red),
        ("com.apple.MobileSMS", "message.fill", "Messages", .green),
        ("com.apple.Music", "music.note", "Music", .purple),
        ("com.apple.systempreferences", "gearshape.fill", "System Settings", .gray),
        ("com.apple.Photos", "photo.fill", "Photos", .pink),
        ("com.apple.Terminal", "terminal.fill", "Terminal", .primary),
        ("com.apple.Notes", "doc.text.fill", "Notes", .orange),
        ("com.apple.TV", "video.fill", "TV", .purple),
        ("com.apple.Maps", "map.fill", "Maps", .green),
        ("com.apple.calculator", "calculator.fill", "Calculator", .blue)
    ]

    private let recentApps: [(String, String, Color, String)] = [
        ("safari.fill", "Browser", .blue, "Opened 12 minutes ago"),
        ("photo.fill", "Photos", .pink, "Opened 34 minutes ago"),
        ("doc.text.fill", "Project notes", .orange, "Edited 1 hour ago"),
        ("folder.fill", "Design assets", .yellow, "Opened yesterday"),
        ("music.note", "Music", .purple, "Played recently")
    ]

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 11) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(accent)
                Text("Search apps, settings and files")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.06), in: Capsule())

            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Pinned")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Text("All apps  ›")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(accent)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 19) {
                        ForEach(apps, id: \.2) { bundleIdentifier, symbol, title, color in
                            VStack(spacing: 8) {
                                MacOSAppIcon(
                                    bundleIdentifier: bundleIdentifier,
                                    fallbackSymbol: symbol,
                                    fallbackColor: color,
                                    size: 34
                                )
                                    .frame(width: 54, height: 54)
                                    .background(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.07), in: RoundedRectangle(cornerRadius: 15))
                                Text(title).font(.system(size: 10, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    HStack {
                        Text("Recommended")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text("More  ›")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                    .padding(.top, 4)

                    HStack(spacing: 12) {
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 20))
                            .foregroundStyle(accent)
                            .frame(width: 42, height: 42)
                            .background(accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Design concept")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Recently opened · 10 min ago")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.05), in: RoundedRectangle(cornerRadius: 12))

                    HStack {
                        Text("Widgets")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Weather", systemImage: "cloud.sun.fill")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.blue)
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("13°")
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                Text("Mostly clear")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Text("Durres")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.blue.opacity(colorScheme == .dark ? 0.22 : 0.1), in: RoundedRectangle(cornerRadius: 13))

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Now playing", systemImage: "music.note")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.purple)
                            Text("Close to You")
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                            HStack {
                                Text("Reality Club")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Image(systemName: "play.fill")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(accent)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.purple.opacity(colorScheme == .dark ? 0.2 : 0.08), in: RoundedRectangle(cornerRadius: 13))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(Color.black.opacity(0.07))
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Text("Most used")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(recentApps, id: \.1) { symbol, title, color, detail in
                        HStack(spacing: 10) {
                            Image(systemName: symbol)
                                .font(.system(size: 16))
                                .foregroundStyle(color)
                                .frame(width: 33, height: 33)
                                .background(Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.07), in: RoundedRectangle(cornerRadius: 9))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(title).font(.system(size: 10, weight: .semibold))
                                Text(detail).font(.system(size: 8)).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    Text("All programs")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.top, 7)

                    ForEach([
                        ("A", "Accessibility", "figure.walk"),
                        ("C", "Calculator", "calculator.fill"),
                        ("F", "Files", "folder.fill"),
                        ("M", "Media", "play.rectangle.fill"),
                        ("N", "Notes", "note.text")
                    ], id: \.1) { letter, name, symbol in
                        HStack(spacing: 8) {
                            Text(letter)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(accent)
                                .frame(width: 20, height: 20)
                                .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
                            Image(systemName: symbol)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(name)
                                .font(.system(size: 9, weight: .medium))
                            Spacer()
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(width: 250, alignment: .leading)
            }

            HStack {
                Label("Your profile", systemImage: "person.crop.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "power")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.07), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(25)
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: surfaceStyle.cornerRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .overlay {
            RoundedRectangle(cornerRadius: surfaceStyle.cornerRadius, style: .continuous)
                .strokeBorder(surfaceStyle == .classic98 ? Color.white : Color.white.opacity(0.76), lineWidth: surfaceStyle == .classic98 ? 2 : 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
    }
}

private enum ClockDateStyle: String, CaseIterable, Identifiable {
    case compact
    case weekday
    case full

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: "Short"
        case .weekday: "Weekday"
        case .full: "Long"
        }
    }

    func string(from date: Date) -> String {
        switch self {
        case .compact:
            date.formatted(.dateTime.month(.twoDigits).day().year())
        case .weekday:
            date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        case .full:
            date.formatted(.dateTime.month(.wide).day().year())
        }
    }
}

private func clockTime(_ date: Date, uses24HourTime: Bool, showsSeconds: Bool) -> String {
    let formatter = DateFormatter()
    formatter.locale = .current
    formatter.dateFormat = uses24HourTime
        ? (showsSeconds ? "HH:mm:ss" : "HH:mm")
        : (showsSeconds ? "h:mm:ss a" : "h:mm a")
    return formatter.string(from: date)
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

private extension Color {
    static let roseAccent = Color(red: 0.82, green: 0.34, blue: 0.43)
    static let roseMist = Color(red: 0.98, green: 0.92, blue: 0.93)
}
