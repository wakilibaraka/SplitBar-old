import AppKit
import Combine
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

enum SurfaceStyle: String, CaseIterable, Identifiable {
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
    var cornerRadius: CGFloat?
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.overlay {
            if surfaceStyle == .aero {
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

private extension View {
    func aeroSheen(cornerRadius: CGFloat? = nil) -> some View {
        modifier(AeroSheen(cornerRadius: cornerRadius))
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

private enum DashboardWidget: String, CaseIterable, Identifiable {
    case weather
    case systemResources
    case nowPlaying
    case photos
    case stickyNotes
    case watchlist
    case date
    case systemRings
    case network

    var id: String { rawValue }

    var defaultSize: WidgetSizePreset {
        switch self {
        case .weather: .large
        case .systemResources: .medium
        case .date, .systemRings, .network: .small
        case .nowPlaying, .photos, .stickyNotes, .watchlist: .small
        }
    }
}

private enum WidgetSizePreset: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case extraLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .extraLarge: "Extra large"
        }
    }

    var spansBoard: Bool {
        self == .large || self == .extraLarge
    }

    var cardContentHeight: CGFloat {
        switch self {
        case .small: 78
        case .medium: 126
        case .large: 162
        case .extraLarge: 210
        }
    }

    var weatherContentHeight: CGFloat {
        switch self {
        case .small: 220
        case .medium: 285
        case .large: 350
        case .extraLarge: 405
        }
    }

    var estimatedHeight: CGFloat {
        cardContentHeight + 56
    }
}

private enum WidgetBoardSection: Identifiable {
    case columns(id: Int, leading: [DashboardWidget], trailing: [DashboardWidget])
    case fullWidth(id: Int, widget: DashboardWidget)

    var id: Int {
        switch self {
        case let .columns(id, _, _), let .fullWidth(id, _): id
        }
    }
}

private enum ClockDisplayStyle: String, CaseIterable, Identifiable {
    case stacked
    case inline
    case digital
    case analog

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stacked: "Stacked"
        case .inline: "Inline"
        case .digital: "Digital"
        case .analog: "Analog"
        }
    }
}

private enum TaskbarIconSize: String, CaseIterable, Identifiable {
    case medium
    case large
    case extraLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .medium: "Medium"
        case .large: "Large"
        case .extraLarge: "Extra large"
        }
    }

    var glyphFraction: CGFloat {
        switch self {
        case .medium: 0.54
        case .large: 0.64
        case .extraLarge: 0.76
        }
    }
}

enum TrashPlacement: String, CaseIterable, Identifiable {
    case withApps
    case beforeTray
    case beforeClock
    case farRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .withApps: "With apps"
        case .beforeTray: "Before tray"
        case .beforeClock: "Before clock"
        case .farRight: "Far right"
        }
    }
}

enum TaskbarMode: String, CaseIterable, Identifiable {
    case windows
    case macOS
    case split3
    case split4
    case centered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .windows: "Windows"
        case .macOS: "macOS"
        case .split3: "Split 3"
        case .split4: "Split 4"
        case .centered: "Centered"
        }
    }

    var isSingleIsland: Bool {
        switch self {
        case .windows, .macOS, .centered: true
        case .split3, .split4: false
        }
    }

    var isSplit: Bool { !isSingleIsland }

    var detail: String {
        switch self {
        case .windows: "Full-width bar with weather, centred apps, tray and clock"
        case .macOS: "Floating dock-style bar"
        case .centered: "One narrower centred bar"
        case .split3: "Weather, apps, then tray and clock"
        case .split4: "Weather, apps, tray, then clock"
        }
    }
}

enum CornerStyle: String, CaseIterable, Identifiable {
    case pill
    case roundedRect
    case sharp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pill: "Pill"
        case .roundedRect: "Rounded"
        case .sharp: "Sharp"
        }
    }

    func shellRadius(surfaceStyle: SurfaceStyle) -> CGFloat {
        switch self {
        case .pill: 26
        case .roundedRect: surfaceStyle.cornerRadius
        case .sharp: 2
        }
    }
}

enum CornerScope: String, CaseIterable, Identifiable {
    case universal
    case perSurface

    var id: String { rawValue }

    var title: String {
        switch self {
        case .universal: "Universal"
        case .perSurface: "Per surface"
        }
    }
}

enum CornerSurface {
    case taskbar
    case widgets
    case flyouts
}

enum TaskbarSection: String, CaseIterable, Identifiable, Hashable {
    case weather
    case apps
    case tray
    case clock

    var id: String { rawValue }

    static func islands(for mode: TaskbarMode) -> [[TaskbarSection]] {
        switch mode {
        case .windows, .macOS, .centered:
            return [[.weather, .apps, .tray, .clock]]
        case .split3:
            return [[.weather], [.apps], [.tray, .clock]]
        case .split4:
            return [[.weather], [.apps], [.tray], [.clock]]
        }
    }
}

enum TaskbarStripMetrics {
    static func tileStride(barHeight: CGFloat) -> CGFloat { max(28, barHeight - 4) + 4 }

    static func layout(
        screenWidth: CGFloat,
        mode: TaskbarMode,
        barHeight: CGFloat,
        gap: CGFloat,
        appCount: Int,
        bottomMargin: CGFloat = 0
    ) -> TaskbarStrip.IslandLayout {
        let stride = tileStride(barHeight: barHeight)
        return TaskbarStrip.layoutIslands(
            screenWidth: screenWidth,
            mode: mode,
            tileStride: stride,
            appCount: appCount,
            weatherWidth: 196,
            trayWidth: stride * 2,
            clockWidth: 96,
            clusterWidth: stride * 3,
            gap: gap,
            margin: 12,
            barHeight: barHeight,
            bottomMargin: bottomMargin
        )
    }
}

struct TaskbarDivider: Identifiable, Equatable, Codable, Sendable {
    var id: UUID
    var anchorBundleID: String?

    init(id: UUID = UUID(), anchorBundleID: String? = nil) {
        self.id = id
        self.anchorBundleID = anchorBundleID
    }
}

enum StripItem: Equatable, Hashable {
    case app(String)
    case divider(UUID)
}

enum TaskbarStrip {
    struct IslandLayout: Equatable {
        struct Island: Equatable {
            var sections: [TaskbarSection]
            var frame: CGRect
        }

        var islands: [Island]
        var visibleAppTiles: Int
        var showsOverflow: Bool
    }

    static func compose(pins: [String], runningOrder: [String], dividers: [TaskbarDivider]) -> [StripItem] {
        var items: [StripItem] = []
        var seen = Set<String>()
        for bundleID in pins + runningOrder.filter({ !pins.contains($0) }) {
            guard seen.insert(bundleID).inserted else { continue }
            items.append(.app(bundleID))
            for divider in dividers where divider.anchorBundleID == bundleID {
                items.append(.divider(divider.id))
            }
        }
        for divider in dividers where divider.anchorBundleID == nil {
            items.append(.divider(divider.id))
        }
        return pruned(items)
    }

    static func pruned(_ items: [StripItem]) -> [StripItem] {
        var result: [StripItem] = []
        for item in items {
            if case .divider = item {
                guard let last = result.last, case .app = last else { continue }
            }
            result.append(item)
        }
        while case .divider = result.last {
            result.removeLast()
        }
        return result
    }

    static func layoutIslands(
        screenWidth: CGFloat,
        mode: TaskbarMode,
        tileStride: CGFloat,
        appCount: Int,
        weatherWidth: CGFloat,
        trayWidth: CGFloat,
        clockWidth: CGFloat,
        clusterWidth: CGFloat,
        gap: CGFloat,
        margin: CGFloat,
        barHeight: CGFloat,
        bottomMargin: CGFloat
    ) -> IslandLayout {
        let islandSections = TaskbarSection.islands(for: mode)
        guard islandSections.count > 1 else {
            return IslandLayout(islands: [], visibleAppTiles: appCount, showsOverflow: false)
        }
        let y = bottomMargin

        func fixedWidth(_ sections: [TaskbarSection]) -> CGFloat? {
            if sections == [.weather] { return weatherWidth }
            if sections == [.tray, .clock] { return trayWidth + 8 + clockWidth }
            if sections == [.tray] { return trayWidth }
            if sections == [.clock] { return clockWidth }
            return nil
        }

        func appsWidth(_ count: Int) -> CGFloat {
            CGFloat(count) * tileStride + clusterWidth + 24
        }

        var frames = [CGRect](repeating: .zero, count: islandSections.count)
        var rightEdge = screenWidth - margin
        for (index, sections) in islandSections.enumerated().reversed() {
            guard let width = fixedWidth(sections) else { continue }
            if sections == [.weather] {
                frames[index] = CGRect(x: margin, y: y, width: width, height: barHeight)
                continue
            }
            rightEdge -= width
            frames[index] = CGRect(x: rightEdge, y: y, width: width, height: barHeight)
            rightEdge -= gap
        }

        var visibleApps = appCount
        var overflow = false
        if let appsIndex = islandSections.firstIndex(where: { $0.contains(.apps) }) {
            let leftCount = islandSections[..<appsIndex].count
            let leftReserved = islandSections[..<appsIndex].compactMap(fixedWidth).reduce(0, +)
                + CGFloat(leftCount) * gap + margin
            let rightReserved = (screenWidth - margin) - rightEdge
            let available = screenWidth - leftReserved - rightReserved
            while visibleApps > 1, appsWidth(visibleApps) > available {
                visibleApps -= 1
            }
            overflow = visibleApps < appCount
            let width = max(tileStride, min(appsWidth(visibleApps), max(0, available)))
            let spanWidth = max(0, screenWidth - leftReserved - rightReserved)
            frames[appsIndex] = CGRect(
                x: leftReserved + max(0, (spanWidth - width) / 2),
                y: y,
                width: width,
                height: barHeight
            )
        }

        let result = islandSections.enumerated().map { IslandLayout.Island(sections: $0.element, frame: frames[$0.offset]) }
        return IslandLayout(islands: result, visibleAppTiles: visibleApps, showsOverflow: overflow)
    }
}

enum RunningIndicatorStyle: String, CaseIterable, Identifiable {
    case dot
    case dash
    case highlight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dot: "Dot"
        case .dash: "Dash"
        case .highlight: "Highlight"
        }
    }
}

enum RunningIndicatorSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }

    var dotDiameter: CGFloat {
        switch self {
        case .small: 4
        case .medium: 6
        case .large: 8
        }
    }

    var dashWidth: CGFloat {
        switch self {
        case .small: 14
        case .medium: 18
        case .large: 24
        }
    }

    var dashHeight: CGFloat {
        switch self {
        case .small: 3
        case .medium: 4
        case .large: 5
        }
    }
}

enum AppMinimizeMode: String, CaseIterable, Identifiable {
    case hide
    case minimize

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hide: "Hide"
        case .minimize: "Minimize"
        }
    }
}

enum ContextMenuStyle: String, CaseIterable, Identifiable {
    case native
    case windows

    var id: String { rawValue }

    var title: String {
        switch self {
        case .native: "Native"
        case .windows: "Windows"
        }
    }
}

enum TaskbarTileAction {
    case revealInFinder(bundleID: String)
    case hideApp(bundleID: String)
    case quitApp(bundleID: String)
    case newWindow(bundleID: String)
    case togglePin(bundleID: String)
    case openRecent(URL)
}

enum PanelKind: String, CaseIterable, Identifiable {
    case start
    case widgets
    case calendar
    case controls
    case settings
    var id: String { rawValue }

    var title: String {
        switch self {
        case .start: "Start"
        case .widgets: "Widgets"
        case .calendar: "Calendar"
        case .controls: "Quick Settings"
        case .settings: "Personalisation"
        }
    }

    var defaultWidth: CGFloat {
        switch self {
        case .start: 640
        case .widgets: 480
        case .calendar: 380
        case .controls: 360
        case .settings: 560
        }
    }

    var minimumWidth: CGFloat {
        switch self {
        case .start: 560
        case .widgets: 400
        case .calendar: 340
        case .controls: 320
        case .settings: 480
        }
    }

    var maximumWidth: CGFloat {
        switch self {
        case .start: 860
        case .widgets: 640
        case .calendar: 520
        case .controls: 520
        case .settings: 680
        }
    }
}

private enum WallpaperPreset: String, CaseIterable, Identifiable {
    case pastelBloom
    case ocean
    case sunset
    case midnight
    case graphite
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pastelBloom: "Pastel bloom"
        case .ocean: "Ocean"
        case .sunset: "Sunset"
        case .midnight: "Midnight"
        case .graphite: "Graphite"
        case .custom: "Custom"
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
        }
    }

    var isDark: Bool {
        self == .midnight || self == .graphite
    }
}

private struct LauncherApp: Identifiable {
    let bundleIdentifier: String
    let symbol: String
    let title: String
    let color: Color

    var id: String { bundleIdentifier }
}

private struct LauncherFolder: Identifiable {
    let title: String
    let symbol: String
    let tint: Color
    let directory: FileManager.SearchPathDirectory

    var id: String { title }

    var url: URL? {
        FileManager.default.urls(for: directory, in: .userDomainMask).first
    }
}

private enum LauncherDefaults {
    static let folders: [LauncherFolder] = [
        LauncherFolder(title: "Desktop", symbol: "desktopcomputer", tint: .blue, directory: .desktopDirectory),
        LauncherFolder(title: "Documents", symbol: "doc.text.fill", tint: .indigo, directory: .documentDirectory),
        LauncherFolder(title: "Movies", symbol: "film.fill", tint: .purple, directory: .moviesDirectory),
        LauncherFolder(title: "Music", symbol: "music.note", tint: .pink, directory: .musicDirectory),
        LauncherFolder(title: "Pictures", symbol: "photo.fill", tint: .orange, directory: .picturesDirectory),
        LauncherFolder(title: "Downloads", symbol: "arrow.down.circle.fill", tint: .teal, directory: .downloadsDirectory)
    ]

    static let apps: [LauncherApp] = [
        LauncherApp(bundleIdentifier: "com.apple.Safari", symbol: "safari.fill", title: "Safari", color: .blue),
        LauncherApp(bundleIdentifier: "com.apple.finder", symbol: "folder.fill", title: "Finder", color: .orange),
        LauncherApp(bundleIdentifier: "com.apple.mail", symbol: "envelope.fill", title: "Mail", color: .cyan),
        LauncherApp(bundleIdentifier: "com.apple.iCal", symbol: "calendar", title: "Calendar", color: .red),
        LauncherApp(bundleIdentifier: "com.apple.MobileSMS", symbol: "message.fill", title: "Messages", color: .green),
        LauncherApp(bundleIdentifier: "com.apple.Music", symbol: "music.note", title: "Music", color: .purple),
        LauncherApp(bundleIdentifier: "com.apple.systempreferences", symbol: "gearshape.fill", title: "System Settings", color: .gray),
        LauncherApp(bundleIdentifier: "com.apple.Photos", symbol: "photo.fill", title: "Photos", color: .pink),
        LauncherApp(bundleIdentifier: "com.apple.Terminal", symbol: "terminal.fill", title: "Terminal", color: .primary),
        LauncherApp(bundleIdentifier: "com.apple.Notes", symbol: "doc.text.fill", title: "Notes", color: .orange),
        LauncherApp(bundleIdentifier: "com.apple.TV", symbol: "video.fill", title: "TV", color: .purple),
        LauncherApp(bundleIdentifier: "com.apple.Maps", symbol: "map.fill", title: "Maps", color: .green),
        LauncherApp(bundleIdentifier: "com.apple.calculator", symbol: "calculator.fill", title: "Calculator", color: .blue)
    ]
    static let pinnedBundleIDs = Array(apps.prefix(8).map(\.bundleIdentifier))
}

