import SwiftUI

struct LauncherApp: Identifiable {
    let bundleIdentifier: String
    let symbol: String
    let title: String
    let color: Color

    var id: String { bundleIdentifier }
}


struct LauncherFolder: Identifiable {
    let title: String
    let symbol: String
    let tint: Color
    let directory: FileManager.SearchPathDirectory

    var id: String { title }

    var url: URL? {
        FileManager.default.urls(for: directory, in: .userDomainMask).first
    }
}


enum LauncherDefaults {
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
    @Published var surfaceStyle = SurfaceStyle.glassmorphism
    @Published var isDarkMode = false
    @Published var wallpaperPreset = WallpaperPreset.pastelBloom {
        didSet { UserDefaults.standard.set(wallpaperPreset.rawValue, forKey: "wallpaper.preset") }
    }
    @Published var pastelTint = Color(red: 0.91, green: 0.69, blue: 0.87) {
        didSet { persist(key: "wallpaper.customStart", value: pastelTint.storedRGBA) }
    }
    @Published var gradientEndTint = Color(red: 0.47, green: 0.70, blue: 0.86) {
        didSet { persist(key: "wallpaper.customEnd", value: gradientEndTint.storedRGBA) }
    }
    @Published var gradientAngle = 35.0 {
        didSet { persist(key: "wallpaper.gradientAngle", value: gradientAngle) }
    }
    @Published var interfaceTransparency = 0.40
    @Published var usesTaskbarGradient = false
    @Published var taskbarGradientStart = Color(red: 0.78, green: 0.48, blue: 0.86)
    @Published var taskbarGradientEnd = Color(red: 0.96, green: 0.38, blue: 0.42)
    @Published var taskbarHeight: CGFloat = 46
    @Published var showsTaskbarPanel = false {
        didSet { UserDefaults.standard.set(showsTaskbarPanel, forKey: "taskbar.panelShown") }
    }
    @Published var taskbarIconSize = TaskbarIconSize.medium {
        didSet { UserDefaults.standard.set(taskbarIconSize.rawValue, forKey: "taskbar.iconSize") }
    }
    @Published var statusIconPreset = StatusIconPreset.batteryOnly {
        didSet { UserDefaults.standard.set(statusIconPreset.rawValue, forKey: "status.iconPreset") }
    }
    @Published var statusIconCustomSymbol = "battery.75percent" {
        didSet { UserDefaults.standard.set(statusIconCustomSymbol, forKey: "status.customSymbol") }
    }
    @Published var widgetOutlineBorder = true {
        didSet { UserDefaults.standard.set(widgetOutlineBorder, forKey: "widgets.outlineBorder") }
    }
    @Published var widgetOutlineWidth: CGFloat = 1.0 {
        didSet { UserDefaults.standard.set(Double(widgetOutlineWidth), forKey: "widgets.outlineWidth") }
    }
    @Published var iconBackgroundVisible = true {
        didSet { UserDefaults.standard.set(iconBackgroundVisible, forKey: "icons.backgroundVisible") }
    }
    @Published var iconBackgroundShape = IconShape.roundedRect {
        didSet { UserDefaults.standard.set(iconBackgroundShape.rawValue, forKey: "icons.backgroundShape") }
    }
    @Published var trashPlacement = TrashPlacement.withApps {
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

    var widgetOutline: WidgetOutlineStyle {
        WidgetOutlineStyle(showsBorder: widgetOutlineBorder, width: max(0.5, widgetOutlineWidth))
    }

    var iconBackground: IconBackgroundStyle {
        IconBackgroundStyle(isVisible: iconBackgroundVisible, shape: iconBackgroundShape)
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
    @Published var systemStatus = SystemStatusSnapshot.placeholder()
    private let systemStatusService = SystemStatusService()
    @Published var topProcesses: [TopProcess] = []
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
    @Published var indicatorColorPreset = IndicatorColorPreset.auto {
        didSet { UserDefaults.standard.set(indicatorColorPreset.rawValue, forKey: "taskbar.indicatorPreset") }
    }
    @Published var indicatorGradientStart = Color.blue {
        didSet { UserDefaults.standard.set(indicatorGradientStart.storedRGBA, forKey: "taskbar.indicatorGradientStart") }
    }
    @Published var indicatorGradientEnd = Color.purple {
        didSet { UserDefaults.standard.set(indicatorGradientEnd.storedRGBA, forKey: "taskbar.indicatorGradientEnd") }
    }
    @Published var clockColorPreset = ClockColorPreset.auto {
        didSet { UserDefaults.standard.set(clockColorPreset.rawValue, forKey: "clock.colorPreset") }
    }
    @Published var clockGradientEnabled = false {
        didSet { UserDefaults.standard.set(clockGradientEnabled, forKey: "clock.gradientEnabled") }
    }
    @Published var clockGradientStart = Color.roseAccent {
        didSet { UserDefaults.standard.set(clockGradientStart.storedRGBA, forKey: "clock.gradientStart") }
    }
    @Published var clockGradientEnd = Color.orange {
        didSet { UserDefaults.standard.set(clockGradientEnd.storedRGBA, forKey: "clock.gradientEnd") }
    }

    var resolvedIndicatorFill: IndicatorFill {
        if indicatorColorPreset == .gradient {
            return IndicatorFill(kind: .gradient(indicatorGradientStart, indicatorGradientEnd))
        }
        return .solid(indicatorColorPreset.color(surfaceStyle: surfaceStyle, darkMode: isDarkMode) ?? runningIndicatorColor)
    }

    var resolvedClockTint: Color {
        clockColorPreset.color(surfaceStyle: surfaceStyle, darkMode: isDarkMode) ?? clockTint
    }

    var clockTintGradient: LinearGradient? {
        guard clockGradientEnabled || clockColorPreset == .gradient else { return nil }
        return LinearGradient(
            colors: [clockGradientStart, clockGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    @Published var minimizeMode = AppMinimizeMode.hide {
        didSet { UserDefaults.standard.set(minimizeMode.rawValue, forKey: "taskbar.minimizeMode") }
    }
    @Published var contextMenuStyle = ContextMenuStyle.native {
        didSet { UserDefaults.standard.set(contextMenuStyle.rawValue, forKey: "taskbar.menuStyle") }
    }
    @Published var flyoutAnimation = FlyoutAnimation.spring {
        didSet { UserDefaults.standard.set(flyoutAnimation.rawValue, forKey: "flyouts.animation") }
    }
    @Published var flyoutHeightPreset = FlyoutHeightPreset.tall {
        didSet { UserDefaults.standard.set(flyoutHeightPreset.rawValue, forKey: "flyouts.heightPreset") }
    }
    @Published var reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
        didSet { UserDefaults.standard.set(reduceMotion, forKey: "motion.reduced") }
    }
    @Published var showsOnboarding = !UserDefaults.standard.bool(forKey: "onboarding.v1.complete")

    // Privacy gates, mirrored from AppPreferences so the taskbar settings UI can
    // bind them. Changes are forwarded to the runtime, which persists them.
    @Published var clipboardHistoryEnabled = false {
        didSet { onPrivacyGateChanged?("clipboardHistoryEnabled", clipboardHistoryEnabled) }
    }
    @Published var ipGeolocationEnabled = false {
        didSet { onPrivacyGateChanged?("ipGeolocationEnabled", ipGeolocationEnabled) }
    }
    @Published var faviconServiceEnabled = false {
        didSet { onPrivacyGateChanged?("faviconServiceEnabled", faviconServiceEnabled) }
    }
    @Published var aiAccountSwitchingEnabled = false {
        didSet { onPrivacyGateChanged?("aiAccountSwitchingEnabled", aiAccountSwitchingEnabled) }
    }
    @Published var clipboardRetention = ClipboardRetentionPolicy(maxEntries: 100, maxBlobBytes: 10 * 1024 * 1024) {
        didSet { onClipboardRetentionChanged?(clipboardRetention) }
    }

    /// Set by the runtime: forwards a gate change into AppPreferences.
    var onPrivacyGateChanged: ((String, Bool) -> Void)?
    var onClipboardRetentionChanged: ((ClipboardRetentionPolicy) -> Void)?

    nonisolated static var defaultShortcutBindings: [ShortcutBinding] {
        [
            ShortcutBinding(id: UUID(), chord: ShortcutChord(carbonKeyCode: 0x02, carbonModifiers: 0x0800), action: .toggleDock),
            ShortcutBinding(id: UUID(), chord: ShortcutChord(carbonKeyCode: 0x31, carbonModifiers: 0x0800), action: .openCommandPalette),
            ShortcutBinding(id: UUID(), chord: ShortcutChord(carbonKeyCode: 0x09, carbonModifiers: 0x0800), action: .openClipboard),
            ShortcutBinding(id: UUID(), chord: ShortcutChord(carbonKeyCode: 0x7B, carbonModifiers: 0x1800), action: .tileWindow(.leftHalf)),
            ShortcutBinding(id: UUID(), chord: ShortcutChord(carbonKeyCode: 0x7C, carbonModifiers: 0x1800), action: .tileWindow(.rightHalf)),
            ShortcutBinding(id: UUID(), chord: ShortcutChord(carbonKeyCode: 0x7E, carbonModifiers: 0x1800), action: .tileWindow(.maximize)),
            ShortcutBinding(id: UUID(), chord: ShortcutChord(carbonKeyCode: 0x7D, carbonModifiers: 0x1800), action: .tileWindow(.center)),
        ]
    }

    @Published var shortcutBindings = TaskbarConceptState.defaultShortcutBindings {
        didSet {
            if let data = try? JSONEncoder().encode(shortcutBindings) {
                UserDefaults.standard.set(data, forKey: "shortcuts.bindings")
            }
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarding.v1.complete")
        showsOnboarding = false
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

    func activeBrightnessService() -> (any DisplayBrightnessControlling)? {
        if let builtIn = DisplayBrightness.builtIn() {
            return builtIn
        }
        if ddcBrightnessEnabled {
            return DisplayBrightness.externalDDC()
        }
        return nil
    }

    func refreshDisplayBrightness() {
        guard let service = activeBrightnessService() else {
            displayBrightnessUnavailable = true
            return
        }
        displayBrightnessUnavailable = false
        if let level = service.currentLevel() {
            displayBrightness = min(1, max(0, level))
        }
    }

    func setDisplayBrightness(_ level: Double) {
        guard let service = activeBrightnessService() else { return }
        if service.setLevel(level) {
            displayBrightness = min(1, max(0, level))
            displayBrightnessUnavailable = false
        }
    }
    @Published var previewBundleID: String?
    @Published var systemMetrics: SystemMetrics?
    @Published var weather = WeatherState.defaultSample()
    @Published var weatherWidgetState = WidgetState.placeholder

    func widgetState(for widget: DashboardWidget) -> WidgetState {
        switch widget {
        case .weather:
            weatherWidgetState
        case .systemRings, .systemResources, .network:
            systemMetrics == nil ? .placeholder : .loaded
        default:
            .loaded
        }
    }
    @Published var nowPlaying = NowPlayingState.idle()
    var onTogglePlayback: (() -> Void)?
    @Published var networkPeakIn: Double = 0
    @Published var networkPeakOut: Double = 0
    private let processSampleQueue = DispatchQueue(label: "com.baraka.splitbar.topprocesses", qos: .utility)
    @Published var panelWidths: [PanelKind: CGFloat] = [:] {
        didSet {
            UserDefaults.standard.set(
                Dictionary(uniqueKeysWithValues: panelWidths.map { ($0.key.rawValue, Double($0.value)) }),
                forKey: "panels.widths"
            )
        }
    }
    @Published var showsClockSettings = false
    @Published var uses24HourTime = false
    @Published var showsSeconds = false
    @Published var dateStyle = ClockDateStyle.compact
    @Published var clockDisplayStyle = ClockDisplayStyle.stacked {
        didSet { UserDefaults.standard.set(clockDisplayStyle.rawValue, forKey: "clock.displayStyle") }
    }
    @Published var clockTint = Color.roseAccent
    @Published var displayedMonth = Calendar.current.startOfMonth(for: .now)
    @Published var selectedDate = Date.now
    @Published var widgetOrder = DashboardWidget.allCases {
        didSet { UserDefaults.standard.set(widgetOrder.map(\.rawValue), forKey: "widgets.order") }
    }
    @Published var widgetSizes: [DashboardWidget: WidgetSizePreset] = [:] {
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
    @Published var showOnlyFourPinned = false {
        didSet { UserDefaults.standard.set(showOnlyFourPinned, forKey: "launcher.showOnlyFour") }
    }
    @Published var recentAppIDs: [String] = [] {
        didSet { UserDefaults.standard.set(recentAppIDs, forKey: "launcher.recentApps") }
    }
    @Published var recentFolderTitles: [String] = [] {
        didSet { UserDefaults.standard.set(recentFolderTitles, forKey: "launcher.recentFolders") }
    }
    @Published var hiddenQuickSettingTitles: Set<String> = [] {
        didSet { UserDefaults.standard.set(hiddenQuickSettingTitles.sorted().joined(separator: "|"), forKey: "quickSettings.hiddenTiles") }
    }
    @Published var enabledQuickSettings: Set<String> = [
        "Finder Path Bar", "Show Extension", "True Tone"
    ]
    @Published var bluetoothEnabled = true
    @Published var vpnEnabled = false
    @Published var appVolume: Double = 0.52

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
        if let savedStatusPreset = defaults.string(forKey: "status.iconPreset").flatMap(StatusIconPreset.init(rawValue:)) {
            statusIconPreset = savedStatusPreset
        }
        if let savedCustomSymbol = defaults.string(forKey: "status.customSymbol"), !savedCustomSymbol.isEmpty {
            statusIconCustomSymbol = savedCustomSymbol
        }
        widgetOutlineBorder = defaults.object(forKey: "widgets.outlineBorder") == nil ? true : defaults.bool(forKey: "widgets.outlineBorder")
        if defaults.object(forKey: "widgets.outlineWidth") != nil {
            widgetOutlineWidth = max(0.5, min(3, CGFloat(defaults.double(forKey: "widgets.outlineWidth"))))
        }
        iconBackgroundVisible = defaults.object(forKey: "icons.backgroundVisible") == nil ? true : defaults.bool(forKey: "icons.backgroundVisible")
        if let savedIconShape = defaults.string(forKey: "icons.backgroundShape").flatMap(IconShape.init(rawValue:)) {
            iconBackgroundShape = savedIconShape
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
        if let savedIndicatorPreset = defaults.string(forKey: "taskbar.indicatorPreset").flatMap(IndicatorColorPreset.init(rawValue:)) {
            indicatorColorPreset = savedIndicatorPreset
        }
        if let values = defaults.array(forKey: "taskbar.indicatorGradientStart") as? [Double],
           let color = Color.fromStoredRGBA(values) {
            indicatorGradientStart = color
        }
        if let values = defaults.array(forKey: "taskbar.indicatorGradientEnd") as? [Double],
           let color = Color.fromStoredRGBA(values) {
            indicatorGradientEnd = color
        }
        if let savedClockPreset = defaults.string(forKey: "clock.colorPreset").flatMap(ClockColorPreset.init(rawValue:)) {
            clockColorPreset = savedClockPreset
        }
        clockGradientEnabled = defaults.bool(forKey: "clock.gradientEnabled")
        if let values = defaults.array(forKey: "clock.gradientStart") as? [Double],
           let color = Color.fromStoredRGBA(values) {
            clockGradientStart = color
        }
        if let values = defaults.array(forKey: "clock.gradientEnd") as? [Double],
           let color = Color.fromStoredRGBA(values) {
            clockGradientEnd = color
        }
        if let savedMinimizeMode = defaults.string(forKey: "taskbar.minimizeMode").flatMap(AppMinimizeMode.init(rawValue:)) {
            minimizeMode = savedMinimizeMode
        }
        if let savedMenuStyle = defaults.string(forKey: "taskbar.menuStyle").flatMap(ContextMenuStyle.init(rawValue:)) {
            contextMenuStyle = savedMenuStyle
        }
        if let savedFlyoutAnimation = defaults.string(forKey: "flyouts.animation").flatMap(FlyoutAnimation.init(rawValue:)) {
            flyoutAnimation = savedFlyoutAnimation
        }
        if let savedHeightPreset = defaults.string(forKey: "flyouts.heightPreset").flatMap(FlyoutHeightPreset.init(rawValue:)) {
            flyoutHeightPreset = savedHeightPreset
        }
        if defaults.object(forKey: "motion.reduced") != nil {
            reduceMotion = defaults.bool(forKey: "motion.reduced")
        }
        if let bindingData = defaults.data(forKey: "shortcuts.bindings"),
           let savedBindings = try? JSONDecoder().decode([ShortcutBinding].self, from: bindingData),
           !savedBindings.isEmpty {
            shortcutBindings = savedBindings
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

    func sampleTopProcessesIfNeeded() {
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
        do {
            let result = try ProcessRunner.run(
                executablePath: "/bin/ps",
                arguments: ["-axo", "comm,pcpu,rss"],
                timeout: 10
            )
            guard result.succeeded else { return (processes: [], total: 0) }
            let output = result.standardOutput
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

    func persist(key: String, value: Any) {
        pendingPersistenceWorkItems[key]?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            UserDefaults.standard.set(value, forKey: key)
            self?.pendingPersistenceWorkItems[key] = nil
        }
        pendingPersistenceWorkItems[key] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    func widgetSize(for widget: DashboardWidget) -> WidgetSizePreset {
        widgetSizes[widget] ?? widget.defaultSize
    }

    func panelWidth(for kind: PanelKind) -> CGFloat {
        panelWidths[kind] ?? kind.defaultWidth
    }

    func flyoutHeight(available: CGFloat) -> CGFloat {
        guard let target = flyoutHeightPreset.points else {
            return max(300, available)
        }
        return max(300, min(target, available))
    }

    func setPanelWidth(_ width: CGFloat, for kind: PanelKind) {
        panelWidths[kind] = min(kind.maximumWidth, max(kind.minimumWidth, width))
    }

    func setWidgetSize(_ size: WidgetSizePreset, for widget: DashboardWidget) {
        widgetSizes[widget] = size
    }

    func moveWidget(_ widget: DashboardWidget, before target: DashboardWidget) {
        guard widget != target, let sourceIndex = widgetOrder.firstIndex(of: widget) else { return }
        var updatedOrder = widgetOrder
        updatedOrder.remove(at: sourceIndex)
        let targetIndex = updatedOrder.firstIndex(of: target) ?? updatedOrder.endIndex
        updatedOrder.insert(widget, at: targetIndex)
        widgetOrder = updatedOrder
    }

    func setPinned(_ bundleID: String, isPinned: Bool) {
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

    func movePinned(_ bundleID: String, before targetBundleID: String) {
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

    func recordFolderOpen(_ title: String) {
        var updated = recentFolderTitles.filter { $0 != title }
        updated.insert(title, at: 0)
        recentFolderTitles = Array(updated.prefix(4))
    }

    func setOutputVolume(_ level: Double) {
        SystemStatusService.setOutputVolume(level)
        var snapshot = systemStatus
        snapshot.volumeLevel = min(1, max(0, level))
        systemStatus = snapshot
    }

    func setBluetoothDeviceConnected(_ connected: Bool, address: String) {
        systemStatusService.setBluetoothDeviceConnected(connected, address: address)
    }

    func resetPersonalisation() {
        surfaceStyle = .glassmorphism
        taskbarMode = .windows
        islandGap = 10
        centeredBarWidth = 720
        userDividers = []
        trashAnchors = [:]
        clusterOrder = ["downloads", "trash", "status"]
        isDarkMode = false
        wallpaperPreset = .pastelBloom
        pastelTint = Color(red: 0.91, green: 0.69, blue: 0.87)
        gradientEndTint = Color(red: 0.47, green: 0.70, blue: 0.86)
        gradientAngle = 35.0
        interfaceTransparency = 0.40
        usesTaskbarGradient = false
        taskbarGradientStart = Color(red: 0.78, green: 0.48, blue: 0.86)
        taskbarGradientEnd = Color(red: 0.96, green: 0.38, blue: 0.42)
        taskbarHeight = 46
        taskbarIconSize = .medium
        flyoutAnimation = .spring
        flyoutHeightPreset = .tall
        indicatorColorPreset = .auto
        indicatorGradientStart = .blue
        indicatorGradientEnd = .purple
        clockColorPreset = .auto
        clockGradientEnabled = false
        clockGradientStart = Color.roseAccent
        clockGradientEnd = .orange
        statusIconPreset = .batteryOnly
        statusIconCustomSymbol = "battery.75percent"
        widgetOutlineBorder = true
        widgetOutlineWidth = 1.0
        iconBackgroundVisible = true
        iconBackgroundShape = .roundedRect
        trashPlacement = .withApps
        panelWidths = [:]
    }
}


struct TopProcess: Equatable {
    let name: String
    let cpuPercent: Double
    let memoryMB: Double
}
