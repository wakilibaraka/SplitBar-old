import SwiftUI

struct TaskbarWeatherSection: View {
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


struct TaskbarClockSection: View {
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
                    tint: model.resolvedClockTint,
                    height: model.taskbarHeight,
                    tintGradient: model.clockTintGradient
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
    @FocusState private var focusedTile: String?

    private var focusableAppIDs: [String] {
        visibleItems.compactMap {
            if case .app(let bundleID) = $0 { bundleID } else { nil }
        }
    }

    private var tiles: TaskbarTiles {
        TaskbarTiles(
            pinnedBundleIDs: model.pinnedAppBundleIDs,
            runningBundleIDs: model.runningBundleIDs,
            frontmostBundleID: model.frontmostBundleID,
            indicatorStyle: model.runningIndicatorStyle,
            indicatorSize: model.runningIndicatorSize,
            indicatorFill: model.resolvedIndicatorFill,
            menuStyle: model.contextMenuStyle,
            isDarkMode: model.isDarkMode,
            systemStatus: model.systemStatus,
            statusIconPreset: model.statusIconPreset,
            statusIconCustomSymbol: model.statusIconCustomSymbol,
            tileSide: max(28, model.taskbarHeight - 4),
            glyphSize: model.taskbarHeight * model.taskbarIconSize.glyphFraction,
            previewsEnabled: model.showWindowPreviews,
            previewBundleID: $model.previewBundleID,
            clusterOrder: model.clusterOrder,
            dividers: model.userDividers,
            onTaskbarIconClick: onTaskbarIconClick,
            onTaskbarTileAction: onTaskbarTileAction,
            onToggleControls: { model.openPanel = model.openPanel == .controls ? nil : .controls },
            onHoverChanged: model.handleTaskbarTileHover,
            onMovePinned: model.movePinned
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
                        .focused($focusedTile, equals: bundleID)
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
        .onMoveCommand { direction in
            let ids = focusableAppIDs
            guard !ids.isEmpty else { return }
            switch direction {
            case .left, .up:
                if let current = focusedTile, let index = ids.firstIndex(of: current) {
                    focusedTile = ids[max(index - 1, 0)]
                } else {
                    focusedTile = ids.last
                }
            case .right, .down:
                if let current = focusedTile, let index = ids.firstIndex(of: current) {
                    focusedTile = ids[min(index + 1, ids.count - 1)]
                } else {
                    focusedTile = ids.first
                }
            @unknown default:
                break
            }
        }
    }

    @ViewBuilder
    private func trayGroup(includeClock: Bool) -> some View {
        tiles.trashCluster
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


struct TaskbarTiles {
    let pinnedBundleIDs: [String]
    let runningBundleIDs: Set<String>
    let frontmostBundleID: String?
    let indicatorStyle: RunningIndicatorStyle
    let indicatorSize: RunningIndicatorSize
    let indicatorFill: IndicatorFill
    let menuStyle: ContextMenuStyle
    let isDarkMode: Bool
    let systemStatus: SystemStatusSnapshot
    let statusIconPreset: StatusIconPreset
    let statusIconCustomSymbol: String
    let tileSide: CGFloat
    let glyphSize: CGFloat
    let previewsEnabled: Bool
    var previewBundleID: Binding<String?>
    let clusterOrder: [String]
    let dividers: [TaskbarDivider]
    let onTaskbarIconClick: (String) -> Void
    let onTaskbarTileAction: (TaskbarTileAction) -> Void
    let onToggleControls: () -> Void
    let onHoverChanged: (String, Bool) -> Void
    let onMovePinned: (String, String) -> Void

    func taskbarAppTile(_ bundleIdentifier: String) -> some View {
        let app = LauncherDefaults.apps.first { $0.bundleIdentifier == bundleIdentifier }
        let title = taskbarDisplayName(for: bundleIdentifier)
        let isRunning = runningBundleIDs.contains(bundleIdentifier)
        let isFrontmost = frontmostBundleID == bundleIdentifier
        let windowCount = isRunning ? AppWindowPreviewService().windows(forBundleIdentifier: bundleIdentifier, appName: title).count : 0
        return AppTile(
            title: title,
            icon: MacOSAppIcon(
                bundleIdentifier: bundleIdentifier,
                fallbackSymbol: app?.symbol ?? "app.fill",
                fallbackColor: app?.color ?? .secondary,
                size: glyphSize
            )
            .frame(width: tileSide, height: tileSide)
            .taskbarTile(highlighted: isRunning && indicatorStyle == .highlight, highlightFill: indicatorFill),
            indicator: Group {
                if isRunning, indicatorStyle != .highlight {
                    runningIndicator(isFrontmost: isFrontmost, windowCount: windowCount)
                        .padding(.bottom, 4)
                }
            },
            onActivate: { onTaskbarIconClick(bundleIdentifier) },
            menu: AnyView(tileContextMenu(bundleIdentifier)),
            onHoverChanged: { onHoverChanged(bundleIdentifier, $0) }
        )
        .overlay(alignment: .topTrailing) {
            if windowCount > 1 {
                Text("\(min(windowCount, 9))")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 15, height: 15)
                    .background(Circle().fill(Color.red))
                    .offset(x: 3, y: -3)
                    .accessibilityLabel("\(windowCount) windows open")
            }
        }
        .draggable(bundleIdentifier)
        .dropDestination(for: String.self) { droppedItems, _ in
            guard let draggedID = droppedItems.first, draggedID != bundleIdentifier else { return false }
            onMovePinned(draggedID, bundleIdentifier)
            return true
        }
    }

    private func runningIndicator(isFrontmost: Bool, windowCount: Int = 0) -> some View {
        let opacity = isFrontmost ? 1.0 : 0.55
        let multiWindow = windowCount > 1 && !isFrontmost
        return Group {
            switch indicatorStyle {
            case .dot:
                if isFrontmost {
                    Capsule()
                        .fill(indicatorFill.style(opacity: opacity))
                        .frame(width: max(indicatorSize.dotDiameter + 8, 12), height: 4)
                } else if multiWindow {
                    ZStack {
                        Capsule()
                            .fill(indicatorFill.style(opacity: opacity))
                            .frame(width: max(indicatorSize.dotDiameter + 8, 12), height: 4)
                            .offset(x: 2.5, y: -2.5)
                        Capsule()
                            .fill(indicatorFill.style(opacity: opacity))
                            .frame(width: max(indicatorSize.dotDiameter + 8, 12), height: 4)
                            .offset(x: -2.5, y: 2.5)
                    }
                } else {
                    Capsule()
                        .fill(indicatorFill.style(opacity: opacity))
                        .frame(width: max(indicatorSize.dotDiameter, 8), height: 4)
                }
            case .dash:
                Capsule()
                    .fill(indicatorFill.style(opacity: opacity))
                    .frame(width: indicatorSize.dashWidth + (isFrontmost ? 6 : 0), height: indicatorSize.dashHeight)
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
        if isRunning {
            Divider()
            Button("Hide") {
                onTaskbarTileAction(.hideApp(bundleID: bundleIdentifier))
            }
            Button("Quit") {
                onTaskbarTileAction(.quitApp(bundleID: bundleIdentifier))
            }
        }
        dividerMenu(for: bundleIdentifier)
    }

    @ViewBuilder
    private func dividerMenu(for bundleIdentifier: String) -> some View {
        Divider()
        Menu("Divider") {
            Button(hasDividerAfter(bundleIdentifier) ? "Remove divider here" : "Add divider after this app") {
                if hasDividerAfter(bundleIdentifier) {
                    onTaskbarTileAction(.removeDivider(afterBundleID: bundleIdentifier))
                } else {
                    onTaskbarTileAction(.addDivider(afterBundleID: bundleIdentifier))
                }
            }
            if !dividers.isEmpty {
                Menu("Move divider to here") {
                    ForEach(Array(dividers.enumerated()), id: \.element.id) { index, divider in
                        Button("Divider \(index + 1)") {
                            onTaskbarTileAction(.moveDivider(id: divider.id, afterBundleID: bundleIdentifier))
                        }
                    }
                }
            }
        }
    }

    private func hasDividerAfter(_ bundleIdentifier: String) -> Bool {
        dividers.contains { $0.anchorBundleID == bundleIdentifier }
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
        dividerMenu(for: bundleIdentifier)
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
                SystemStatusIcon(
                    snapshot: systemStatus,
                    glyphSize: glyphSize,
                    preset: statusIconPreset,
                    customSymbol: statusIconCustomSymbol
                )
                    .frame(width: tileSide, height: tileSide)
                    .taskbarTile()
            }
            .buttonStyle(.plain)
            .help("Open quick controls, volume, Bluetooth and battery")
        }
    }

}


struct Taskbar: View {
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
    private var appTileCount: Int {
        model.pinnedAppBundleIDs.count + model.runningAppOrder.filter { !model.pinnedAppBundleIDs.contains($0) }.count
    }

    private var tiles: TaskbarTiles {
        TaskbarTiles(
            pinnedBundleIDs: model.pinnedAppBundleIDs,
            runningBundleIDs: model.runningBundleIDs,
            frontmostBundleID: model.frontmostBundleID,
            indicatorStyle: model.runningIndicatorStyle,
            indicatorSize: model.runningIndicatorSize,
            indicatorFill: model.resolvedIndicatorFill,
            menuStyle: model.contextMenuStyle,
            isDarkMode: model.isDarkMode,
            systemStatus: model.systemStatus,
            statusIconPreset: model.statusIconPreset,
            statusIconCustomSymbol: model.statusIconCustomSymbol,
            tileSide: tileSide,
            glyphSize: glyphSize,
            previewsEnabled: model.showWindowPreviews,
            previewBundleID: $model.previewBundleID,
            clusterOrder: model.clusterOrder,
            dividers: model.userDividers,
            onTaskbarIconClick: onTaskbarIconClick,
            onTaskbarTileAction: onTaskbarTileAction,
            onToggleControls: { toggle(.controls) },
            onHoverChanged: model.handleTaskbarTileHover,
            onMovePinned: model.movePinned
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
            .frame(width: isConstrained ? (mode == .centered ? TaskbarStripMetrics.centeredFrameWidth(userWidth: model.centeredBarWidth, barHeight: height, appCount: appTileCount, availableWidth: geometry.size.width) : min(geometry.size.width, model.centeredBarWidth)) : nil)
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
        } else if model.surfaceStyle == .windowsAero {
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
            let fill: AnyShapeStyle = {
                switch model.surfaceStyle {
                case .windowsXP:
                    return AnyShapeStyle(LinearGradient(
                        colors: [Color(red: 0.15, green: 0.44, blue: 0.88), Color(red: 0.04, green: 0.22, blue: 0.61)],
                        startPoint: .top, endPoint: .bottom
                    ))
                case .aqua:
                    return AnyShapeStyle(LinearGradient(
                        colors: [Color(red: 0.30, green: 0.65, blue: 0.96), Color(red: 0.10, green: 0.40, blue: 0.88)],
                        startPoint: .top, endPoint: .bottom
                    ))
                case .frutigerAero:
                    return AnyShapeStyle(LinearGradient(
                        colors: [Color(red: 0.42, green: 0.78, blue: 0.96), Color(red: 0.18, green: 0.62, blue: 0.82)],
                        startPoint: .top, endPoint: .bottom
                    ))
                case .y2k:
                    return AnyShapeStyle(LinearGradient(
                        colors: [Color(red: 0.72, green: 0.82, blue: 1.0), Color(red: 0.44, green: 0.60, blue: 0.96)],
                        startPoint: .top, endPoint: .bottom
                    ))
                default:
                    return AnyShapeStyle(model.surfaceStyle.taskbarFill(darkMode: model.isDarkMode))
                }
            }()
            Rectangle()
                .fill(fill)
                .overlay(alignment: .top) {
                    if model.surfaceStyle == .neobrutalism {
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: 3)
                    } else {
                        Rectangle()
                            .fill(Color.white.opacity(0.42))
                            .frame(height: 1)
                    }
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


struct TaskbarSplitRow: View {
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


struct TaskbarClockDisplay: View {
    let date: Date
    let style: ClockDisplayStyle
    let dateStyle: ClockDateStyle
    let uses24HourTime: Bool
    let showsSeconds: Bool
    let tint: Color
    let height: CGFloat
    var tintGradient: LinearGradient? = nil

    private var time: String {
        clockTime(date, uses24HourTime: uses24HourTime, showsSeconds: showsSeconds)
    }

    private var textStyle: AnyShapeStyle {
        if let tintGradient {
            return AnyShapeStyle(tintGradient)
        }
        return AnyShapeStyle(tint)
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
                        .foregroundStyle(textStyle)
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
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var timeLabel: some View {
        Text(time)
            .font(.system(size: height * (style == .digital ? 0.32 : 0.27), weight: .semibold, design: .rounded))
            .foregroundStyle(textStyle)
            .lineLimit(1)
    }

    private var dateLabel: some View {
        Text(dateStyle.string(from: date))
            .font(.system(size: height * 0.20, weight: .medium))
            .foregroundStyle(textStyle)
            .lineLimit(1)
    }
}


struct AnalogClockFace: View {
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