@MainActor
final class TaskbarConceptState: ObservableObject {
    @Published var openPanel: OpenPanel?
    @Published var surfaceStyle = SurfaceStyle.glass
    @Published fileprivate var usesDockPresentation = false
    @Published fileprivate var isDarkMode = false
    @Published fileprivate var wallpaperPreset = WallpaperPreset.pastelBloom {
        didSet { UserDefaults.standard.set(wallpaperPreset.rawValue, forKey: "wallpaper.preset") }
    }
    @Published fileprivate var pastelTint = Color(red: 0.91, green: 0.69, blue: 0.87) {
        didSet { persist(key: "wallpaper.customStart", value: pastelTint.storedRGBA) }
    }
    @Published fileprivate var gradientEndTint = Color(red: 0.47, green: 0.70, blue: 0.86) {
        didSet { persist(key: "wallpaper.customEnd", value: gradientEndTint.storedRGBA) }
    }
    @Published fileprivate var gradientAngle = 35.0 {
        didSet { persist(key: "wallpaper.gradientAngle", value: gradientAngle) }
    }
    @Published fileprivate var interfaceTransparency = 0.68
    @Published fileprivate var usesTaskbarGradient = false
    @Published fileprivate var taskbarGradientStart = Color(red: 0.78, green: 0.48, blue: 0.86)
    @Published fileprivate var taskbarGradientEnd = Color(red: 0.96, green: 0.38, blue: 0.42)
    @Published var taskbarHeight: CGFloat = 46
    @Published var showsTaskbarPanel = false {
        didSet { UserDefaults.standard.set(showsTaskbarPanel, forKey: "taskbar.panelShown") }
    }
    @Published fileprivate var taskbarIconSize = TaskbarIconSize.medium {
        didSet { UserDefaults.standard.set(taskbarIconSize.rawValue, forKey: "taskbar.iconSize") }
    }
    @Published fileprivate var trashPlacement = TrashPlacement.withApps {
        didSet { UserDefaults.standard.set(trashPlacement.rawValue, forKey: "taskbar.trashPlacement") }
    }
    @Published var taskbarMode = TaskbarMode.windows {
        didSet { UserDefaults.standard.set(taskbarMode.rawValue, forKey: "taskbar.mode") }
    }
    @Published var userDividers: [TaskbarDivider] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(userDividers) {
                UserDefaults.standard.set(data, forKey: "taskbar.dividers")
            }
        }
    }
    @Published var trashAnchors: [String: String] = [:] {
        didSet { UserDefaults.standard.set(trashAnchors, forKey: "taskbar.trashAnchors") }
    }
    @Published var clusterOrder: [String] = ["downloads", "trash", "status"] {
        didSet { UserDefaults.standard.set(clusterOrder, forKey: "taskbar.clusterOrder") }
    }
    @Published var islandGap: CGFloat = 10 {
        didSet { UserDefaults.standard.set(Double(islandGap), forKey: "taskbar.islandGap") }
    }
    @Published var centeredBarWidth: CGFloat = 720 {
        didSet { UserDefaults.standard.set(Double(centeredBarWidth), forKey: "taskbar.centeredWidth") }
    }
    @Published var cornerStyle = CornerStyle.roundedRect {
        didSet { UserDefaults.standard.set(cornerStyle.rawValue, forKey: "corners.style") }
    }
    @Published var cornerScope = CornerScope.universal {
        didSet { UserDefaults.standard.set(cornerScope.rawValue, forKey: "corners.scope") }
    }
    @Published var cornerTaskbar = CornerStyle.roundedRect {
        didSet { UserDefaults.standard.set(cornerTaskbar.rawValue, forKey: "corners.taskbar") }
    }
    @Published var cornerWidgets = CornerStyle.roundedRect {
        didSet { UserDefaults.standard.set(cornerWidgets.rawValue, forKey: "corners.widgets") }
    }
    @Published var cornerFlyouts = CornerStyle.roundedRect {
        didSet { UserDefaults.standard.set(cornerFlyouts.rawValue, forKey: "corners.flyouts") }
    }

    func cornerStyle(for surface: CornerSurface) -> CornerStyle {
        guard cornerScope == .perSurface else { return cornerStyle }
        switch surface {
        case .taskbar: return cornerTaskbar
        case .widgets: return cornerWidgets
        case .flyouts: return cornerFlyouts
        }
    }

    func shellRadius(for surface: CornerSurface) -> CGFloat {
        cornerStyle(for: surface).shellRadius(surfaceStyle: surfaceStyle)
    }

    func trashPlacement(for mode: TaskbarMode) -> TrashPlacement {
        if let saved = trashAnchors[mode.rawValue].flatMap(TrashPlacement.init(rawValue:)) {
            return saved
        }
        return trashPlacement
    }

    private var tileHoverTask: Task<Void, Never>?

    func handleTaskbarTileHover(_ bundleIdentifier: String, hovering: Bool) {
        tileHoverTask?.cancel()
        tileHoverTask = nil
        guard showWindowPreviews else { return }
        if hovering, runningBundleIDs.contains(bundleIdentifier) {
            tileHoverTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled, let self else { return }
                self.previewBundleID = bundleIdentifier
            }
        } else if !hovering, previewBundleID == bundleIdentifier {
            previewBundleID = nil
        }
    }

    func cancelTaskbarTileHover() {
        tileHoverTask?.cancel()
        tileHoverTask = nil
    }
    @Published fileprivate var systemStatus = SystemStatusSnapshot.placeholder()
    private let systemStatusService = SystemStatusService()
    @Published fileprivate var topProcesses: [TopProcess] = []
    @Published var totalProcessCount: Int = 0
    @Published var runningBundleIDs: Set<String> = []
    @Published var runningAppOrder: [String] = []
    @Published var frontmostBundleID: String?
    @Published var runningIndicatorStyle = RunningIndicatorStyle.dot {
        didSet { UserDefaults.standard.set(runningIndicatorStyle.rawValue, forKey: "taskbar.indicatorStyle") }
    }
    @Published var runningIndicatorSize = RunningIndicatorSize.medium {
        didSet { UserDefaults.standard.set(runningIndicatorSize.rawValue, forKey: "taskbar.indicatorSize") }
    }
    @Published var runningIndicatorColor = Color.blue {
        didSet { UserDefaults.standard.set(runningIndicatorColor.storedRGBA, forKey: "taskbar.indicatorColor") }
    }
    @Published var minimizeMode = AppMinimizeMode.hide {
        didSet { UserDefaults.standard.set(minimizeMode.rawValue, forKey: "taskbar.minimizeMode") }
    }
    @Published var contextMenuStyle = ContextMenuStyle.native {
        didSet { UserDefaults.standard.set(contextMenuStyle.rawValue, forKey: "taskbar.menuStyle") }
    }
    @Published var showWindowPreviews = false {
        didSet { UserDefaults.standard.set(showWindowPreviews, forKey: "taskbar.windowPreviews") }
    }
    @Published var hideMacDock = false {
        didSet { UserDefaults.standard.set(hideMacDock, forKey: "dock.hidden") }
    }
    @Published var showWifiName = false {
        didSet { UserDefaults.standard.set(showWifiName, forKey: "status.showWifiName") }
    }
    @Published var showBluetoothDevices = false {
        didSet {
            UserDefaults.standard.set(showBluetoothDevices, forKey: "status.showBluetoothDevices")
            systemStatusService.bluetoothDeviceMonitoringEnabled = showBluetoothDevices
        }
    }
    @Published var displayBrightness = 0.82
    @Published var displayBrightnessUnavailable = false
    @Published var ddcBrightnessEnabled = false {
        didSet { UserDefaults.standard.set(ddcBrightnessEnabled, forKey: "display.ddcEnabled") }
    }

    fileprivate func activeBrightnessService() -> (any DisplayBrightnessControlling)? {
        if let builtIn = DisplayBrightness.builtIn() {
            return builtIn
        }
        if ddcBrightnessEnabled {
            return DisplayBrightness.externalDDC()
        }
        return nil
    }

    fileprivate func refreshDisplayBrightness() {
        guard let service = activeBrightnessService() else {
            displayBrightnessUnavailable = true
            return
        }
        displayBrightnessUnavailable = false
        if let level = service.currentLevel() {
            displayBrightness = min(1, max(0, level))
        }
    }

    fileprivate func setDisplayBrightness(_ level: Double) {
        guard let service = activeBrightnessService() else { return }
        if service.setLevel(level) {
            displayBrightness = min(1, max(0, level))
            displayBrightnessUnavailable = false
        }
    }
    @Published var previewBundleID: String?
    @Published var systemMetrics: SystemMetrics?
    @Published var weather = WeatherState.defaultSample()
    @Published var nowPlaying = NowPlayingState.idle()
    var onTogglePlayback: (() -> Void)?
    @Published var networkPeakIn: Double = 0
    @Published var networkPeakOut: Double = 0
    private let processSampleQueue = DispatchQueue(label: "com.baraka.splitbar.topprocesses", qos: .utility)
    @Published fileprivate var panelWidths: [PanelKind: CGFloat] = [:] {
        didSet {
            UserDefaults.standard.set(
                Dictionary(uniqueKeysWithValues: panelWidths.map { ($0.key.rawValue, Double($0.value)) }),
                forKey: "panels.widths"
            )
        }
    }
    @Published fileprivate var showsClockSettings = false
    @Published fileprivate var uses24HourTime = false
    @Published fileprivate var showsSeconds = false
    @Published fileprivate var dateStyle = ClockDateStyle.compact
    @Published fileprivate var clockDisplayStyle = ClockDisplayStyle.stacked {
        didSet { UserDefaults.standard.set(clockDisplayStyle.rawValue, forKey: "clock.displayStyle") }
    }
    @Published fileprivate var clockTint = Color.roseAccent
    @Published fileprivate var displayedMonth = Calendar.current.startOfMonth(for: .now)
    @Published fileprivate var selectedDate = Date.now
    @Published fileprivate var widgetOrder = DashboardWidget.allCases {
        didSet { UserDefaults.standard.set(widgetOrder.map(\.rawValue), forKey: "widgets.order") }
    }
    @Published fileprivate var widgetSizes: [DashboardWidget: WidgetSizePreset] = [:] {
        didSet {
            UserDefaults.standard.set(
                Dictionary(uniqueKeysWithValues: widgetSizes.map { ($0.key.rawValue, $0.value.rawValue) }),
                forKey: "widgets.sizes"
            )
        }
    }
    @Published var pinnedAppBundleIDs = LauncherDefaults.pinnedBundleIDs {
        didSet { UserDefaults.standard.set(pinnedAppBundleIDs, forKey: "launcher.pinnedApps") }
    }
    @Published fileprivate var showOnlyFourPinned = false {
        didSet { UserDefaults.standard.set(showOnlyFourPinned, forKey: "launcher.showOnlyFour") }
    }
    @Published fileprivate var recentAppIDs: [String] = [] {
        didSet { UserDefaults.standard.set(recentAppIDs, forKey: "launcher.recentApps") }
    }
    @Published fileprivate var recentFolderTitles: [String] = [] {
        didSet { UserDefaults.standard.set(recentFolderTitles, forKey: "launcher.recentFolders") }
    }
    @Published fileprivate var hiddenQuickSettingTitles: Set<String> = [] {
        didSet { UserDefaults.standard.set(hiddenQuickSettingTitles.sorted().joined(separator: "|"), forKey: "quickSettings.hiddenTiles") }
    }
    @Published fileprivate var enabledQuickSettings: Set<String> = [
        "Finder Path Bar", "Show Extension", "True Tone"
    ]
    @Published fileprivate var bluetoothEnabled = true
    @Published fileprivate var vpnEnabled = false
    @Published fileprivate var appVolume: Double = 0.52

    init() {
        let defaults = UserDefaults.standard
        if let savedWallpaper = defaults.string(forKey: "wallpaper.preset").flatMap(WallpaperPreset.init(rawValue:)) {
            wallpaperPreset = savedWallpaper
        }
        if let values = defaults.array(forKey: "wallpaper.customStart") as? [Double],
           let color = Color.fromStoredRGBA(values) {
            pastelTint = color
        }
        if let values = defaults.array(forKey: "wallpaper.customEnd") as? [Double],
           let color = Color.fromStoredRGBA(values) {
            gradientEndTint = color
        }
        if defaults.object(forKey: "wallpaper.gradientAngle") != nil {
            gradientAngle = defaults.double(forKey: "wallpaper.gradientAngle")
        }
        if let savedOrder = defaults.stringArray(forKey: "widgets.order") {
            let savedWidgets = savedOrder.compactMap(DashboardWidget.init(rawValue:))
            var uniqueWidgets: [DashboardWidget] = []
            for widget in savedWidgets where !uniqueWidgets.contains(widget) {
                uniqueWidgets.append(widget)
            }
            widgetOrder = uniqueWidgets + DashboardWidget.allCases.filter { !uniqueWidgets.contains($0) }
        }
        let savedSizes = defaults.dictionary(forKey: "widgets.sizes") as? [String: String] ?? [:]
        widgetSizes = Dictionary(uniqueKeysWithValues: savedSizes.compactMap { key, value in
            guard let widget = DashboardWidget(rawValue: key), let size = WidgetSizePreset(rawValue: value) else {
                return nil
            }
            return (widget, size)
        })
        if let savedClockStyle = defaults.string(forKey: "clock.displayStyle").flatMap(ClockDisplayStyle.init(rawValue:)) {
            clockDisplayStyle = savedClockStyle
        }
        if let savedIconSize = defaults.string(forKey: "taskbar.iconSize").flatMap(TaskbarIconSize.init(rawValue:)) {
            taskbarIconSize = savedIconSize
        }
        if let savedTrashPlacement = defaults.string(forKey: "taskbar.trashPlacement").flatMap(TrashPlacement.init(rawValue:)) {
            trashPlacement = savedTrashPlacement
        }
        if let savedMode = defaults.string(forKey: "taskbar.mode").flatMap(TaskbarMode.init(rawValue:)) {
            taskbarMode = savedMode
        }
        if let dividerData = defaults.data(forKey: "taskbar.dividers"),
           let savedDividers = try? JSONDecoder().decode([TaskbarDivider].self, from: dividerData) {
            userDividers = savedDividers
        }
        trashAnchors = defaults.dictionary(forKey: "taskbar.trashAnchors") as? [String: String] ?? [:]
        let savedCluster = defaults.stringArray(forKey: "taskbar.clusterOrder") ?? []
        if !savedCluster.isEmpty {
            clusterOrder = savedCluster
        }
        if defaults.object(forKey: "taskbar.islandGap") != nil {
            islandGap = CGFloat(defaults.double(forKey: "taskbar.islandGap"))
        }
        if defaults.object(forKey: "taskbar.centeredWidth") != nil {
            centeredBarWidth = CGFloat(defaults.double(forKey: "taskbar.centeredWidth"))
        }
        if let savedCorners = defaults.string(forKey: "corners.style").flatMap(CornerStyle.init(rawValue:)) {
            cornerStyle = savedCorners
        }
        if let savedScope = defaults.string(forKey: "corners.scope").flatMap(CornerScope.init(rawValue:)) {
            cornerScope = savedScope
        }
        if let savedTaskbar = defaults.string(forKey: "corners.taskbar").flatMap(CornerStyle.init(rawValue:)) {
            cornerTaskbar = savedTaskbar
        }
        if let savedWidgets = defaults.string(forKey: "corners.widgets").flatMap(CornerStyle.init(rawValue:)) {
            cornerWidgets = savedWidgets
        }
        if let savedFlyouts = defaults.string(forKey: "corners.flyouts").flatMap(CornerStyle.init(rawValue:)) {
            cornerFlyouts = savedFlyouts
        }
        showsTaskbarPanel = defaults.bool(forKey: "taskbar.panelShown")
        let savedWidths = defaults.dictionary(forKey: "panels.widths") as? [String: Double] ?? [:]
        panelWidths = Dictionary(uniqueKeysWithValues: savedWidths.compactMap { key, value in
            guard let kind = PanelKind(rawValue: key) else { return nil }
            return (kind, CGFloat(value))
        })
        var restoredPins: [String] = []
        for bundleID in defaults.stringArray(forKey: "launcher.pinnedApps") ?? LauncherDefaults.pinnedBundleIDs
        where LauncherDefaults.apps.contains(where: { $0.bundleIdentifier == bundleID })
            && !restoredPins.contains(bundleID)
            && restoredPins.count < 8 {
            restoredPins.append(bundleID)
        }
        pinnedAppBundleIDs = restoredPins
        showOnlyFourPinned = defaults.bool(forKey: "launcher.showOnlyFour")
        recentAppIDs = (defaults.stringArray(forKey: "launcher.recentApps") ?? []).filter { !$0.isEmpty }
        recentFolderTitles = (defaults.stringArray(forKey: "launcher.recentFolders") ?? []).filter { !$0.isEmpty }
        if let savedIndicatorStyle = defaults.string(forKey: "taskbar.indicatorStyle").flatMap(RunningIndicatorStyle.init(rawValue:)) {
            runningIndicatorStyle = savedIndicatorStyle
        }
        if let savedIndicatorSize = defaults.string(forKey: "taskbar.indicatorSize").flatMap(RunningIndicatorSize.init(rawValue:)) {
            runningIndicatorSize = savedIndicatorSize
        }
        if let values = defaults.array(forKey: "taskbar.indicatorColor") as? [Double],
           let color = Color.fromStoredRGBA(values) {
            runningIndicatorColor = color
        }
        if let savedMinimizeMode = defaults.string(forKey: "taskbar.minimizeMode").flatMap(AppMinimizeMode.init(rawValue:)) {
            minimizeMode = savedMinimizeMode
        }
        if let savedMenuStyle = defaults.string(forKey: "taskbar.menuStyle").flatMap(ContextMenuStyle.init(rawValue:)) {
            contextMenuStyle = savedMenuStyle
        }
        showWindowPreviews = defaults.bool(forKey: "taskbar.windowPreviews")
        hideMacDock = defaults.bool(forKey: "dock.hidden")
        showWifiName = defaults.bool(forKey: "status.showWifiName")
        showBluetoothDevices = defaults.bool(forKey: "status.showBluetoothDevices")
        systemStatusService.bluetoothDeviceMonitoringEnabled = showBluetoothDevices
        ddcBrightnessEnabled = defaults.bool(forKey: "display.ddcEnabled")
        hiddenQuickSettingTitles = Set(
            (defaults.string(forKey: "quickSettings.hiddenTiles") ?? "")
                .split(separator: "|")
                .map(String.init)
        )
        systemStatusService.startMonitoring(interval: 10.0) { [weak self] snapshot in
            self?.systemStatus = snapshot
        }
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleTopProcessesIfNeeded()
            }
        }
    }

    fileprivate func sampleTopProcessesIfNeeded() {
        guard openPanel == .start || openPanel == .widgets else { return }
        processSampleQueue.async { [weak self] in
            let sampled = Self.sampleTopProcesses()
            DispatchQueue.main.async {
                self?.topProcesses = sampled.processes
                self?.totalProcessCount = sampled.total
            }
        }
    }

    nonisolated private static func sampleTopProcesses() -> (processes: [TopProcess], total: Int) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "comm,pcpu,rss"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard let output = String(data: data, encoding: .utf8) else { return (processes: [], total: 0) }
            var rows: [TopProcess] = []
            var totalCount = 0
            for line in output.components(separatedBy: "\n").dropFirst() {
                let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                guard parts.count >= 3,
                      let cpu = Double(parts[parts.count - 2]),
                      let rssKB = Double(parts[parts.count - 1])
                else {
                    continue
                }
                totalCount += 1
                let name = parts.dropLast(2).joined(separator: " ")
                guard !name.isEmpty else { continue }
                rows.append(TopProcess(name: name, cpuPercent: cpu, memoryMB: rssKB / 1024))
            }
            return (Array(rows.sorted { $0.cpuPercent > $1.cpuPercent }.prefix(5)), totalCount)
        } catch {
            return (processes: [], total: 0)
        }
    }

    private var pendingPersistenceWorkItems: [String: DispatchWorkItem] = [:]

    fileprivate func persist(key: String, value: Any) {
        pendingPersistenceWorkItems[key]?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            UserDefaults.standard.set(value, forKey: key)
            self?.pendingPersistenceWorkItems[key] = nil
        }
        pendingPersistenceWorkItems[key] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    fileprivate func widgetSize(for widget: DashboardWidget) -> WidgetSizePreset {
        widgetSizes[widget] ?? widget.defaultSize
    }

    func panelWidth(for kind: PanelKind) -> CGFloat {
        panelWidths[kind] ?? kind.defaultWidth
    }

    fileprivate func setPanelWidth(_ width: CGFloat, for kind: PanelKind) {
        panelWidths[kind] = min(kind.maximumWidth, max(kind.minimumWidth, width))
    }

    fileprivate func setWidgetSize(_ size: WidgetSizePreset, for widget: DashboardWidget) {
        widgetSizes[widget] = size
    }

    fileprivate func moveWidget(_ widget: DashboardWidget, before target: DashboardWidget) {
        guard widget != target, let sourceIndex = widgetOrder.firstIndex(of: widget) else { return }
        var updatedOrder = widgetOrder
        updatedOrder.remove(at: sourceIndex)
        let targetIndex = updatedOrder.firstIndex(of: target) ?? updatedOrder.endIndex
        updatedOrder.insert(widget, at: targetIndex)
        widgetOrder = updatedOrder
    }

    fileprivate func setPinned(_ bundleID: String, isPinned: Bool) {
        if isPinned {
            guard LauncherDefaults.apps.contains(where: { $0.bundleIdentifier == bundleID }),
                  !pinnedAppBundleIDs.contains(bundleID),
                  pinnedAppBundleIDs.count < 8
            else {
                return
            }
            pinnedAppBundleIDs.append(bundleID)
        } else {
            pinnedAppBundleIDs.removeAll { $0 == bundleID }
        }
    }

    fileprivate func movePinned(_ bundleID: String, before targetBundleID: String) {
        guard bundleID != targetBundleID,
              let sourceIndex = pinnedAppBundleIDs.firstIndex(of: bundleID) else { return }
        var updated = pinnedAppBundleIDs
        updated.remove(at: sourceIndex)
        let targetIndex = updated.firstIndex(of: targetBundleID) ?? updated.endIndex
        updated.insert(bundleID, at: targetIndex)
        pinnedAppBundleIDs = updated
    }

    func togglePinned(_ bundleID: String) {
        setPinned(bundleID, isPinned: !pinnedAppBundleIDs.contains(bundleID))
    }

    func addDivider(after bundleID: String?) {
        userDividers.append(TaskbarDivider(anchorBundleID: bundleID))
    }

    func moveDivider(_ id: UUID, after bundleID: String) {
        guard let index = userDividers.firstIndex(where: { $0.id == id }) else { return }
        userDividers[index].anchorBundleID = bundleID
    }

    func removeDivider(_ id: UUID) {
        userDividers.removeAll { $0.id == id }
    }

    func recordLaunch(_ bundleID: String) {
        var updated = recentAppIDs.filter { $0 != bundleID }
        updated.insert(bundleID, at: 0)
        recentAppIDs = Array(updated.prefix(8))
    }

    fileprivate func recordFolderOpen(_ title: String) {
        var updated = recentFolderTitles.filter { $0 != title }
        updated.insert(title, at: 0)
        recentFolderTitles = Array(updated.prefix(4))
    }

    fileprivate func setOutputVolume(_ level: Double) {
        SystemStatusService.setOutputVolume(level)
        var snapshot = systemStatus
        snapshot.volumeLevel = min(1, max(0, level))
        systemStatus = snapshot
    }

    fileprivate func setBluetoothDeviceConnected(_ connected: Bool, address: String) {
        systemStatusService.setBluetoothDeviceConnected(connected, address: address)
    }

    fileprivate func resetPersonalisation() {
        surfaceStyle = .glass
        usesDockPresentation = false
        isDarkMode = false
        wallpaperPreset = .pastelBloom
        pastelTint = Color(red: 0.91, green: 0.69, blue: 0.87)
        gradientEndTint = Color(red: 0.47, green: 0.70, blue: 0.86)
        gradientAngle = 35.0
        interfaceTransparency = 0.68
        usesTaskbarGradient = false
        taskbarGradientStart = Color(red: 0.78, green: 0.48, blue: 0.86)
        taskbarGradientEnd = Color(red: 0.96, green: 0.38, blue: 0.42)
        taskbarHeight = 46
        taskbarIconSize = .medium
        trashPlacement = .withApps
        panelWidths = [:]
    }
}

