import SwiftUI

enum TaskbarIconSize: String, CaseIterable, Identifiable {
    case extraSmall
    case small
    case medium
    case large
    case extraLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .extraSmall: "XS"
        case .small: "S"
        case .medium: "M"
        case .large: "L"
        case .extraLarge: "XL"
        }
    }

    var glyphFraction: CGFloat {
        switch self {
        case .extraSmall: 0.42
        case .small: 0.50
        case .medium: 0.60
        case .large: 0.72
        case .extraLarge: 0.84
        }
    }
}


enum StatusIconPreset: String, CaseIterable, Identifiable {
    case batteryOnly
    case batteryVolume
    case batteryVolumeNet
    case customSFSymbol

    var id: String { rawValue }

    var title: String {
        switch self {
        case .batteryOnly: "Battery"
        case .batteryVolume: "Battery + volume"
        case .batteryVolumeNet: "Battery + volume + network"
        case .customSFSymbol: "Custom symbol"
        }
    }
}


enum IconShape: String, CaseIterable, Identifiable {
    case circle
    case roundedRect
    case roundedRectLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .circle: "Circle"
        case .roundedRect: "Rounded"
        case .roundedRectLarge: "Large rounded"
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


/// Resolved fill for the running indicator: a flat colour or a two-stop gradient.
struct IndicatorFill: Equatable {
    enum Kind: Equatable {
        case solid(Color)
        case gradient(Color, Color)
    }

    var kind: Kind

    static func solid(_ color: Color) -> IndicatorFill {
        IndicatorFill(kind: .solid(color))
    }

    func style(opacity: Double) -> AnyShapeStyle {
        switch kind {
        case .solid(let color):
            AnyShapeStyle(color.opacity(opacity))
        case .gradient(let start, let end):
            AnyShapeStyle(LinearGradient(
                colors: [start.opacity(opacity), end.opacity(opacity)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        }
    }
}


enum IndicatorColorPreset: String, CaseIterable, Identifiable {
    case auto
    case blue
    case green
    case red
    case orange
    case purple
    case pink
    case white
    case gradient

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: "Auto"
        case .blue: "Blue"
        case .green: "Green"
        case .red: "Red"
        case .orange: "Orange"
        case .purple: "Purple"
        case .pink: "Pink"
        case .white: "White"
        case .gradient: "Gradient"
        }
    }

    func color(surfaceStyle: SurfaceStyle, darkMode: Bool) -> Color? {
        switch self {
        case .auto:
            surfaceStyle.accent(darkMode: darkMode)
        case .blue: .blue
        case .green: .green
        case .red: .red
        case .orange: .orange
        case .purple: .purple
        case .pink: .pink
        case .white: .white
        case .gradient: nil
        }
    }
}


enum ClockColorPreset: String, CaseIterable, Identifiable {
    case auto
    case white
    case primary
    case blue
    case pink
    case orange
    case gradient

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: "Auto"
        case .white: "White"
        case .primary: "Primary"
        case .blue: "Blue"
        case .pink: "Pink"
        case .orange: "Orange"
        case .gradient: "Gradient"
        }
    }

    func color(surfaceStyle: SurfaceStyle, darkMode: Bool) -> Color? {
        switch self {
        case .auto:
            surfaceStyle.accent(darkMode: darkMode)
        case .white: .white
        case .primary: .primary
        case .blue: .blue
        case .pink: .pink
        case .orange: .orange
        case .gradient: nil
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


enum FlyoutAnimation: String, CaseIterable, Identifiable {
    case dissolve
    case slideUp
    case slideDown
    case sideLeft
    case sideRight
    case spring
    case flip
    case zoom
    case none

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dissolve: "Dissolve"
        case .slideUp: "Slide up"
        case .slideDown: "Slide down"
        case .sideLeft: "Slide left"
        case .sideRight: "Slide right"
        case .spring: "Spring"
        case .flip: "Flip"
        case .zoom: "Zoom"
        case .none: "None"
        }
    }

    func asTransition() -> AnyTransition {
        switch self {
        case .dissolve:
            return .opacity
        case .slideUp:
            return .move(edge: .bottom).combined(with: .opacity)
        case .slideDown:
            return .move(edge: .top).combined(with: .opacity)
        case .sideLeft:
            return .move(edge: .trailing).combined(with: .opacity)
        case .sideRight:
            return .move(edge: .leading).combined(with: .opacity)
        case .spring:
            return .scale(scale: 0.94).combined(with: .opacity)
        case .flip:
            return AnyTransition.modifier(
                active: FlipTransitionModifier(angle: 90),
                identity: FlipTransitionModifier(angle: 0)
            ).combined(with: .opacity)
        case .zoom:
            return AnyTransition.scale(scale: 0.7).combined(with: .opacity)
        case .none:
            return .identity
        }
    }
}


struct FlipTransitionModifier: ViewModifier {
    var angle: Double

    func body(content: Content) -> some View {
        content.rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0))
    }
}


enum FlyoutHeightPreset: String, CaseIterable, Identifiable {
    case compact
    case regular
    case tall
    case extraTall
    case fullScreen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: "Compact"
        case .regular: "Regular"
        case .tall: "Tall"
        case .extraTall: "Extra tall"
        case .fullScreen: "Full screen"
        }
    }

    var points: CGFloat? {
        switch self {
        case .compact: 320
        case .regular: 520
        case .tall: 720
        case .extraTall: 900
        case .fullScreen: nil
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
    case addDivider(afterBundleID: String)
    case removeDivider(afterBundleID: String)
    case moveDivider(id: UUID, afterBundleID: String)
}
