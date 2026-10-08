import SwiftUI

// MARK: - TaskbarTiles
//
// Tile factory + context menus for the taskbar. Moved verbatim from
// TaskbarStripViews.swift in the Phase-1 island split (HYBRID_PLAN A1).

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
    let reduceMotion: Bool

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
                        // G1: the pill springs in when an app launches.
                        .transition(.scale(scale: 0.3, anchor: .bottom).combined(with: .opacity))
                }
            },
            onActivate: { onTaskbarIconClick(bundleIdentifier) },
            menu: AnyView(tileContextMenu(bundleIdentifier)),
            onHoverChanged: { onHoverChanged(bundleIdentifier, $0) }
        )
        .animation(
            MotionTokens.spring(response: 0.3, dampingFraction: 0.6, reduceMotion: reduceMotion),
            value: isRunning
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