struct TaskbarFlyoutContentView: View {
    let panel: OpenPanel
    @ObservedObject var model: TaskbarConceptState
    let onLaunchApplication: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        flyoutContent
            .environment(\.surfaceStyle, model.surfaceStyle)
            .environment(\.surfaceTransparency, model.interfaceTransparency)
    }

    @ViewBuilder
    private var flyoutContent: some View {
        switch panel {
        case .widgets:
            WidgetsPanel(onClose: onClose, accent: model.clockTint, model: model)
        case .calendar:
            ClockFlyout(
                displayedMonth: $model.displayedMonth,
                selectedDate: $model.selectedDate,
                showsClockSettings: $model.showsClockSettings,
                uses24HourTime: $model.uses24HourTime,
                showsSeconds: $model.showsSeconds,
                dateStyle: $model.dateStyle,
                clockDisplayStyle: $model.clockDisplayStyle,
                clockTint: $model.clockTint,
                accent: model.clockTint,
                cornerRadius: model.shellRadius(for: .flyouts)
            )
        case .controls:
            ControlsFlyout(accent: model.clockTint, model: model)
        case .start:
            StartFlyout(
                onClose: onClose,
                accent: model.clockTint,
                model: model,
                onLaunchApplication: onLaunchApplication
            )
        case .settings:
            SettingsFlyout(
                surfaceStyle: $model.surfaceStyle,
                usesDockPresentation: $model.usesDockPresentation,
                isDarkMode: $model.isDarkMode,
                wallpaperPreset: $model.wallpaperPreset,
                pastelTint: $model.pastelTint,
                gradientEndTint: $model.gradientEndTint,
                gradientAngle: $model.gradientAngle,
                interfaceTransparency: $model.interfaceTransparency,
                usesTaskbarGradient: $model.usesTaskbarGradient,
                taskbarGradientStart: $model.taskbarGradientStart,
                taskbarGradientEnd: $model.taskbarGradientEnd,
                taskbarHeight: $model.taskbarHeight,
                showsTaskbarPanel: $model.showsTaskbarPanel,
                hideMacDock: $model.hideMacDock,
                showWindowPreviews: $model.showWindowPreviews,
                runningIndicatorStyle: $model.runningIndicatorStyle,
                runningIndicatorSize: $model.runningIndicatorSize,
                runningIndicatorColor: $model.runningIndicatorColor,
                minimizeMode: $model.minimizeMode,
                contextMenuStyle: $model.contextMenuStyle,
                showWifiName: $model.showWifiName,
                showBluetoothDevices: $model.showBluetoothDevices,
                ddcBrightnessEnabled: $model.ddcBrightnessEnabled,
                cornerStyle: $model.cornerStyle,
                cornerScope: $model.cornerScope,
                cornerTaskbar: $model.cornerTaskbar,
                cornerWidgets: $model.cornerWidgets,
                cornerFlyouts: $model.cornerFlyouts,
                taskbarIconSize: $model.taskbarIconSize,
                trashPlacement: $model.trashPlacement,
                panelWidths: $model.panelWidths,
                accent: model.clockTint,
                onClose: onClose,
                onResetPersonalisation: { model.resetPersonalisation() },
                cornerRadius: model.shellRadius(for: .flyouts)
            )
        }
    }
}

struct WindowPreviewContent: View {
    let bundleID: String
    let appTitle: String
    let windows: [AppWindowInfo]
    let surfaceStyle: SurfaceStyle
    let onSelectWindow: (AppWindowInfo) -> Void
    let onClose: () -> Void
    let cornerRadius: CGFloat
    @State private var thumbnails: [CGWindowID: NSImage] = [:]
    @State private var didAttemptCapture = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(appTitle)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(windows.count) \(windows.count == 1 ? "window" : "windows")")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            ForEach(windows.prefix(6)) { window in
                previewRow(window)
            }
            if didAttemptCapture, thumbnails.isEmpty {
                Text("Grant Screen Recording for live thumbnails.")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.76), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
        .task {
            await captureThumbnails()
        }
    }

    private func previewRow(_ window: AppWindowInfo) -> some View {
        Button {
            onSelectWindow(window)
        } label: {
            HStack(spacing: 10) {
                if let image = thumbnails[window.id] {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    MacOSAppIcon(
                        bundleIdentifier: bundleID,
                        fallbackSymbol: "app.fill",
                        fallbackColor: .secondary,
                        size: 34
                    )
                    .frame(width: 120, height: 72)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                }
                Text(window.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(8)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.05), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func captureThumbnails() async {
        let service = AppWindowPreviewService()
        for window in windows.prefix(6) {
            if let image = await service.captureThumbnail(forWindowID: window.id) {
                thumbnails[window.id] = image
            }
        }
        didAttemptCapture = true
    }
}

struct TaskbarPanelContentView: View {
    @ObservedObject var model: TaskbarConceptState
    let onLaunchApplication: (String) -> Void
    let onTaskbarIconClick: (String) -> Void
    let onTaskbarTileAction: (TaskbarTileAction) -> Void

    var body: some View {
        Taskbar(
            model: model,
            height: $model.taskbarHeight,
            onLaunchApplication: onLaunchApplication,
            onTaskbarIconClick: onTaskbarIconClick,
            onTaskbarTileAction: onTaskbarTileAction,
            rendersSplitRow: false
        )
        .environment(\.surfaceTransparency, model.interfaceTransparency)
        .preferredColorScheme(model.isDarkMode ? .dark : .light)
    }
}

public struct TaskbarConceptView: View {
    @ObservedObject private var model: TaskbarConceptState
    private let onLaunchApplication: (String) -> Void
    private let onTaskbarIconClick: (String) -> Void
    private let onTaskbarTileAction: (TaskbarTileAction) -> Void

    init(model: TaskbarConceptState, onLaunchApplication: @escaping (String) -> Void, onTaskbarIconClick: @escaping (String) -> Void, onTaskbarTileAction: @escaping (TaskbarTileAction) -> Void) {
        self._model = ObservedObject(wrappedValue: model)
        self.onLaunchApplication = onLaunchApplication
        self.onTaskbarIconClick = onTaskbarIconClick
        self.onTaskbarTileAction = onTaskbarTileAction
    }

    private var openPanel: OpenPanel? {
        get { model.openPanel }
        nonmutating set { model.openPanel = newValue }
    }
    private var surfaceStyle: SurfaceStyle { model.surfaceStyle }
    private var showsTaskbarPanel: Bool { model.showsTaskbarPanel }
    private var usesDockPresentation: Bool { model.usesDockPresentation }
    private var isDarkMode: Bool { model.isDarkMode }
    private var wallpaperPreset: WallpaperPreset { model.wallpaperPreset }
    private var pastelTint: Color { model.pastelTint }
    private var gradientEndTint: Color { model.gradientEndTint }
    private var gradientAngle: Double { model.gradientAngle }
    private var interfaceTransparency: Double { model.interfaceTransparency }
    private var usesTaskbarGradient: Bool { model.usesTaskbarGradient }
    private var taskbarGradientStart: Color { model.taskbarGradientStart }
    private var taskbarGradientEnd: Color { model.taskbarGradientEnd }
    private var taskbarHeight: CGFloat { model.taskbarHeight }
    private var showsClockSettings: Bool { model.showsClockSettings }
    private var uses24HourTime: Bool { model.uses24HourTime }
    private var showsSeconds: Bool { model.showsSeconds }
    private var dateStyle: ClockDateStyle { model.dateStyle }
    private var clockTint: Color { model.clockTint }
    private var displayedMonth: Date { model.displayedMonth }
    private var selectedDate: Date { model.selectedDate }

    private func panelFrameWidth(_ kind: PanelKind, available: CGFloat) -> CGFloat {
        min(model.panelWidth(for: kind), available)
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                DesktopBackdrop(
                    isDarkMode: isDarkMode,
                    preset: wallpaperPreset,
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

                if openPanel == .widgets, !showsTaskbarPanel {
                    WidgetsPanel(onClose: { openPanel = nil }, accent: clockTint, model: model)
                        .frame(
                            width: panelFrameWidth(.widgets, available: geometry.size.width - 36),
                            height: max(300, geometry.size.height - taskbarHeight - 28)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.leading, 14)
                        .padding(.top, 14)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                if openPanel == .calendar, !showsTaskbarPanel {
                    ClockFlyout(
                        displayedMonth: $model.displayedMonth,
                        selectedDate: $model.selectedDate,
                        showsClockSettings: $model.showsClockSettings,
                        uses24HourTime: $model.uses24HourTime,
                        showsSeconds: $model.showsSeconds,
                        dateStyle: $model.dateStyle,
                        clockDisplayStyle: $model.clockDisplayStyle,
                        clockTint: $model.clockTint,
                        accent: clockTint,
                        cornerRadius: model.shellRadius(for: .flyouts)
                    )
                    .frame(width: min(520, geometry.size.width - 36), height: max(300, geometry.size.height - taskbarHeight - 28))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 14)
                    .padding(.top, 14)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .environment(\.surfaceStyle, surfaceStyle)
                    .zIndex(2)
                }

                if openPanel == .controls, !showsTaskbarPanel {
                    ControlsFlyout(accent: clockTint, model: model)
                        .frame(width: panelFrameWidth(.controls, available: geometry.size.width - 36), height: max(300, geometry.size.height - taskbarHeight - 28))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.trailing, 14)
                        .padding(.top, 14)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                if openPanel == .start, !showsTaskbarPanel {
                    StartFlyout(
                        onClose: { openPanel = nil },
                        accent: clockTint,
                        model: model,
                        onLaunchApplication: onLaunchApplication
                    )
                        .frame(width: panelFrameWidth(.start, available: geometry.size.width - 48), height: min(700, geometry.size.height - taskbarHeight - 36))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, taskbarHeight + 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                if openPanel == .settings, !showsTaskbarPanel {
                    SettingsFlyout(
                        surfaceStyle: $model.surfaceStyle,
                        usesDockPresentation: $model.usesDockPresentation,
                        isDarkMode: $model.isDarkMode,
                        wallpaperPreset: $model.wallpaperPreset,
                        pastelTint: $model.pastelTint,
                        gradientEndTint: $model.gradientEndTint,
                        gradientAngle: $model.gradientAngle,
                        interfaceTransparency: $model.interfaceTransparency,
                        usesTaskbarGradient: $model.usesTaskbarGradient,
                        taskbarGradientStart: $model.taskbarGradientStart,
                        taskbarGradientEnd: $model.taskbarGradientEnd,
                        taskbarHeight: $model.taskbarHeight,
                        showsTaskbarPanel: $model.showsTaskbarPanel,
                        hideMacDock: $model.hideMacDock,
                        showWindowPreviews: $model.showWindowPreviews,
                        runningIndicatorStyle: $model.runningIndicatorStyle,
                        runningIndicatorSize: $model.runningIndicatorSize,
                        runningIndicatorColor: $model.runningIndicatorColor,
                        minimizeMode: $model.minimizeMode,
                        contextMenuStyle: $model.contextMenuStyle,
                        showWifiName: $model.showWifiName,
                        showBluetoothDevices: $model.showBluetoothDevices,
                        ddcBrightnessEnabled: $model.ddcBrightnessEnabled,
                        cornerStyle: $model.cornerStyle,
                        cornerScope: $model.cornerScope,
                        cornerTaskbar: $model.cornerTaskbar,
                        cornerWidgets: $model.cornerWidgets,
                        cornerFlyouts: $model.cornerFlyouts,
                        taskbarIconSize: $model.taskbarIconSize,
                        trashPlacement: $model.trashPlacement,
                        panelWidths: $model.panelWidths,
                        accent: clockTint,
                        onClose: { openPanel = nil },
                        onResetPersonalisation: { model.resetPersonalisation() },
                        cornerRadius: model.shellRadius(for: .flyouts)
                    )
                    .frame(width: panelFrameWidth(.settings, available: geometry.size.width - 40), height: min(680, geometry.size.height - taskbarHeight - 34))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.bottom, taskbarHeight)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                    .environment(\.surfaceStyle, surfaceStyle)
                        .zIndex(2)
                }

                Taskbar(
                    model: model,
                    height: $model.taskbarHeight,
                    onLaunchApplication: onLaunchApplication,
                    onTaskbarIconClick: onTaskbarIconClick,
                    onTaskbarTileAction: onTaskbarTileAction
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
    let preset: WallpaperPreset
    let pastelTint: Color
    let gradientEndTint: Color
    let gradientAngle: Double

    private var gradientStart: UnitPoint {
        UnitPoint(x: 0.5 - cos(gradientAngle * .pi / 180) / 2, y: 0.5 - sin(gradientAngle * .pi / 180) / 2)
    }

    private var gradientEnd: UnitPoint {
        UnitPoint(x: 0.5 + cos(gradientAngle * .pi / 180) / 2, y: 0.5 + sin(gradientAngle * .pi / 180) / 2)
    }

    private var wallpaperColors: [Color] {
        if preset == .custom {
            return [pastelTint, gradientEndTint]
        }
        if isDarkMode && !preset.isDark {
            return [
                Color(red: 0.035, green: 0.055, blue: 0.10),
                Color(red: 0.10, green: 0.075, blue: 0.14),
                Color(red: 0.045, green: 0.10, blue: 0.16)
            ]
        }
        return preset.colors
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: wallpaperColors,
                startPoint: gradientStart,
                endPoint: gradientEnd
            )

            Circle()
                .fill((preset == .custom ? pastelTint : wallpaperColors.first ?? pastelTint).opacity(0.47))
                .frame(width: 520, height: 520)
                .blur(radius: 85)
                .offset(x: 380, y: -170)

            Circle()
                .fill((preset == .custom ? gradientEndTint : wallpaperColors.last ?? gradientEndTint).opacity(0.31))
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

private func taskbarDisplayName(for bundleIdentifier: String) -> String {
    if let known = LauncherDefaults.apps.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
        return known.title
    }
    if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }),
       let name = running.localizedName, !name.isEmpty {
        return name
    }
    return bundleIdentifier
}

private struct TaskbarWeatherSection: View {
    @ObservedObject var model: TaskbarConceptState

    private var glyphSize: CGFloat { model.taskbarHeight * model.taskbarIconSize.glyphFraction }

    var body: some View {
        Button {
            model.openPanel = model.openPanel == .widgets ? nil : .widgets
        } label: {
            HStack(spacing: 10) {
                Image(systemName: model.weather.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: glyphSize))
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.weather.formattedTemperature)
                        .font(.system(size: 13, weight: .semibold))
                    Text(model.weather.conditionText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 170, height: model.taskbarHeight - 4, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Open widgets")
    }
}

private struct TaskbarClockSection: View {
    @ObservedObject var model: TaskbarConceptState

    var body: some View {
        clockSchedule { date in
            Button {
                model.openPanel = model.openPanel == .calendar ? nil : .calendar
            } label: {
                TaskbarClockDisplay(
                    date: date,
                    style: model.clockDisplayStyle,
                    dateStyle: model.dateStyle,
                    uses24HourTime: model.uses24HourTime,
                    showsSeconds: model.showsSeconds,
                    tint: model.clockTint,
                    height: model.taskbarHeight
                )
                .frame(minWidth: 88, minHeight: model.taskbarHeight - 8, alignment: .trailing)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Open calendar")
        }
    }

    private func clockSchedule<Content: View>(@ViewBuilder content: @escaping (Date) -> Content) -> some View {
        if model.showsSeconds {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content(context.date)
            }
        } else {
            TimelineView(.periodic(from: .now.nextMinuteBoundary, by: 60)) { context in
                content(context.date)
            }
        }
    }
}

struct TaskbarIslandContent: View {
    let sections: [TaskbarSection]
    @ObservedObject var model: TaskbarConceptState
    let onLaunchApplication: (String) -> Void
    let onTaskbarIconClick: (String) -> Void
    let onTaskbarTileAction: (TaskbarTileAction) -> Void
    var maxAppTiles: Int? = nil
    var showOverflowChevron: Bool = false

    private var tiles: TaskbarTiles {
        TaskbarTiles(
            pinnedBundleIDs: model.pinnedAppBundleIDs,
            runningBundleIDs: model.runningBundleIDs,
            frontmostBundleID: model.frontmostBundleID,
            indicatorStyle: model.runningIndicatorStyle,
            indicatorSize: model.runningIndicatorSize,
            indicatorColor: model.runningIndicatorColor,
            menuStyle: model.contextMenuStyle,
            isDarkMode: model.isDarkMode,
            systemStatus: model.systemStatus,
            tileSide: max(28, model.taskbarHeight - 4),
            glyphSize: model.taskbarHeight * model.taskbarIconSize.glyphFraction,
            previewsEnabled: model.showWindowPreviews,
            previewBundleID: $model.previewBundleID,
            clusterOrder: model.clusterOrder,
            onTaskbarIconClick: onTaskbarIconClick,
            onTaskbarTileAction: onTaskbarTileAction,
            onToggleControls: { model.openPanel = model.openPanel == .controls ? nil : .controls },
            onHoverChanged: model.handleTaskbarTileHover
        )
    }

    private var stripItems: [StripItem] {
        let running = model.runningAppOrder.filter({ !model.pinnedAppBundleIDs.contains($0) })
        let dividers = model.taskbarMode == .macOS ? [] : model.userDividers
        return TaskbarStrip.compose(
            pins: model.pinnedAppBundleIDs,
            runningOrder: running,
            dividers: dividers
        )
    }

    private var visibleItems: [StripItem] {
        guard let maxAppTiles else { return stripItems }
        var appsSeen = 0
        var result: [StripItem] = []
        for item in stripItems {
            if case .app = item {
                appsSeen += 1
                if appsSeen > maxAppTiles {
                    continue
                }
            }
            result.append(item)
        }
        return TaskbarStrip.pruned(result)
    }

    private var isClipped: Bool {
        guard maxAppTiles != nil else { return false }
        return visibleItems.count < stripItems.count
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(sections, id: \.self) { section in
                switch section {
                case .weather:
                    TaskbarWeatherSection(model: model)
                case .apps:
                    appsGroup
                case .tray:
                    trayGroup(includeClock: false)
                case .clock:
                    clockGroup
                }
            }
        }
    }

    private var appsGroup: some View {
        HStack(spacing: 4) {
            Button {
                model.openPanel = model.openPanel == .start ? nil : .start
            } label: {
                MacOSAppIcon(
                    bundleIdentifier: "com.apple.launchpad",
                    fallbackSymbol: "square.grid.3x3.fill",
                    fallbackColor: model.isDarkMode ? Color(red: 0.54, green: 0.76, blue: 1) : .blue,
                    size: model.taskbarHeight * model.taskbarIconSize.glyphFraction
                )
                .frame(width: max(28, model.taskbarHeight - 4), height: max(28, model.taskbarHeight - 4))
                .taskbarTile()
            }
            .buttonStyle(.plain)
            .help("Open Start")
            ForEach(visibleItems, id: \.self) { item in
                switch item {
                case .app(let bundleID):
                    tiles.taskbarAppTile(bundleID)
                case .divider(let id):
                    TaskbarDividerView()
                        .padding(.vertical, 6)
                        .contextMenu {
                            Button("Remove divider", role: .destructive) {
                                model.removeDivider(id)
                            }
                        }
                }
            }
            if model.trashPlacement(for: model.taskbarMode) == .withApps {
                tiles.trashCluster
            }
            if showOverflowChevron, isClipped {
                Button {
                    model.openPanel = .start
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: max(28, model.taskbarHeight - 4))
                }
                .buttonStyle(.plain)
                .help("More apps in the launcher")
            }
        }
    }

    @ViewBuilder
    private func trayGroup(includeClock: Bool) -> some View {
        if model.trashPlacement(for: model.taskbarMode) == .beforeTray {
            tiles.trashCluster
        }
        if includeClock {
            clockGroup
        }
    }

    private var clockGroup: some View {
        HStack(spacing: 4) {
            if model.trashPlacement(for: model.taskbarMode) == .beforeClock {
                tiles.trashCluster
            }
            TaskbarClockSection(model: model)
            if model.trashPlacement(for: model.taskbarMode) == .farRight {
                tiles.trashCluster
            }
        }
    }
}

private struct TaskbarTiles {
    let pinnedBundleIDs: [String]
    let runningBundleIDs: Set<String>
    let frontmostBundleID: String?
    let indicatorStyle: RunningIndicatorStyle
    let indicatorSize: RunningIndicatorSize
    let indicatorColor: Color
    let menuStyle: ContextMenuStyle
    let isDarkMode: Bool
    let systemStatus: SystemStatusSnapshot
    let tileSide: CGFloat
    let glyphSize: CGFloat
    let previewsEnabled: Bool
    var previewBundleID: Binding<String?>
    let clusterOrder: [String]
    let onTaskbarIconClick: (String) -> Void
    let onTaskbarTileAction: (TaskbarTileAction) -> Void
    let onToggleControls: () -> Void
    let onHoverChanged: (String, Bool) -> Void

    func taskbarAppTile(_ bundleIdentifier: String) -> some View {
        let app = LauncherDefaults.apps.first { $0.bundleIdentifier == bundleIdentifier }
        let title = taskbarDisplayName(for: bundleIdentifier)
        let isRunning = runningBundleIDs.contains(bundleIdentifier)
        let isFrontmost = frontmostBundleID == bundleIdentifier
        return Button {
            onTaskbarIconClick(bundleIdentifier)
        } label: {
            MacOSAppIcon(
                bundleIdentifier: bundleIdentifier,
                fallbackSymbol: app?.symbol ?? "app.fill",
                fallbackColor: app?.color ?? .secondary,
                size: glyphSize
            )
            .frame(width: tileSide, height: tileSide)
            .taskbarTile(highlighted: isRunning && indicatorStyle == .highlight, highlightColor: indicatorColor)
            .overlay(alignment: .bottom) {
                if isRunning, indicatorStyle != .highlight {
                    runningIndicator(isFrontmost: isFrontmost)
                        .padding(.bottom, 4)
                }
            }
        }
        .buttonStyle(.plain)
        .help(title)
        .contextMenu {
            tileContextMenu(bundleIdentifier)
        }
        .onHover { hovering in
            onHoverChanged(bundleIdentifier, hovering)
        }
    }

    private func runningIndicator(isFrontmost: Bool) -> some View {
        Group {
            switch indicatorStyle {
            case .dot:
                Circle()
                    .fill(indicatorColor.opacity(isFrontmost ? 1 : 0.55))
                    .frame(width: indicatorSize.dotDiameter, height: indicatorSize.dotDiameter)
            case .dash:
                Capsule()
                    .fill(indicatorColor.opacity(isFrontmost ? 1 : 0.55))
                    .frame(width: indicatorSize.dashWidth, height: indicatorSize.dashHeight)
            case .highlight:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func tileContextMenu(_ bundleIdentifier: String) -> some View {
        switch menuStyle {
        case .native:
            nativeTileMenu(bundleIdentifier)
        case .windows:
            windowsTileMenu(bundleIdentifier)
        }
    }

    @ViewBuilder
    private func nativeTileMenu(_ bundleIdentifier: String) -> some View {
        let isRunning = runningBundleIDs.contains(bundleIdentifier)
        Button(isRunning ? "Activate" : "Open") {
            onTaskbarIconClick(bundleIdentifier)
        }
        Button("Show in Finder") {
            onTaskbarTileAction(.revealInFinder(bundleID: bundleIdentifier))
        }
        if isRunning {
            Divider()
            Button("Hide") {
                onTaskbarTileAction(.hideApp(bundleID: bundleIdentifier))
            }
            Button("Quit") {
                onTaskbarTileAction(.quitApp(bundleID: bundleIdentifier))
            }
        }
    }

    @ViewBuilder
    private func windowsTileMenu(_ bundleIdentifier: String) -> some View {
        let isRunning = runningBundleIDs.contains(bundleIdentifier)
        let isPinned = pinnedBundleIDs.contains(bundleIdentifier)
        Button("Open") {
            onTaskbarIconClick(bundleIdentifier)
        }
        Button("Open new window") {
            onTaskbarTileAction(.newWindow(bundleID: bundleIdentifier))
        }
        Button("Open file location") {
            onTaskbarTileAction(.revealInFinder(bundleID: bundleIdentifier))
        }
        let windows = AppWindowPreviewService().windows(
            forBundleIdentifier: bundleIdentifier,
            appName: taskbarDisplayName(for: bundleIdentifier)
        )
        if !windows.isEmpty {
            Divider()
            ForEach(windows.prefix(5)) { window in
                Button(window.title) {
                    AppWindowPreviewService().focusWindow(info: window, bundleIdentifier: bundleIdentifier)
                }
            }
        }
        let recents = recentDocuments(for: bundleIdentifier)
        if !recents.isEmpty {
            Divider()
            Menu("Recent") {
                ForEach(recents, id: \.self) { url in
                    Button(url.deletingPathExtension().lastPathComponent) {
                        onTaskbarTileAction(.openRecent(url))
                    }
                }
            }
        }
        Divider()
        Button(isPinned ? "Unpin from taskbar" : "Pin to taskbar") {
            onTaskbarTileAction(.togglePin(bundleID: bundleIdentifier))
        }
        .disabled(!isPinned && pinnedBundleIDs.count >= 8)
        if isRunning {
            Button("Quit") {
                onTaskbarTileAction(.quitApp(bundleID: bundleIdentifier))
            }
        }
    }

    private func recentDocuments(for bundleIdentifier: String) -> [URL] {
        let recents = NSDocumentController.shared.recentDocumentURLs
        var matches: [URL] = []
        for url in recents.prefix(20) {
            guard let appURL = NSWorkspace.shared.urlForApplication(toOpen: url),
                  Bundle(url: appURL)?.bundleIdentifier == bundleIdentifier
            else {
                continue
            }
            matches.append(url)
            if matches.count >= 5 {
                break
            }
        }
        return matches
    }

    var trashCluster: some View {
        HStack(spacing: 4) {
            ForEach(clusterOrder, id: \.self) { key in
                clusterTile(key)
            }
        }
    }

    @ViewBuilder
    private func clusterTile(_ key: String) -> some View {
        switch key {
        case "downloads":
            DownloadsTile(tileSide: tileSide, glyphSize: glyphSize)
        case "trash":
            TrashTile(tileSide: tileSide, glyphSize: glyphSize, darkMode: isDarkMode)
        default:
            Button {
                onToggleControls()
            } label: {
                SystemStatusIcon(snapshot: systemStatus, glyphSize: glyphSize)
                    .frame(width: tileSide, height: tileSide)
                    .taskbarTile()
            }
            .buttonStyle(.plain)
            .help("Open quick controls, volume, Bluetooth and battery")
        }
    }

}

private struct Taskbar: View {
    @ObservedObject var model: TaskbarConceptState
    @Binding var height: CGFloat
    @State private var dragStartHeight: CGFloat?
    let onLaunchApplication: (String) -> Void
    let onTaskbarIconClick: (String) -> Void
    let onTaskbarTileAction: (TaskbarTileAction) -> Void
    var rendersSplitRow: Bool = true

    private var mode: TaskbarMode { model.taskbarMode }
    private var glyphSize: CGFloat { height * model.taskbarIconSize.glyphFraction }
    private var tileSide: CGFloat { max(28, height - 4) }
    private var isFloating: Bool { mode == .macOS }
    private var isConstrained: Bool { isFloating || mode == .centered }
    private var showsDividers: Bool { !isFloating }

    private var tiles: TaskbarTiles {
        TaskbarTiles(
            pinnedBundleIDs: model.pinnedAppBundleIDs,
            runningBundleIDs: model.runningBundleIDs,
            frontmostBundleID: model.frontmostBundleID,
            indicatorStyle: model.runningIndicatorStyle,
            indicatorSize: model.runningIndicatorSize,
            indicatorColor: model.runningIndicatorColor,
            menuStyle: model.contextMenuStyle,
            isDarkMode: model.isDarkMode,
            systemStatus: model.systemStatus,
            tileSide: tileSide,
            glyphSize: glyphSize,
            previewsEnabled: model.showWindowPreviews,
            previewBundleID: $model.previewBundleID,
            clusterOrder: model.clusterOrder,
            onTaskbarIconClick: onTaskbarIconClick,
            onTaskbarTileAction: onTaskbarTileAction,
            onToggleControls: { toggle(.controls) },
            onHoverChanged: model.handleTaskbarTileHover
        )
    }

    var body: some View {
        Group {
            if mode.isSplit, rendersSplitRow {
                TaskbarSplitRow(
                    model: model,
                    onLaunchApplication: onLaunchApplication,
                    onTaskbarIconClick: onTaskbarIconClick,
                    onTaskbarTileAction: onTaskbarTileAction
                )
            } else if mode.isSplit {
                Color.clear
            } else {
                barShell
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .environment(\.surfaceTransparency, model.interfaceTransparency)
        .overlay(alignment: .top) {
            resizeHandle
        }
        .overlay(alignment: .top) {
            if !isFloating, model.surfaceStyle == .classic98 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(height: 1)
                    .offset(y: -1)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                model.openPanel = .settings
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

    private var barShell: some View {
        GeometryReader { geometry in
            ZStack {
                barBackground
                HStack(spacing: 0) {
                    TaskbarWeatherSection(model: model)
                        .padding(.leading, 18)
                    if showsDividers, !model.userDividers.isEmpty {
                        TaskbarDividerView()
                            .padding(.vertical, 6)
                            .padding(.leading, 10)
                    }
                    Spacer(minLength: 0)
                    trailingTrayCluster
                        .layoutPriority(1)
                }
                .padding(.horizontal, isFloating ? 18 : 8)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .frame(width: isConstrained ? min(geometry.size.width, model.centeredBarWidth) : nil)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .center) {
                TaskbarIslandContent(
                    sections: [.apps],
                    model: model,
                    onLaunchApplication: onLaunchApplication,
                    onTaskbarIconClick: onTaskbarIconClick,
                    onTaskbarTileAction: onTaskbarTileAction
                )
            }
        }
    }

    @ViewBuilder
    private var barBackground: some View {
        let radius = model.shellRadius(for: .taskbar)
        if isFloating {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
                }
                .padding(.vertical, 3)
        } else if model.usesTaskbarGradient {
            Rectangle()
                .fill(LinearGradient(colors: [model.taskbarGradientStart, model.taskbarGradientEnd], startPoint: .leading, endPoint: .trailing))
        } else if model.surfaceStyle == .aero {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    LinearGradient(
                        colors: [
                            Color(red: 0.44, green: 0.74, blue: 0.96).opacity(model.isDarkMode ? 0.22 : 0.45),
                            Color.white.opacity(model.isDarkMode ? 0.03 : 0.16),
                            Color(red: 0.18, green: 0.43, blue: 0.71).opacity(model.isDarkMode ? 0.18 : 0.30)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        } else {
            Rectangle()
                .fill(
                    model.surfaceStyle == .windowsXP
                        ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.15, green: 0.44, blue: 0.88), Color(red: 0.04, green: 0.22, blue: 0.61)], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(model.surfaceStyle.taskbarFill(darkMode: model.isDarkMode))
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.42))
                        .frame(height: 1)
                }
        }
    }

    private var trailingTrayCluster: some View {
        HStack(spacing: model.trashPlacement(for: mode) == .beforeClock ? 4 : 8) {
            if model.trashPlacement(for: mode) == .beforeTray {
                tiles.trashCluster
            }
            if model.trashPlacement(for: mode) == .beforeClock {
                tiles.trashCluster
            }
            TaskbarClockSection(model: model)
            if model.trashPlacement(for: mode) == .farRight {
                tiles.trashCluster
            }
        }
        .padding(.trailing, 12)
    }

    private var resizeHandle: some View {
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

    private func toggle(_ panel: OpenPanel) {
        model.openPanel = model.openPanel == panel ? nil : panel
    }
}

private struct TaskbarSplitRow: View {
    @ObservedObject var model: TaskbarConceptState
    let onLaunchApplication: (String) -> Void
    let onTaskbarIconClick: (String) -> Void
    let onTaskbarTileAction: (TaskbarTileAction) -> Void

    var body: some View {
        GeometryReader { geometry in
            let appCount = model.pinnedAppBundleIDs.count
                + model.runningAppOrder.filter({ !model.pinnedAppBundleIDs.contains($0) }).count
            let layout = TaskbarStripMetrics.layout(
                screenWidth: geometry.size.width,
                mode: model.taskbarMode,
                barHeight: model.taskbarHeight,
                gap: model.islandGap,
                appCount: appCount
            )
            ZStack(alignment: .topLeading) {
                ForEach(Array(layout.islands.enumerated()), id: \.offset) { _, island in
                    islandShell(
                        sections: island.sections,
                        frame: island.frame,
                        maxAppTiles: layout.visibleAppTiles,
                        showsOverflow: layout.showsOverflow
                    )
                    .offset(x: island.frame.minX, y: island.frame.minY)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
    }

    private func islandShell(
        sections: [TaskbarSection],
        frame: CGRect,
        maxAppTiles: Int,
        showsOverflow: Bool
    ) -> some View {
        let radius = model.shellRadius(for: .taskbar)
        return TaskbarIslandContent(
            sections: sections,
            model: model,
            onLaunchApplication: onLaunchApplication,
            onTaskbarIconClick: onTaskbarIconClick,
            onTaskbarTileAction: onTaskbarTileAction,
            maxAppTiles: maxAppTiles,
            showOverflowChevron: showsOverflow
        )
        .padding(.horizontal, 10)
        .frame(width: frame.width, height: frame.height)
        .background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.38), lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

private struct TaskbarClockDisplay: View {
    let date: Date
    let style: ClockDisplayStyle
    let dateStyle: ClockDateStyle
    let uses24HourTime: Bool
    let showsSeconds: Bool
    let tint: Color
    let height: CGFloat

    private var time: String {
        clockTime(date, uses24HourTime: uses24HourTime, showsSeconds: showsSeconds)
    }

    var body: some View {
        Group {
            switch style {
            case .stacked:
                VStack(alignment: .trailing, spacing: 2) {
                    timeLabel
                    dateLabel
                }
            case .inline:
                HStack(spacing: 6) {
                    timeLabel
                    Text(dateStyle.string(from: date))
                        .font(.system(size: height * 0.19, weight: .medium))
                        .lineLimit(1)
                }
            case .digital:
                timeLabel
            case .analog:
                HStack(spacing: 6) {
                    AnalogClockFace(date: date, tint: tint, size: min(height - 12, 24))
                    VStack(alignment: .trailing, spacing: 2) {
                        timeLabel
                        dateLabel
                    }
                }
            }
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var timeLabel: some View {
        Text(time)
            .font(.system(size: height * (style == .digital ? 0.32 : 0.27), weight: .semibold, design: .rounded))
            .lineLimit(1)
    }

    private var dateLabel: some View {
        Text(dateStyle.string(from: date))
            .font(.system(size: height * 0.20, weight: .medium))
            .lineLimit(1)
    }
}

private struct AnalogClockFace: View {
    let date: Date
    let tint: Color
    let size: CGFloat

    private var hourAngle: Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double((components.hour ?? 0) % 12) * 30 + Double(components.minute ?? 0) / 2
    }

    private var minuteAngle: Double {
        Double(Calendar.current.component(.minute, from: date)) * 6
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(tint.opacity(0.7), lineWidth: 1.2)
            Capsule()
                .fill(tint)
                .frame(width: 2, height: size * 0.24)
                .offset(y: -size * 0.12)
                .rotationEffect(.degrees(hourAngle))
            Capsule()
                .fill(tint)
                .frame(width: 1.3, height: size * 0.34)
                .offset(y: -size * 0.17)
                .rotationEffect(.degrees(minuteAngle))
            Circle()
                .fill(tint)
                .frame(width: 3, height: 3)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(date.formatted(date: .omitted, time: .shortened))
    }
}

private final class AppIconStore: ObservableObject {
    static let shared = AppIconStore()

    @Published private(set) var icons: [String: NSImage] = [:]

    private let queue = DispatchQueue(label: "com.baraka.splitbar.appicon", qos: .userInitiated)
    private var resolved = Set<String>()

    private init() {}

    func icon(for bundleIdentifier: String) -> NSImage? {
        if let cached = icons[bundleIdentifier] {
            return cached
        }
        resolve(bundleIdentifier)
        return nil
    }

    private func resolve(_ bundleIdentifier: String) {
        guard resolved.insert(bundleIdentifier).inserted else { return }
        queue.async { [weak self] in
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else { return }
            let image = NSWorkspace.shared.icon(forFile: appURL.path)
            DispatchQueue.main.async {
                self?.icons[bundleIdentifier] = image
            }
        }
    }
}

private final class TrashStore: ObservableObject {
    static let shared = TrashStore()

    @Published private(set) var isEmpty = true

    private let queue = DispatchQueue(label: "com.baraka.splitbar.trash", qos: .utility)
    private let metadataQuery = NSMetadataQuery()

    private var trashURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash", isDirectory: true)
    }

    private init() {
        metadataQuery.searchScopes = [trashURL]
        metadataQuery.predicate = NSPredicate(format: "%K LIKE '*'", NSMetadataItemFSNameKey)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryUpdated),
            name: .NSMetadataQueryDidFinishGathering,
            object: metadataQuery
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryUpdated),
            name: .NSMetadataQueryDidUpdate,
            object: metadataQuery
        )
        refresh()
        metadataQuery.start()
    }

    @objc private func queryUpdated() {
        refresh()
    }

    func refresh() {
        let url = trashURL
        queue.async { [weak self] in
            let names = (try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []
            let hasVisibleItems = names.contains { !$0.hasPrefix(".") }
            DispatchQueue.main.async {
                self?.isEmpty = !hasVisibleItems
            }
        }
    }

    func openTrash() {
        NSWorkspace.shared.open(trashURL)
        refresh()
    }

    func emptyTrash() {
        queue.async { [weak self] in
            guard let script = NSAppleScript(source: "tell application \"Finder\" to empty trash") else { return }
            var errorDict: NSDictionary?
            script.executeAndReturnError(&errorDict)
            DispatchQueue.main.async {
                self?.refresh()
            }
        }
    }
}

private struct DownloadsTile: View {
    let tileSide: CGFloat
    let glyphSize: CGFloat

    private var downloadsURL: URL? {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    }

    var body: some View {
        Button {
            if let url = downloadsURL {
                NSWorkspace.shared.open(url)
            }
        } label: {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: glyphSize, weight: .medium))
                .foregroundStyle(.teal)
                .frame(width: tileSide, height: tileSide)
                .taskbarTile()
        }
        .buttonStyle(.plain)
        .help("Open Downloads")
        .disabled(downloadsURL == nil)
    }
}

private struct SystemStatusIcon: View {
    let snapshot: SystemStatusSnapshot
    let glyphSize: CGFloat

    private var ringDiameter: CGFloat { glyphSize * 0.92 }

    private var batteryColor: Color {
        if snapshot.batteryLevel <= 15 { return .red }
        if snapshot.batteryLevel <= 30 { return .orange }
        return .green
    }

    var body: some View {
        HStack(spacing: glyphSize * 0.12) {
            batteryRing
            wifiGlyph
        }
        .accessibilityHidden(true)
    }

    private var batteryRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.18), lineWidth: max(2, glyphSize * 0.09))
                .frame(width: ringDiameter, height: ringDiameter)
            Circle()
                .trim(from: 0, to: CGFloat(snapshot.batteryLevel) / 100)
                .stroke(batteryColor, style: StrokeStyle(lineWidth: max(2, glyphSize * 0.09), lineCap: .round))
                .frame(width: ringDiameter, height: ringDiameter)
                .rotationEffect(.degrees(-90))
            if snapshot.isCharging {
                Image(systemName: "bolt.fill")
                    .font(.system(size: ringDiameter * 0.44, weight: .bold))
                    .foregroundStyle(.yellow)
            } else {
                Text("\(snapshot.batteryLevel)")
                    .font(.system(size: ringDiameter * 0.30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    private var wifiGlyph: some View {
        Image(systemName: snapshot.wifiOn ? "wifi" : "wifi.slash")
            .font(.system(size: glyphSize * 0.5, weight: .medium))
            .foregroundStyle(snapshot.wifiOn ? .primary : .secondary)
    }
}

private struct TrashTile: View {
    let tileSide: CGFloat
    let glyphSize: CGFloat
    let darkMode: Bool
    @ObservedObject private var store = TrashStore.shared

    var body: some View {
        Button {
            store.openTrash()
        } label: {
            Image(systemName: store.isEmpty ? "trash" : "trash.fill")
                .font(.system(size: glyphSize, weight: .medium))
                .foregroundStyle(darkMode ? Color(red: 0.72, green: 0.78, blue: 0.88) : .secondary)
                .frame(width: tileSide, height: tileSide)
                .taskbarTile()
        }
        .buttonStyle(.plain)
        .help(store.isEmpty ? "Open Trash (empty)" : "Open Trash")
        .contextMenu {
            Button("Open Trash") { store.openTrash() }
            Button("Empty Trash") { store.emptyTrash() }
                .disabled(store.isEmpty)
        }
        .onAppear { store.refresh() }
    }
}

private struct TaskbarDividerView: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.14))
            .frame(width: 1)
    }
}

private struct TaskbarTileStyle: ViewModifier {
    var highlighted = false
    var highlightColor = Color.blue
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(highlighted ? highlightColor.opacity(0.22) : Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                highlighted ? highlightColor.opacity(0.55) : Color.white.opacity(colorScheme == .dark ? 0.14 : 0.5),
                                lineWidth: 1
                            )
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
    func taskbarTile(highlighted: Bool = false, highlightColor: Color = .blue) -> some View {
        modifier(TaskbarTileStyle(highlighted: highlighted, highlightColor: highlightColor))
    }
}

private struct MacOSAppIcon: View {
    let bundleIdentifier: String
    let fallbackSymbol: String
    let fallbackColor: Color
    let size: CGFloat
    @ObservedObject private var store = AppIconStore.shared

    var body: some View {
        Group {
            if let icon = store.icons[bundleIdentifier] {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    Image(systemName: fallbackSymbol)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(fallbackColor)
                        .padding(size * 0.14)
                }
                .task(id: bundleIdentifier) {
                    _ = store.icon(for: bundleIdentifier)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct DateWidget: View {
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

private struct SystemRingsWidget: View {
    let cpuPercent: Double
    let memoryPercent: Double
    let diskPercent: Double
    let batteryLevel: Int
    let processCount: Int
    let contentHeight: CGFloat

    private var uptimeText: String {
        let totalMinutes = Int(ProcessInfo.processInfo.systemUptime / 60)
        if totalMinutes < 60 {
            return "\(totalMinutes) mins"
        }
        return "\(totalMinutes / 60) hrs"
    }

    var body: some View {
        WidgetCard(title: "System", symbol: "cpu", tint: .blue, minContentHeight: contentHeight) {
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

private struct NetworkWidget: View {
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

private struct WidgetsPanel: View {
    private var shellRadius: CGFloat { model.shellRadius(for: .widgets) }
    let onClose: () -> Void
    let accent: Color
    @ObservedObject var model: TaskbarConceptState
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency
    @State private var isEditingWidgets = false

    private var boardSections: [WidgetBoardSection] {
        var sections: [WidgetBoardSection] = []
        var leading: [DashboardWidget] = []
        var trailing: [DashboardWidget] = []
        var leadingHeight: CGFloat = 0
        var trailingHeight: CGFloat = 0
        var nextID = 0

        func flushColumns() {
            guard !leading.isEmpty || !trailing.isEmpty else { return }
            sections.append(.columns(id: nextID, leading: leading, trailing: trailing))
            nextID += 1
            leading = []
            trailing = []
            leadingHeight = 0
            trailingHeight = 0
        }

        for widget in model.widgetOrder {
            let size = model.widgetSize(for: widget)
            if size.spansBoard {
                flushColumns()
                sections.append(.fullWidth(id: nextID, widget: widget))
                nextID += 1
            } else if leadingHeight <= trailingHeight {
                leading.append(widget)
                leadingHeight += size.estimatedHeight
            } else {
                trailing.append(widget)
                trailingHeight += size.estimatedHeight
            }
        }
        flushColumns()
        return sections
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Widgets")
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                    Text(isEditingWidgets ? "Drag to rearrange · Choose a size on each card" : "A little overview of your day")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    isEditingWidgets.toggle()
                } label: {
                    Text(isEditingWidgets ? "Done" : "Edit")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 13)
                        .frame(height: 34)
                }
                .buttonStyle(.plain)
                .background(.white.opacity(0.6), in: Capsule())
                .help("Rearrange and resize widgets")
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
                VStack(spacing: 12) {
                    ForEach(boardSections) { section in
                        switch section {
                        case let .columns(_, leading, trailing):
                            HStack(alignment: .top, spacing: 12) {
                                VStack(spacing: 12) {
                                    ForEach(leading) { widget in
                                        widgetTile(widget)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .top)
                                VStack(spacing: 12) {
                                    ForEach(trailing) { widget in
                                        widgetTile(widget)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .top)
                            }
                        case let .fullWidth(_, widget):
                            widgetTile(widget)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
        }
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: shellRadius, style: .continuous)
                .strokeBorder(surfaceStyle == .classic98 ? Color.white.opacity(0.95) : Color.white.opacity(0.72), lineWidth: surfaceStyle == .classic98 ? 2 : 1)
        }
        .shadow(color: .black.opacity(surfaceStyle == .classic98 ? 0.12 : 0.18), radius: surfaceStyle == .glass ? 22 : 14, x: 0, y: surfaceStyle == .classic98 ? 3 : 8)
        .aeroSheen(cornerRadius: shellRadius)
    }

    @ViewBuilder
    private func widgetTile(_ widget: DashboardWidget) -> some View {
        let size = model.widgetSize(for: widget)
        let tile = widgetContent(widget, size: size)
            .overlay(alignment: .topTrailing) {
                if isEditingWidgets {
                    Menu {
                        ForEach(WidgetSizePreset.allCases) { preset in
                            Button {
                                model.setWidgetSize(preset, for: widget)
                            } label: {
                                if preset == size {
                                    Label(preset.title, systemImage: "checkmark")
                                } else {
                                    Text(preset.title)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.primary.opacity(0.75))
                            .frame(width: 25, height: 25)
                            .background(.regularMaterial, in: Circle())
                    }
                    .menuStyle(.borderlessButton)
                    .padding(9)
                    .help("Change widget size")
                }
            }
            .animation(.snappy(duration: 0.22), value: size)

        if isEditingWidgets {
            tile
                .draggable(widget.rawValue)
                .dropDestination(for: String.self) { droppedItems, _ in
                    guard let rawValue = droppedItems.first,
                          let draggedWidget = DashboardWidget(rawValue: rawValue)
                    else {
                        return false
                    }
                    model.moveWidget(draggedWidget, before: widget)
                    return true
                }
        } else {
            tile
        }
    }

    @ViewBuilder
    private func widgetContent(_ widget: DashboardWidget, size: WidgetSizePreset) -> some View {
        switch widget {
        case .weather:
            WeatherWidget(weather: model.weather, contentHeight: size.weatherContentHeight)
        case .systemResources:
            SystemResourcesWidget(contentHeight: size.cardContentHeight)
        case .nowPlaying:
            MediaWidget(model: model, contentHeight: size.cardContentHeight)
        case .photos:
            PhotosWidget(contentHeight: size.cardContentHeight)
        case .stickyNotes:
            StickyNotesWidget(contentHeight: size.cardContentHeight)
        case .watchlist:
            WatchlistWidget(contentHeight: size.cardContentHeight)
        case .date:
            DateWidget(contentHeight: size.cardContentHeight)
        case .systemRings:
            SystemRingsWidget(
                cpuPercent: model.systemMetrics?.cpu.usagePercent ?? 0,
                memoryPercent: model.systemMetrics?.memory.usagePercent ?? 0,
                diskPercent: model.systemMetrics?.disk.usagePercent ?? 0,
                batteryLevel: model.systemStatus.batteryLevel,
                processCount: model.totalProcessCount,
                contentHeight: size.cardContentHeight
            )
        case .network:
            NetworkWidget(
                downBytesPerSecond: model.systemMetrics?.network.bytesInPerSecond ?? 0,
                upBytesPerSecond: model.systemMetrics?.network.bytesOutPerSecond ?? 0,
                peakDownBytesPerSecond: UInt64(model.networkPeakIn),
                peakUpBytesPerSecond: UInt64(model.networkPeakOut),
                contentHeight: size.cardContentHeight
            )
        }
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
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(.primary.opacity(0.84))
                Spacer(minLength: 0)
            }

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
    let weather: WeatherState
    let contentHeight: CGFloat

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
            VStack(alignment: .leading, spacing: 11) {
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

private struct SystemResourcesWidget: View {    let contentHeight: CGFloat

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

private struct TopProcess: Equatable {
    let name: String
    let cpuPercent: Double
    let memoryMB: Double
}

private struct LauncherProcessesCard: View {
    let processes: [TopProcess]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Processes")
                    .font(.system(size: 11, weight: .semibold))
                Spacer(minLength: 4)
                Text("LIVE")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.green)
            }
            HStack {
                Text("PROCESS")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("CORE")
                    .frame(width: 44, alignment: .trailing)
                Text("MEM")
                    .frame(width: 52, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.secondary)
            if processes.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 7) {
                    ForEach(0..<processes.count, id: \.self) { index in
                        processRow(processes[index])
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.045),
            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
    }

    private func processRow(_ process: TopProcess) -> some View {
        HStack {
            Text(process.name)
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(format: "%.1f%%", process.cpuPercent))
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.green)
                .frame(width: 44, alignment: .trailing)
            Text(memoryText(process.memoryMB))
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
        }
    }

    private func memoryText(_ mb: Double) -> String {        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}

private struct LauncherBackgroundAppsCard: View {
    private let backgroundApps: [(String, String, Color)] = [
        ("Browser", "1.2 GB", .blue),
        ("Cloud Sync", "640 MB", .purple),
        ("Video Call", "420 MB", .green),
        ("Photo Editor", "310 MB", .orange)
    ]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Background activity", systemImage: "app.badge")
                    .font(.system(size: 11, weight: .semibold))
                Spacer(minLength: 4)
                Text("2.6 GB")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.purple)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * 0.58)
                }
            }
            .frame(height: 5)

            VStack(spacing: 8) {
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
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.045),
            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
    }
}

private struct PhotosWidget: View {
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

private struct StickyNotesWidget: View {
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

private struct WatchlistWidget: View {
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

private struct MediaWidget: View {
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

private struct BluetoothWidget: View {
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

private struct BatteryWidget: View {
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
    private var shellRadius: CGFloat { model.shellRadius(for: .flyouts) }
    let accent: Color
    @ObservedObject var model: TaskbarConceptState
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency
    @State private var isEditingQuickSettings = false

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
        Set(quickSettings.map(\.title)).subtracting(model.hiddenQuickSettingTitles)
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
                        BatteryWidget(
                            level: model.systemStatus.batteryLevel,
                            isCharging: model.systemStatus.isCharging,
                            isPluggedIn: model.systemStatus.isPluggedIn
                        )
                        .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 112, alignment: .topLeading)
                        statusReadoutTile(
                            title: "Wi-Fi",
                            detail: wifiDetailText,
                            symbol: model.systemStatus.wifiOn ? "wifi" : "wifi.slash",
                            isOn: model.systemStatus.wifiOn
                        )
                        .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 112)
                    }

                    BluetoothWidget(
                        powerOn: model.systemStatus.bluetoothOn,
                        monitoringEnabled: model.showBluetoothDevices,
                        devices: model.systemStatus.bluetoothDevices,
                        onToggleDevice: { connected, address in
                            model.setBluetoothDeviceConnected(connected, address: address)
                        }
                    )

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
                controlSlider(
                    "System",
                    symbol: "speaker.wave.2.fill",
                    value: Binding(
                        get: { model.systemStatus.volumeLevel },
                        set: { model.setOutputVolume($0) }
                    )
                )
                controlSlider("App audio", symbol: "waveform", value: $model.appVolume)
                if model.displayBrightnessUnavailable {
                    Text("No controllable display found.")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    controlSlider(
                        "Brightness",
                        symbol: "sun.max.fill",
                        value: Binding(
                            get: { model.displayBrightness },
                            set: { model.setDisplayBrightness($0) }
                        )
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 9)
            .padding(.bottom, 14)
            .task {
                model.refreshDisplayBrightness()
            }
        }
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: shellRadius, style: .continuous)
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
                    model.hiddenQuickSettingTitles = []
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
        var hiddenTitles = model.hiddenQuickSettingTitles
        if isVisible {
            hiddenTitles.remove(title)
        } else {
            hiddenTitles.insert(title)
        }
        model.hiddenQuickSettingTitles = hiddenTitles
    }

    private var wifiDetailText: String {
        guard model.systemStatus.wifiOn else { return "Off" }
        if model.showWifiName,
           let ssid = model.systemStatus.wifiSSID,
           !ssid.isEmpty {
            return ssid
        }
        return "On · \(model.systemStatus.wifiBars)/3 bars"
    }

    private func statusReadoutTile(
        title: String,
        detail: String,
        symbol: String,
        isOn: Bool
    ) -> some View {
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
        case "Bluetooth": model.bluetoothEnabled
        case "Dark Mode": model.isDarkMode
        case "VPN": model.vpnEnabled
        default: model.enabledQuickSettings.contains(title)
        }
    }

    private func activateQuickSetting(_ title: String) {
        switch title {
        case "Bluetooth":
            model.bluetoothEnabled.toggle()
        case "Dark Mode":
            model.isDarkMode.toggle()
        case "VPN":
            model.vpnEnabled.toggle()
        default:
            if model.enabledQuickSettings.contains(title) {
                model.enabledQuickSettings.remove(title)
            } else {
                model.enabledQuickSettings.insert(title)
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
    @Binding var clockDisplayStyle: ClockDisplayStyle
    @Binding var clockTint: Color
    let accent: Color
    let cornerRadius: CGFloat
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent)
                    Text("Calendar")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                }
                Spacer()
            }
            .padding(18)

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
                        clockDisplayStyle: $clockDisplayStyle,
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
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
    @Binding var clockDisplayStyle: ClockDisplayStyle
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

            HStack(spacing: 6) {
                ForEach(ClockDisplayStyle.allCases) { style in
                    styleChip(style.title, isSelected: clockDisplayStyle == style) {
                        clockDisplayStyle = style
                    }
                }
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
    @Binding var wallpaperPreset: WallpaperPreset
    @Binding var pastelTint: Color
    @Binding var gradientEndTint: Color
    @Binding var gradientAngle: Double
    @Binding var interfaceTransparency: Double
    @Binding var usesTaskbarGradient: Bool
    @Binding var taskbarGradientStart: Color
    @Binding var taskbarGradientEnd: Color
    @Binding var taskbarHeight: CGFloat
    @Binding var showsTaskbarPanel: Bool
    @Binding var hideMacDock: Bool
    @Binding var showWindowPreviews: Bool
    @Binding var runningIndicatorStyle: RunningIndicatorStyle
    @Binding var runningIndicatorSize: RunningIndicatorSize
    @Binding var runningIndicatorColor: Color
    @Binding var minimizeMode: AppMinimizeMode
    @Binding var contextMenuStyle: ContextMenuStyle
    @Binding var showWifiName: Bool
    @Binding var showBluetoothDevices: Bool
    @Binding var ddcBrightnessEnabled: Bool
    @Binding var cornerStyle: CornerStyle
    @Binding var cornerScope: CornerScope
    @Binding var cornerTaskbar: CornerStyle
    @Binding var cornerWidgets: CornerStyle
    @Binding var cornerFlyouts: CornerStyle
    @Binding var taskbarIconSize: TaskbarIconSize
    @Binding var trashPlacement: TrashPlacement
    @Binding var panelWidths: [PanelKind: CGFloat]
    let accent: Color
    let onClose: () -> Void
    let onResetPersonalisation: () -> Void
    let cornerRadius: CGFloat
    @State private var isConfirmingReset = false
    @Environment(\.surfaceStyle) private var currentStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    private var sectionFill: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.13 : 0.045)
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            content()
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(sectionFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sliderValueLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(minWidth: 38, alignment: .trailing)
    }

    private func cornerStyleButton(_ style: CornerStyle, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(style.title)
                .font(.system(size: 9, weight: .semibold))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    selected ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                    in: RoundedRectangle(cornerRadius: 9)
                )
        }
        .buttonStyle(.plain)
    }

    private func cornerSurfaceRow(_ title: String, selection: Binding<CornerStyle>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .medium))
            Spacer()
            Picker("", selection: selection) {
                ForEach(CornerStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 190)
        }
    }

    private func surfaceStyleRow(_ style: SurfaceStyle) -> some View {
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
            .background(
                surfaceStyle == style ? style.accent(darkMode: isDarkMode).opacity(0.1) : Color.primary.opacity(0.035),
                in: RoundedRectangle(cornerRadius: style.cornerRadius)
            )
        }
        .buttonStyle(.plain)
    }

    private func panelWidthBinding(for kind: PanelKind) -> Binding<Double> {
        Binding(
            get: { Double(panelWidths[kind] ?? kind.defaultWidth) },
            set: { panelWidths[kind] = min(kind.maximumWidth, max(kind.minimumWidth, CGFloat($0))) }
        )
    }

    private func iconSizePresetButton(_ size: TaskbarIconSize) -> some View {
        Button {
            taskbarIconSize = size
        } label: {
            VStack(spacing: 7) {
                Image(systemName: "app.fill")
                    .font(.system(size: 14 + CGFloat(TaskbarIconSize.allCases.firstIndex(of: size) ?? 1) * 4, weight: .medium))
                    .foregroundStyle(accent)
                    .frame(height: 26)
                Text(size.title)
                    .font(.system(size: 9, weight: .semibold))
            }
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(
                taskbarIconSize == size ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .buttonStyle(.plain)
    }

    private func trashPlacementButton(_ placement: TrashPlacement) -> some View {
        Button {
            trashPlacement = placement
        } label: {
            Text(placement.title)
                .font(.system(size: 9, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    trashPlacement == placement ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                    in: RoundedRectangle(cornerRadius: 9)
                )
        }
        .buttonStyle(.plain)
    }

    private func panelWidthRow(_ kind: PanelKind) -> some View {
        HStack {
            Text(kind.title)
                .font(.system(size: 10, weight: .medium))
                .frame(width: 96, alignment: .leading)
            Slider(value: panelWidthBinding(for: kind), in: Double(kind.minimumWidth)...Double(kind.maximumWidth), step: 10)
                .tint(accent)
            sliderValueLabel("\(Int(panelWidths[kind] ?? kind.defaultWidth)) pt")
        }
    }

    private func wallpaperPresetButton(_ preset: WallpaperPreset) -> some View {
        Button {
            wallpaperPreset = preset
            isDarkMode = preset.isDark
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        LinearGradient(
                            colors: preset == .custom ? [pastelTint, gradientEndTint] : preset.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 38)
                Text(preset.title)
                    .font(.system(size: 9, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                wallpaperPreset == preset ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .buttonStyle(.plain)
    }

    private var taskbarBehaviorSection: some View {
        settingsSection("Taskbar behavior") {
            Text("Running indicator")
                .font(.system(size: 10, weight: .medium))
            HStack(spacing: 8) {
                ForEach(RunningIndicatorStyle.allCases) { style in
                    indicatorStyleButton(style)
                }
            }
            HStack {
                ForEach(RunningIndicatorSize.allCases) { size in
                    indicatorSizeButton(size)
                }
                Spacer(minLength: 8)
                ColorPicker("Colour", selection: $runningIndicatorColor, supportsOpacity: false)
                    .font(.system(size: 10, weight: .medium))
            }
            Text("Click focused app")
                .font(.system(size: 10, weight: .medium))
                .padding(.top, 2)
            HStack(spacing: 8) {
                ForEach(AppMinimizeMode.allCases) { mode in
                    minimizeModeButton(mode)
                }
            }
            Text("Minimize needs Accessibility; first use explains the prompt. Hide needs nothing.")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Text("Right-click menu")
                .font(.system(size: 10, weight: .medium))
                .padding(.top, 2)
            HStack(spacing: 8) {
                ForEach(ContextMenuStyle.allCases) { style in
                    contextMenuStyleButton(style)
                }
            }
            Toggle(isOn: $showWindowPreviews) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Window previews")
                        .font(.system(size: 11, weight: .medium))
                    Text("Live thumbnails on icon hover. Needs Screen Recording; icon fallback otherwise.")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
            .padding(.top, 2)
            Toggle(isOn: $showWifiName) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Show Wi-Fi network name")
                        .font(.system(size: 11, weight: .medium))
                    Text("Needs Location; macOS prompts once on first read.")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
            .padding(.top, 2)
            Toggle(isOn: $showBluetoothDevices) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Bluetooth devices")
                        .font(.system(size: 11, weight: .medium))
                    Text("Lists paired devices with tap-to-connect. Prompts for Bluetooth on first read; per-device batteries have no public API.")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
            .padding(.top, 2)
            Toggle(isOn: $ddcBrightnessEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("External display brightness (DDC)")
                        .font(.system(size: 11, weight: .medium))
                    Text("Uses a private display API, isolated and probed at runtime. External writes are hardware-unverified; built-in display uses public API.")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
            .padding(.top, 2)
        }
    }

    private func indicatorStyleButton(_ style: RunningIndicatorStyle) -> some View {
        Button {
            runningIndicatorStyle = style
        } label: {
            Text(style.title)
                .font(.system(size: 9, weight: .semibold))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    runningIndicatorStyle == style ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                    in: RoundedRectangle(cornerRadius: 9)
                )
        }
        .buttonStyle(.plain)
    }

    private func indicatorSizeButton(_ size: RunningIndicatorSize) -> some View {
        Button {
            runningIndicatorSize = size
        } label: {
            Text(size.title)
                .font(.system(size: 9, weight: .semibold))
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    runningIndicatorSize == size ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                    in: RoundedRectangle(cornerRadius: 9)
                )
        }
        .buttonStyle(.plain)
    }

    private func minimizeModeButton(_ mode: AppMinimizeMode) -> some View {
        Button {
            minimizeMode = mode
        } label: {
            Text(mode.title)
                .font(.system(size: 9, weight: .semibold))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    minimizeMode == mode ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                    in: RoundedRectangle(cornerRadius: 9)
                )
        }
        .buttonStyle(.plain)
    }

    private func contextMenuStyleButton(_ style: ContextMenuStyle) -> some View {
        Button {
            contextMenuStyle = style
        } label: {
            Text(style.title)
                .font(.system(size: 9, weight: .semibold))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    contextMenuStyle == style ? accent.opacity(0.12) : Color.primary.opacity(0.035),
                    in: RoundedRectangle(cornerRadius: 9)
                )
        }
        .buttonStyle(.plain)
    }

    private var quickSettingsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            taskbarModeSection
            appearanceSection
            transparencySection
            taskbarHeightSection
        }
    }

    private var taskbarModeSection: some View {
        settingsSection("Taskbar mode") {
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
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
            Toggle(isOn: $showsTaskbarPanel) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Screen-edge panel")
                        .font(.system(size: 11, weight: .medium))
                    Text("Show the taskbar in a bottom-edge panel with flyouts above it.")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
            Toggle(isOn: $hideMacDock) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Hide macOS Dock")
                        .font(.system(size: 11, weight: .medium))
                    Text("Experimental and reversible. Original Dock settings restore on quit, crash recovery included.")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
        }
    }

    private var appearanceSection: some View {
        settingsSection("Appearance") {
            Toggle(isOn: $isDarkMode) {
                Label(
                    isDarkMode ? "Dark appearance" : "Light appearance",
                    systemImage: isDarkMode ? "moon.stars.fill" : "sun.max.fill"
                )
                .font(.system(size: 11, weight: .medium))
            }
            .toggleStyle(.switch)
        }
    }

    private var transparencySection: some View {
        settingsSection("Transparency") {
            Toggle(isOn: Binding(
                get: { interfaceTransparency > 0 },
                set: { interfaceTransparency = $0 ? 0.68 : 0 }
            )) {
                Text("Enable transparency")
                    .font(.system(size: 11, weight: .medium))
            }
            .toggleStyle(.switch)
            Slider(value: $interfaceTransparency, in: 0...0.9, step: 0.01)
                .tint(accent)
                .disabled(interfaceTransparency == 0)
            HStack {
                sliderValueLabel("\(Int(interfaceTransparency * 100))%")
                Spacer(minLength: 0)
                Text("Panels and taskbar")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var taskbarHeightSection: some View {
        settingsSection("Taskbar height") {
            Slider(value: $taskbarHeight, in: 32...48, step: 2)
                .tint(accent)
            HStack {
                Text("Compact")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                sliderValueLabel("\(Int(taskbarHeight)) pt")
            }
        }
    }

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
                Button {
                    isConfirmingReset = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(sectionFill, in: Circle())
                }
                .buttonStyle(.plain)
                .help("Reset Personalisation to defaults")
                .confirmationDialog(
                    "Reset Personalisation?",
                    isPresented: $isConfirmingReset,
                    titleVisibility: .visible
                ) {
                    Button("Reset everything", role: .destructive) {
                        onResetPersonalisation()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Widths, icons, trash position, wallpaper, and taskbar appearance return to defaults. Pins and widgets are untouched.")
                }
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(sectionFill, in: Circle())
                }
                .buttonStyle(.plain)
            }

            quickSettingsGrid

            taskbarBehaviorSection

            settingsSection("Taskbar icons") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(TaskbarIconSize.allCases) { size in
                        iconSizePresetButton(size)
                    }
                }
                Text("Trash position")
                    .font(.system(size: 10, weight: .medium))
                    .padding(.top, 2)
                HStack(spacing: 8) {
                    ForEach(TrashPlacement.allCases) { placement in
                        trashPlacementButton(placement)
                    }
                }
            }

            settingsSection("Panel widths") {
                ForEach(PanelKind.allCases) { kind in
                    panelWidthRow(kind)
                }
                Text("Windows 11-style narrow defaults; widen any panel back toward its previous width.")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            settingsSection("Surface style") {
                ForEach(SurfaceStyle.allCases) { style in
                    surfaceStyleRow(style)
                }
            }

            settingsSection("Corners") {
                HStack(spacing: 8) {
                    ForEach(CornerStyle.allCases) { style in
                        cornerStyleButton(style, selected: cornerStyle == style) {
                            cornerStyle = style
                        }
                    }
                }
                HStack {
                    Text("Apply to")
                        .font(.system(size: 10, weight: .medium))
                    Spacer()
                    Picker("", selection: $cornerScope) {
                        ForEach(CornerScope.allCases) { scope in
                            Text(scope.title).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 190)
                }
                if cornerScope == .perSurface {
                    cornerSurfaceRow("Taskbar", selection: $cornerTaskbar)
                    cornerSurfaceRow("Widgets", selection: $cornerWidgets)
                    cornerSurfaceRow("Flyouts", selection: $cornerFlyouts)
                }
                Text("Pill rounds shells fully (capped on tall panels); Sharp floors at 2 pt so beveled themes keep reading.")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            settingsSection("Desktop wallpaper") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(WallpaperPreset.allCases) { preset in
                        wallpaperPresetButton(preset)
                    }
                }
                Text("Choose a preset or pick Custom to tune the gradient colours.")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                if wallpaperPreset == .custom {
                    HStack {
                        ColorPicker("Start colour", selection: $pastelTint, supportsOpacity: false)
                        ColorPicker("End colour", selection: $gradientEndTint, supportsOpacity: false)
                    }
                    .font(.system(size: 10, weight: .medium))
                }
                HStack {
                    Text("Gradient angle")
                        .font(.system(size: 10, weight: .medium))
                    Slider(value: $gradientAngle, in: 0...360, step: 1)
                        .tint(accent)
                    sliderValueLabel("\(Int(gradientAngle))°")
                }
            }

            settingsSection("Taskbar gradient") {
                Toggle("Use custom taskbar gradient", isOn: $usesTaskbarGradient)
                    .toggleStyle(.switch)
                    .font(.system(size: 11, weight: .medium))
                HStack {
                    ColorPicker("Start", selection: $taskbarGradientStart, supportsOpacity: false)
                    ColorPicker("End", selection: $taskbarGradientEnd, supportsOpacity: false)
                }
                .font(.system(size: 10, weight: .medium))
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        }
        .scrollIndicators(.hidden)
        .background(panelBackground(style: currentStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .background(surfaceWash(style: currentStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(currentStyle == .classic98 ? Color.white : Color.white.opacity(0.76), lineWidth: currentStyle == .classic98 ? 2 : 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
    }
}

private struct StartFlyout: View {
    private var shellRadius: CGFloat { model.shellRadius(for: .flyouts) }
    let onClose: () -> Void
    let accent: Color
    @ObservedObject var model: TaskbarConceptState
    let onLaunchApplication: (String) -> Void
    @State private var isEditingPins = false
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.surfaceTransparency) private var transparency

    private var apps: [LauncherApp] { LauncherDefaults.apps }

    private var folders: [LauncherFolder] { LauncherDefaults.folders }

    private var filteredCatalogApps: [ApplicationDescriptor] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return catalogApps }
        return catalogApps.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
    }

    private func loadCatalog() async {
        guard catalogApps.isEmpty else { return }
        let scanned = await Task.detached(priority: .userInitiated) {
            ApplicationCatalogService().scan(directories: ApplicationCatalogService.catalogDirectories())
        }.value
        catalogApps = scanned
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.system(size: 14, weight: .semibold))
            if !model.recentAppIDs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(model.recentAppIDs, id: \.self) { bundleID in
                            recentAppCell(bundleID)
                        }
                    }
                }
            }
            if !model.recentFolderTitles.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(model.recentFolderTitles.filter({ title in folders.contains(where: { $0.title == title }) }), id: \.self) { title in
                        if let folder = folders.first(where: { $0.title == title }) {
                            folderCell(folder)
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private func recentAppTitle(_ bundleID: String) -> String {
        if let known = apps.first(where: { $0.bundleIdentifier == bundleID }) {
            return known.title
        }
        if let scanned = catalogApps.first(where: { $0.bundleIdentifier == bundleID }) {
            return scanned.displayName
        }
        return bundleID
    }

    private func recentAppCell(_ bundleID: String) -> some View {
        Button {
            onLaunchApplication(bundleID)
        } label: {
            VStack(spacing: 6) {
                MacOSAppIcon(
                    bundleIdentifier: bundleID,
                    fallbackSymbol: "app.fill",
                    fallbackColor: .secondary,
                    size: 30
                )
                .frame(width: 46, height: 46)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.07), in: RoundedRectangle(cornerRadius: 13))
                Text(recentAppTitle(bundleID))
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
        .help(recentAppTitle(bundleID))
    }

    private var allAppsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("All apps")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(filteredCatalogApps.count) apps")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            if catalogApps.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if filteredCatalogApps.isEmpty {
                Text("No apps match your search.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                    ForEach(filteredCatalogApps) { app in
                        catalogAppCell(app)
                    }
                }
            }
        }
        .padding(.top, 4)
        .task {
            await loadCatalog()
        }
    }

    private func pinnedCell(_ app: LauncherApp) -> some View {
        Button {
            if isEditingPins {
                model.setPinned(app.bundleIdentifier, isPinned: false)
            } else {
                onLaunchApplication(app.bundleIdentifier)
            }
        } label: {            VStack(spacing: 8) {
                MacOSAppIcon(
                    bundleIdentifier: app.bundleIdentifier,
                    fallbackSymbol: app.symbol,
                    fallbackColor: app.color,
                    size: 34
                )
                .frame(width: 54, height: 54)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.07), in: RoundedRectangle(cornerRadius: 15))
                Text(app.title).font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                if isEditingPins {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .draggable(app.bundleIdentifier)
        .dropDestination(for: String.self) { droppedItems, _ in
            guard let draggedID = droppedItems.first else { return false }
            model.movePinned(draggedID, before: app.bundleIdentifier)
            return true
        }
    }

    private func pinEditCell(_ app: LauncherApp) -> some View {        let isPinned = model.pinnedAppBundleIDs.contains(app.bundleIdentifier)
        return Button {
            model.setPinned(app.bundleIdentifier, isPinned: !isPinned)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isPinned ? "pin.fill" : "plus")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(isPinned ? accent : .secondary)
                Text(app.title)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.045), in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .disabled(!isPinned && model.pinnedAppBundleIDs.count >= 8)
        .opacity(!isPinned && model.pinnedAppBundleIDs.count >= 8 ? 0.45 : 1)
    }
    private func folderCell(_ folder: LauncherFolder) -> some View {
        Button {
            if let url = folder.url {
                NSWorkspace.shared.open(url)
                model.recordFolderOpen(folder.title)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: folder.symbol)
                    .font(.system(size: 13))
                    .foregroundStyle(folder.tint)
                    .frame(width: 26, height: 26)
                    .background(folder.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text(folder.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: 42)
            .background(
                Color.primary.opacity(colorScheme == .dark ? 0.13 : 0.05),
                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

        private func catalogAppCell(_ app: ApplicationDescriptor) -> some View {
        Button {
            onLaunchApplication(app.bundleIdentifier)
        } label: {
            VStack(spacing: 8) {
                MacOSAppIcon(
                    bundleIdentifier: app.bundleIdentifier,
                    fallbackSymbol: "app.fill",
                    fallbackColor: .secondary,
                    size: 34
                )
                .frame(width: 54, height: 54)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.07), in: RoundedRectangle(cornerRadius: 15))
                Text(app.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 26)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .help(app.displayName)
    }

    @State private var userIdentity = UserIdentityService.currentIdentity()
    @State private var userAvatar: NSImage?
    @State private var pendingPowerAction: SystemPowerAction?
    @State private var powerErrorMessage: String?
    @State private var searchQuery = ""
    @State private var catalogApps: [ApplicationDescriptor] = []

    private var launcherFooter: some View {
        HStack {
            HStack(spacing: 10) {
                if let userAvatar {
                    Image(nsImage: userAvatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 30, height: 30)
                        .overlay {
                            Text(userIdentity.initials)
                                .font(.system(size: 11, weight: .semibold))
                        }
                }
                Text(userIdentity.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            }
            Spacer()
            Button {
                model.openPanel = .settings
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.07), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .help("Open Personalisation")
            powerMenu
        }
        .onAppear {
            userAvatar = UserIdentityService.avatarImage(for: userIdentity)
        }
        .confirmationDialog(
            powerConfirmationTitle,
            isPresented: Binding(
                get: { pendingPowerAction != nil },
                set: { if !$0 { pendingPowerAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Confirm", role: .destructive) {
                if let action = pendingPowerAction {
                    pendingPowerAction = nil
                    runPowerAction(action)
                }
            }
            Button("Cancel", role: .cancel) {
                pendingPowerAction = nil
            }
        } message: {
            Text("This uses macOS Automation and may ask for permission first.")
        }
        .alert("Couldn't complete the action", isPresented: Binding(
            get: { powerErrorMessage != nil },
            set: { if !$0 { powerErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(powerErrorMessage ?? "")
        }
    }

    private var powerConfirmationTitle: String {
        switch pendingPowerAction {
        case .restart: "Restart this Mac now?"
        case .shutDown: "Shut down this Mac now?"
        case .logOut: "Log out now?"
        case .lock, .sleep, .none: "Continue?"
        }
    }

    private var powerMenu: some View {
        Menu {
            Button {
                runPowerAction(.lock)
            } label: {
                Label("Lock", systemImage: "lock.fill")
            }
            Button {
                runPowerAction(.sleep)
            } label: {
                Label("Sleep", systemImage: "moon.zzz.fill")
            }
            Divider()
            Button {
                pendingPowerAction = .restart
            } label: {
                Label("Restart…", systemImage: "arrow.clockwise")
            }
            Button {
                pendingPowerAction = .shutDown
            } label: {
                Label("Shut Down…", systemImage: "power")
            }
            Button {
                pendingPowerAction = .logOut
            } label: {
                Label("Log Out…", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Image(systemName: "power")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 34, height: 34)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.07), in: RoundedRectangle(cornerRadius: 10))
        }
        .menuStyle(.borderlessButton)
        .help("Power options")
    }

    private func runPowerAction(_ action: SystemPowerAction) {
        performSystemPowerAction(action) { result in
            if case .failure(let error) = result {
                powerErrorMessage = error.description
            }
        }
    }

    private var pinnedApps: [LauncherApp] {
        model.pinnedAppBundleIDs.compactMap { bundleID in
            apps.first { $0.bundleIdentifier == bundleID }
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 11) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(accent)
                TextField("Search apps, settings and files", text: $searchQuery)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
                if searchQuery.isEmpty {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.06), in: Capsule())

            ScrollView {
                HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Pinned")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Button(isEditingPins ? "Done" : "Edit") {
                            isEditingPins.toggle()
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .buttonStyle(.plain)
                        .foregroundStyle(accent)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 19) {
                        ForEach(Array(pinnedApps.prefix(4))) { app in
                            pinnedCell(app)
                        }
                    }

                    Toggle("Show only 4 pinned apps", isOn: $model.showOnlyFourPinned)
                        .toggleStyle(.switch)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.top, 2)

                    if !model.recentAppIDs.isEmpty || !model.recentFolderTitles.isEmpty {
                        recentSection
                    }

                    if !isEditingPins && !model.showOnlyFourPinned {
                        allAppsSection
                    }

                    if isEditingPins {
                        HStack {
                            Text("All apps")
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text("\(model.pinnedAppBundleIDs.count) of 8 pinned")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach(apps) { app in
                                pinEditCell(app)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08))
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 13) {
                    LauncherBackgroundAppsCard()

                    HStack {
                        Text("Folders")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(folders) { folder in
                            folderCell(folder)
                        }
                    }

                    LauncherProcessesCard(processes: model.topProcesses)

                    Spacer(minLength: 0)
                }
                .frame(width: 250, alignment: .leading)
                }
            }
            .scrollIndicators(.hidden)

            launcherFooter
        }
        .padding(25)
        .background(panelBackground(style: surfaceStyle, darkMode: colorScheme == .dark, transparency: transparency), in: RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .background(surfaceWash(style: surfaceStyle, darkMode: colorScheme == .dark))
        .clipShape(RoundedRectangle(cornerRadius: shellRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: shellRadius, style: .continuous)
                .strokeBorder(surfaceStyle == .classic98 ? Color.white : Color.white.opacity(0.76), lineWidth: surfaceStyle == .classic98 ? 2 : 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
    }
}

private extension Date {
    var nextMinuteBoundary: Date {
        let calendar = Calendar.current
        let startOfMinute = calendar.dateInterval(of: .minute, for: self)?.start ?? self
        return calendar.date(byAdding: .minute, value: 1, to: startOfMinute) ?? self.addingTimeInterval(60)
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

    var storedRGBA: [Double] {
        guard let color = NSColor(self).usingColorSpace(.deviceRGB) else {
            return [0.91, 0.69, 0.87, 1]
        }
        return [
            Double(color.redComponent),
            Double(color.greenComponent),
            Double(color.blueComponent),
            Double(color.alphaComponent)
        ]
    }

    static func fromStoredRGBA(_ values: [Double]) -> Color? {
        guard values.count == 4,
              values.allSatisfy({ (0...1).contains($0) })
        else {
            return nil
        }
        return Color(
            .sRGB,
            red: values[0],
            green: values[1],
            blue: values[2],
            opacity: values[3]
        )
    }
}
