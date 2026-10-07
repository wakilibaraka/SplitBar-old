import AppKit
import Combine
import CoreGraphics
import Foundation
import OSLog
import SwiftUI
import UniformTypeIdentifiers

private struct AddItemViewHostingContainer: View {
    let applications: [ApplicationDescriptor]
    @State private var addState: AddItemState
    let onAddApplication: (ApplicationDescriptor) -> Void
    let onAddLink: (String) -> Void
    let onAddWidget: (String, String) -> Void
    let onClose: () -> Void

    init(
        applications: [ApplicationDescriptor],
        initialState: AddItemState,
        onAddApplication: @escaping (ApplicationDescriptor) -> Void,
        onAddLink: @escaping (String) -> Void,
        onAddWidget: @escaping (String, String) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.applications = applications
        self._addState = State(initialValue: initialState)
        self.onAddApplication = onAddApplication
        self.onAddLink = onAddLink
        self.onAddWidget = onAddWidget
        self.onClose = onClose
    }

    var body: some View {
        AddItemView(
            applications: applications,
            state: addState,
            onAction: { action in
                addState = reduceAddItem(state: addState, action: action)
            },
            onAddApplication: onAddApplication,
            onAddLink: onAddLink,
            onAddWidget: onAddWidget,
            onClose: onClose
        )
    }
}

private struct DockInteractiveContainerView: View {
    let state: AppState
    let preferences: AppPreferences
    let config: DockMagnificationConfiguration
    let weatherState: WeatherState?
    let aiUsageState: AIUsageState?
    let systemMetrics: SystemMetrics?
    let nowPlayingState: NowPlayingState?
    let onAction: (AppAction) -> Void
    let onOpenAddPanel: () -> Void
    let onSelectTheme: (DockMaterialStyle) -> Void
    let onToggleAutoHide: () -> Void
    let onShowAppWindows: (String, String, URL?) -> Void
    let onHoverItem: (DockItemViewState?, CGPoint?) -> Void
    let onUpdateIconSize: (Double) -> Void
    @State private var pointerLocation: CGPoint?
    @State private var itemFrames: [DockItemGeometry] = []
    @State private var autoHideTimer: DispatchWorkItem?

    var body: some View {
        let viewState = makeDockViewState(
            state: state,
            pointer: pointerLocation,
            itemFrames: itemFrames,
            configuration: config,
            weatherState: weatherState,
            aiUsageState: aiUsageState,
            systemMetrics: systemMetrics,
            nowPlayingState: nowPlayingState
        )
        EdgeDockView(
            viewState: viewState,
            materialStyle: preferences.materialStyle,
            reduceMotion: preferences.reduceMotion,
            autoHide: preferences.placement.autoHide,
            iconBaseSize: CGFloat(preferences.dockIconSize),
            onAction: onAction,
            onOpenAddPanel: onOpenAddPanel,
            onSelectTheme: onSelectTheme,
            onToggleAutoHide: onToggleAutoHide,
            onShowAppWindows: onShowAppWindows,
            onUpdateIconSize: onUpdateIconSize
        )
        .coordinateSpace(name: "DockContainer")
        .contentShape(Rectangle())
        .onPreferenceChange(DockItemFramesPreferenceKey.self) { preferences in
            let geometries = preferences.map { pref in
                DockItemGeometry(id: pref.id, logicalFrame: pref.frame)
            }
            if self.itemFrames != geometries {
                self.itemFrames = geometries
            }
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                autoHideTimer?.cancel()
                autoHideTimer = nil
                withAnimation(preferences.reduceMotion ? .easeOut(duration: 0.1) : .interactiveSpring(response: 0.16, dampingFraction: 0.82)) {
                    pointerLocation = location
                }
                let hoveredItem = viewState.items.min(by: { a, b in
                    let distA = hypot(location.x - a.transform.logicalFrame.midX, location.y - a.transform.logicalFrame.midY)
                    let distB = hypot(location.x - b.transform.logicalFrame.midX, location.y - b.transform.logicalFrame.midY)
                    return distA < distB
                })
                if let item = hoveredItem {
                    let center = CGPoint(x: item.transform.logicalFrame.midX, y: item.transform.logicalFrame.midY)
                    let dist = hypot(location.x - center.x, location.y - center.y)
                    if dist < 42.0 {
                        onHoverItem(item, center)
                    } else {
                        onHoverItem(nil, nil)
                    }
                } else {
                    onHoverItem(nil, nil)
                }
            case .ended:
                withAnimation(preferences.reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.25, dampingFraction: 0.8)) {
                    pointerLocation = nil
                }
                onHoverItem(nil, nil)
                if preferences.placement.autoHide && !state.flyout.isVisible {
                    let task = DispatchWorkItem {
                        onAction(.hideDock)
                    }
                    autoHideTimer = task
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65, execute: task)
                }
            }
        }
    }
}

@MainActor
public final class AppRuntimeController {
    public private(set) var state: AppState
    public private(set) var preferences: AppPreferences
    public let screenService: ScreenService
    public let launchService: AppLaunchService
    public let catalogService: ApplicationCatalogService
    public let shortcutService: GlobalShortcutService
    let clipboardCoordinator: ClipboardCoordinator
    public let panelController: EdgePanelController
    public let flyoutController: FlyoutPanelController
    private var dockHostingView: NSHostingView<DockInteractiveContainerView>?
    private var latestSystemMetrics: SystemMetrics?
    public let configPersistence: ConfigurationPersistence
    public let systemMonitorService: SystemMonitorService
    public let windowPreviewService: AppWindowPreviewService
    public let nowPlayingService: NowPlayingService
    public let weatherService: WeatherService
    public let bluetoothService: BluetoothService
    public let aiUsageService: AIUsageService
    public let windowManagerService: WindowManagerService
    public let launchAtLoginService: LaunchAtLoginService
    public let quickNotesService: QuickNotesService
    public let dockController: DockController
    public let tooltipController: DockTooltipPanelController
    public private(set) var statusBarController: StatusBarController?
    public let magnificationConfiguration: DockMagnificationConfiguration
    private var addItemPanel: NSPanel?
    private var addPanelGlobalMonitor: Any?
    private var addPanelLocalMonitor: Any?
    private var flyoutGlobalMonitor: Any?
    private var flyoutLocalMonitor: Any?
    private var detailedSystemMonitorWindow: NSWindow?
    private var isStreamingCadenceRefreshing = false
    private var currentMetricsInterval: TimeInterval = 15.0
    private var currentAIUsageInterval: TimeInterval = 60.0
    private var currentPlaybackInterval: TimeInterval = 10.0
    private var taskbarConceptWindow: NSWindow?
    private let taskbarConceptState = TaskbarConceptState()
    private let taskbarPanelController = TaskbarPanelController()
    private let displayCoordinator = DisplayCoordinator()
    private let taskbarFlyoutController = FlyoutPanelController()
    private let windowPreviewController = FlyoutPanelController()
    private var taskbarFlyoutKindShown: OpenPanel?
    private var taskbarFlyoutLocalMonitor: Any?
    private var taskbarFlyoutGlobalMonitor: Any?
    private var taskbarPanelSubscriptions = Set<AnyCancellable>()
    private var isLegacyEdgeDockEnabled = false
    private var settingsWindow: NSWindow?
    private var detailedMonitorHostingView: NSHostingView<DetailedSystemMonitorView>?
    private var settingsHostingView: NSHostingView<SettingsView>?
    private var commandPalettePanel: NSPanel?
    private var commandPaletteGlobalMonitor: Any?
    private var commandPaletteLocalMonitor: Any?

    public init(
        initialState: AppState,
        preferences: AppPreferences,
        screenService: ScreenService,
        launchService: AppLaunchService,
        catalogService: ApplicationCatalogService,
        shortcutService: GlobalShortcutService,
        flyoutController: FlyoutPanelController,
        clipboardPersistence: ClipboardPersistence,
        clipboardMonitor: ClipboardMonitor,
        configPersistence: ConfigurationPersistence,
        systemMonitorService: SystemMonitorService,
        nowPlayingService: NowPlayingService,
        weatherService: WeatherService,
        bluetoothService: BluetoothService,
        aiUsageService: AIUsageService,
        windowManagerService: WindowManagerService,
        launchAtLoginService: LaunchAtLoginService,
        quickNotesService: QuickNotesService,
        dockController: DockController
    ) {
        self.state = initialState
        self.preferences = preferences
        self.screenService = screenService
        self.launchService = launchService
        self.catalogService = catalogService
        self.shortcutService = shortcutService
        self.flyoutController = flyoutController
        self.clipboardCoordinator = ClipboardCoordinator(
            monitor: clipboardMonitor,
            persistence: clipboardPersistence
        )
        self.configPersistence = configPersistence
        self.systemMonitorService = systemMonitorService
        self.windowPreviewService = AppWindowPreviewService()
        self.nowPlayingService = nowPlayingService
        self.weatherService = weatherService
        self.bluetoothService = bluetoothService
        self.aiUsageService = aiUsageService
        self.windowManagerService = windowManagerService
        self.launchAtLoginService = launchAtLoginService
        self.quickNotesService = quickNotesService
        self.dockController = dockController
        self.tooltipController = DockTooltipPanelController()
        self.magnificationConfiguration = DockMagnificationConfiguration(
            maxScale: 1.35,
            influenceRadius: 75.0,
            maxLift: 0.0
        )

        weak var controllerRef: AppRuntimeController?
        let panel = EdgePanelController(onReveal: {
            controllerRef?.dispatch(action: .revealDock)
        })
        self.panelController = panel
        controllerRef = self

        weak var statusSelf: AppRuntimeController?
        let statusBar = StatusBarController(
            onToggleDock: {
                statusSelf?.toggleDockVisibility()
            },
            onOpenCommandPalette: {
                statusSelf?.openCommandPalette()
            },
            onOpenTaskbarPreview: {
                statusSelf?.openTaskbarConceptWindow()
            },
            onToggleTaskbarPanel: {
                statusSelf?.toggleTaskbarPanel()
            },
            isTaskbarPanelShown: { [weak self] in
                self?.taskbarConceptState.showsTaskbarPanel == true
            },
            onOpenSystemMonitor: {
                statusSelf?.openDetailedSystemMonitor()
            },
            onOpenSettings: {
                statusSelf?.openSettingsWindow()
            },
            onChangeEdge: { [weak self] newEdge in
                guard let self = self else { return }
                self.dispatch(action: .updatePlacement(DockPlacement(edge: newEdge, verticalOffsetFraction: 0.5, autoHide: self.preferences.placement.autoHide)))
            },
            onToggleAutoHide: { [weak self] in
                guard let self = self else { return }
                let current = self.preferences.placement.autoHide
                let newPlacement = DockPlacement(
                    edge: self.preferences.placement.edge,
                    verticalOffsetFraction: self.preferences.placement.verticalOffsetFraction,
                    autoHide: !current
                )
                self.dispatch(action: .updatePlacement(newPlacement))
            },
            onSelectTheme: { [weak self] newTheme in
                guard let self = self else { return }
                var updated = self.preferences
                updated.materialStyle = newTheme
                self.updatePreferences(updated)
            },
            onExportBackup: {
                statusSelf?.promptExportConfiguration()
            },
            onImportBackup: {
                statusSelf?.promptImportConfiguration()
            },
            onQuitAndRestore: { [weak self] in
                self?.dockController.setHidden(false)
                NSApp.terminate(nil)
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        self.statusBarController = statusBar
        statusSelf = self

        self.clipboardCoordinator.historyDidChange = { [weak self] change in
            guard let self else { return }
            switch change {
            case .captured:
                if self.state.flyout.isVisible, let activeID = self.state.flyout.activeItemID {
                    self.syncFlyout(activeItemID: activeID)
                }
            case .edited:
                if let activeID = self.state.flyout.activeItemID {
                    self.syncFlyout(activeItemID: activeID)
                }
            }
        }

        self.updateDockContent()
        self.syncPanels()
        self.setupDefaultShortcuts()
        self.setupTaskbarPanel()
        self.setupRunningState()
        self.setupWeatherForwarding()
        self.installPrivacyGateBridge()
        self.clipboardCoordinator.refreshMonitoring(for: preferences.clipboardSettings)
        self.setupLiveStreaming()
        Logger.lifecycle.info("AppRuntimeController initialized")
        openTaskbarConceptWindow()
    }

    public var isLaunchAtLoginEnabled: Bool {
        return launchAtLoginService.isEnabled
    }

    public func setLaunchAtLogin(enabled: Bool) {
        _ = launchAtLoginService.setEnabled(enabled)
        // Başarısız olursa anahtar gerçek duruma geri döner (hata servis tarafından loglanır)
        refreshSettingsWindow()
    }

    /// Ayarlar penceresini açar. `showSettingsWindow:` seçicisi macOS 14+ sürümlerinde SwiftUI Settings
    /// sahnesini açmadığı için pencere doğrudan yönetilir.
    public func openSettingsWindow() {
        let window: NSWindow
        if let existing = settingsWindow {
            window = existing
            refreshSettingsWindow()
        } else {
            let hostingView = NSHostingView(rootView: makeSettingsView())
            window = NSWindow(
                contentRect: NSRect(x: 0.0, y: 0.0, width: 780.0, height: 520.0),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "SplitBar Settings"
            window.isReleasedWhenClosed = false
            window.contentView = hostingView
            window.center()
            self.settingsWindow = window
            self.settingsHostingView = hostingView
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func setupTaskbarPanel() {
        taskbarPanelController.onFullscreenBegan = { [weak self] in
            self?.taskbarConceptState.openPanel = nil
            self?.taskbarConceptState.previewBundleID = nil
        }
        taskbarConceptState.$showsTaskbarPanel
            .removeDuplicates()
            .sink { [weak self] showsPanel in
                guard let self else { return }
                if showsPanel {
                    self.showTaskbarPanel()
                } else {
                    self.taskbarPanelController.hide()
                    self.taskbarConceptState.previewBundleID = nil
                }
                self.syncTaskbarFlyout(self.taskbarConceptState.openPanel)
            }
            .store(in: &taskbarPanelSubscriptions)
        taskbarConceptState.$taskbarHeight
            .removeDuplicates()
            .sink { [weak self] height in
                self?.taskbarPanelController.updateHeight(height)
            }
            .store(in: &taskbarPanelSubscriptions)
        taskbarConceptState.$taskbarMode
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.taskbarPanelController.refresh()
            }
            .store(in: &taskbarPanelSubscriptions)
        taskbarConceptState.$islandGap
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.taskbarPanelController.refresh()
            }
            .store(in: &taskbarPanelSubscriptions)
        taskbarConceptState.$pinnedAppBundleIDs
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.taskbarPanelController.refresh()
            }
            .store(in: &taskbarPanelSubscriptions)
        taskbarConceptState.$runningAppOrder
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.taskbarPanelController.refresh()
            }
            .store(in: &taskbarPanelSubscriptions)
        taskbarConceptState.$flyoutHeightPreset
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self, self.taskbarConceptState.openPanel != nil else { return }
                self.syncTaskbarFlyout(self.taskbarConceptState.openPanel)
            }
            .store(in: &taskbarPanelSubscriptions)
        taskbarConceptState.$openPanel
            .removeDuplicates()
            .sink { [weak self] panel in
                self?.syncTaskbarFlyout(panel)
            }
            .store(in: &taskbarPanelSubscriptions)
        taskbarConceptState.$previewBundleID
            .removeDuplicates()
            .sink { [weak self] bundleID in
                self?.syncWindowPreview(bundleID)
            }
            .store(in: &taskbarPanelSubscriptions)
        if taskbarConceptState.showsTaskbarPanel {
            showTaskbarPanel()
        }
    }

    private func showTaskbarPanel() {
        taskbarPanelController.show(provider: { [weak self] in
            guard let self else {
                return TaskbarPanelRequest(
                    strip: AnyView(EmptyView()),
                    islandContent: { _, _ in AnyView(EmptyView()) }
                )
            }
            return self.taskbarPanelRequest()
        })
    }

    private func taskbarPanelRequest() -> TaskbarPanelRequest {
        let content = TaskbarPanelContentView(
            model: taskbarConceptState,
            onLaunchApplication: { [weak self] bundleIdentifier in
                self?.launchPinnedApplication(bundleIdentifier: bundleIdentifier)
            },
            onTaskbarIconClick: { [weak self] bundleIdentifier in
                self?.handleTaskbarIconClick(bundleIdentifier: bundleIdentifier)
            },
            onTaskbarTileAction: { [weak self] action in
                self?.handleTaskbarTileAction(action)
            }
        )
        let mode = taskbarConceptState.taskbarMode
        let screenWidth = displayCoordinator.panelScreenWidth()
        let appCount = taskbarConceptState.pinnedAppBundleIDs.count
            + taskbarConceptState.runningAppOrder
                .filter({ !taskbarConceptState.pinnedAppBundleIDs.contains($0) }).count
        let islands = mode.isSplit
            ? TaskbarStripMetrics.layout(
                screenWidth: screenWidth,
                mode: mode,
                barHeight: taskbarConceptState.taskbarHeight,
                gap: taskbarConceptState.islandGap,
                appCount: appCount
            )
            : nil
        let radius = taskbarConceptState.shellRadius(for: .taskbar)
        return TaskbarPanelRequest(
            strip: AnyView(content),
            islands: islands,
            islandContent: { [weak self] _, sections in
                guard let self else { return AnyView(EmptyView()) }
                return AnyView(
                    TaskbarIslandContent(
                        sections: sections,
                        model: self.taskbarConceptState,
                        onLaunchApplication: { [weak self] in self?.launchPinnedApplication(bundleIdentifier: $0) },
                        onTaskbarIconClick: { [weak self] in self?.handleTaskbarIconClick(bundleIdentifier: $0) },
                        onTaskbarTileAction: { [weak self] in self?.handleTaskbarTileAction($0) },
                        maxAppTiles: islands?.visibleAppTiles,
                        showOverflowChevron: islands?.showsOverflow ?? false
                    )
                    .padding(.horizontal, 10)
                    .background {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: radius, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.38), lineWidth: 1)
                            }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                )
            }
        )
    }

    public func toggleTaskbarPanel() {
        taskbarConceptState.showsTaskbarPanel.toggle()
    }

    private func syncWindowPreview(_ bundleID: String?) {
        guard taskbarConceptState.showsTaskbarPanel,
              taskbarConceptState.showWindowPreviews,
              let bundleID
        else {
            windowPreviewController.hide()
            return
        }
        let appTitle = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID })?.localizedName ?? bundleID
        let service = AppWindowPreviewService()
        let windows = service.windows(forBundleIdentifier: bundleID, appName: appTitle)
        guard !windows.isEmpty,
              let screen = screenService.primaryScreen(),
              let stripFrame = taskbarPanelController.currentFrame
        else {
            windowPreviewController.hide()
            return
        }
        let width: CGFloat = 400
        let height = min(480, CGFloat(110 + windows.prefix(6).count * 92))
        let frame = flyoutPanelFrame(
            anchorFrame: stripFrame,
            screen: screen,
            edge: .bottom,
            flyoutSize: CGSize(width: min(width, screen.visibleFrame.width - 32), height: height),
            gap: 12
        )
        let content = WindowPreviewContent(
            bundleID: bundleID,
            appTitle: appTitle,
            windows: Array(windows.prefix(6)),
            surfaceStyle: taskbarConceptState.surfaceStyle,
            onSelectWindow: { [weak self] info in
                if self?.windowManagerService.raiseWindow(info) != true {
                    service.focusWindow(info: info, bundleIdentifier: bundleID)
                }
                self?.taskbarConceptState.previewBundleID = nil
            },
            onClose: { [weak self] in
                self?.taskbarConceptState.previewBundleID = nil
            },
            cornerRadius: taskbarConceptState.shellRadius(for: .flyouts)
        )
        if windowPreviewController.panel.isVisible {
            windowPreviewController.replace(content: AnyView(content), frame: frame)
        } else {
            windowPreviewController.show(content: AnyView(content), frame: frame)
        }
    }

    private func syncTaskbarFlyout(_ panel: OpenPanel?) {
        if panel != nil {
            taskbarConceptState.previewBundleID = nil
        }
        guard taskbarConceptState.showsTaskbarPanel else {
            closeTaskbarFlyout()
            return
        }
        guard let panel else {
            closeTaskbarFlyout()
            return
        }
        guard let frame = taskbarFlyoutFrame(for: panel) else {
            closeTaskbarFlyout()
            return
        }
        let content = TaskbarFlyoutContentView(
            panel: panel,
            model: taskbarConceptState,
            onLaunchApplication: { [weak self] bundleIdentifier in
                self?.launchPinnedApplication(bundleIdentifier: bundleIdentifier)
            },
            onClose: { [weak self] in
                self?.taskbarConceptState.openPanel = nil
            }
        )
        if taskbarFlyoutKindShown == panel, taskbarFlyoutController.panel.isVisible {
            taskbarFlyoutController.replace(content: AnyView(content), frame: frame)
        } else {
            taskbarFlyoutController.show(content: AnyView(content), frame: frame)
            taskbarFlyoutKindShown = panel
        }
        setupTaskbarFlyoutDismissal()
    }

    private func taskbarFlyoutFrame(for panel: OpenPanel) -> CGRect? {
        guard let screen = screenService.primaryScreen() else { return nil }
        let kind = panel.panelKind
        let width = min(taskbarConceptState.panelWidth(for: kind), screen.visibleFrame.width - 32)
        let stripHeight = taskbarPanelController.currentFrame?.height ?? taskbarConceptState.taskbarHeight
        let height = taskbarConceptState.flyoutHeight(available: screen.visibleFrame.height - stripHeight - 48)
        let stripFrame = taskbarPanelController.currentFrame ?? edgeActivationFrame(
            screen: screen,
            edge: .bottom,
            thickness: stripHeight
        )
        var frame = flyoutPanelFrame(
            anchorFrame: stripFrame,
            screen: screen,
            edge: .bottom,
            flyoutSize: CGSize(width: width, height: max(300, height)),
            gap: 12
        )
        switch panel {
        case .widgets:
            frame.origin.x = screen.visibleFrame.minX + 14
        case .calendar, .controls:
            frame.origin.x = screen.visibleFrame.maxX - width - 14
        case .start, .settings:
            break
        }
        return frame
    }

    private func setupTaskbarFlyoutDismissal() {
        if taskbarFlyoutLocalMonitor == nil {
            taskbarFlyoutLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                guard let self else { return event }
                if event.keyCode == 53, self.taskbarFlyoutController.panel.isVisible {
                    self.taskbarConceptState.openPanel = nil
                    return nil
                }
                return event
            }
        }
        if taskbarFlyoutGlobalMonitor == nil {
            taskbarFlyoutGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    let location = NSEvent.mouseLocation
                    let inFlyout = self.taskbarFlyoutController.panel.isVisible
                        && self.taskbarFlyoutController.panel.frame.contains(location)
                    let stripFrame = self.taskbarPanelController.currentFrame ?? .zero
                    if !inFlyout, !stripFrame.contains(location) {
                        self.taskbarConceptState.openPanel = nil
                    }
                }
            }
        }
    }

    private func closeTaskbarFlyout() {
        taskbarFlyoutKindShown = nil
        taskbarFlyoutController.hide()
        if let monitor = taskbarFlyoutLocalMonitor {
            NSEvent.removeMonitor(monitor)
            taskbarFlyoutLocalMonitor = nil
        }
        if let monitor = taskbarFlyoutGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            taskbarFlyoutGlobalMonitor = nil
        }
    }

    public func openTaskbarConceptWindow() {
        let window: NSWindow
        if let existing = taskbarConceptWindow {
            window = existing
        } else {
            let conceptView = TaskbarConceptView(
                model: taskbarConceptState,
                onLaunchApplication: { [weak self] bundleIdentifier in
                    self?.launchPinnedApplication(bundleIdentifier: bundleIdentifier)
                },
                onTaskbarIconClick: { [weak self] bundleIdentifier in
                    self?.handleTaskbarIconClick(bundleIdentifier: bundleIdentifier)
                },
                onTaskbarTileAction: { [weak self] action in
                    self?.handleTaskbarTileAction(action)
                }
            )
            let hostingView = NSHostingView(rootView: conceptView)
            hostingView.sizingOptions = []
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1440, height: 920),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "SplitBar Taskbar Preview"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 1080, height: 700)
            window.contentView = hostingView
            window.center()
            taskbarConceptWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func launchPinnedApplication(bundleIdentifier: String) {
        taskbarConceptState.recordLaunch(bundleIdentifier)
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            Logger.lifecycle.error("Pinned application is not installed bundle=\(bundleIdentifier, privacy: .private)")
            let alert = NSAlert()
            alert.messageText = "Application Not Found"
            alert.informativeText = "The application \(bundleIdentifier) could not be found on this Mac."
            alert.alertStyle = .warning
            alert.runModal()
            return
        }

        launchTarget(.application(bundleIdentifier: bundleIdentifier, url: appURL))
    }

    private func launchTarget(_ target: LaunchTarget) {
        Task { [weak self] in
            guard let self else { return }
            let result = await self.launchService.launch(target: target)
            self.presentLaunchResult(result, target: target)
        }
    }

    private func presentLaunchResult(_ result: LaunchResult, target: LaunchTarget) {
        guard result != .launched else { return }
        let targetName: String
        switch target {
        case .application(let bundleIdentifier, _):
            targetName = bundleIdentifier
        case .link(let url):
            targetName = url.absoluteString
        }

        let message: String
        switch result {
        case .launched:
            return
        case .invalidTarget:
            message = "The launch target is invalid."
            Logger.lifecycle.error("Launch target is invalid target=\(targetName, privacy: .private)")
        case .systemFailure(let detail):
            message = detail
            Logger.lifecycle.error("Launch failed target=\(targetName, privacy: .private) error=\(detail, privacy: .private)")
        }

        let alert = NSAlert()
        alert.messageText = "Could Not Open Item"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func refreshSettingsWindow() {
        settingsHostingView?.rootView = makeSettingsView()
    }

    private func makeSettingsView() -> SettingsView {
        SettingsView(
            preferences: preferences,
            isLaunchAtLoginEnabled: isLaunchAtLoginEnabled,
            onUpdatePreferences: { [weak self] updated in
                self?.updatePreferences(updated)
            },
            onToggleLaunchAtLogin: { [weak self] enabled in
                self?.setLaunchAtLogin(enabled: enabled)
            }
        )
    }

    public func toggleDockVisibility() {
        if !isLegacyEdgeDockEnabled {
            isLegacyEdgeDockEnabled = true
            dispatch(action: .revealDock)
        } else if state.isDockRevealed {
            dispatch(action: .hideDock)
        } else {
            dispatch(action: .revealDock)
        }
    }

    /// Connects the taskbar settings UI's privacy gates to AppPreferences so a
    /// change there is persisted and applied like any other setting.
    private func installPrivacyGateBridge() {
        taskbarConceptState.clipboardHistoryEnabled = preferences.clipboardHistoryEnabled
        taskbarConceptState.ipGeolocationEnabled = preferences.ipGeolocationEnabled
        taskbarConceptState.faviconServiceEnabled = preferences.faviconServiceEnabled
        taskbarConceptState.aiAccountSwitchingEnabled = preferences.aiAccountSwitchingEnabled
        taskbarConceptState.clipboardRetention = preferences.clipboardRetention

        taskbarConceptState.onPrivacyGateChanged = { [weak self] key, value in
            guard let self else { return }
            var updated = self.preferences
            switch key {
            case "clipboardHistoryEnabled": updated.clipboardHistoryEnabled = value
            case "ipGeolocationEnabled": updated.ipGeolocationEnabled = value
            case "faviconServiceEnabled": updated.faviconServiceEnabled = value
            case "aiAccountSwitchingEnabled": updated.aiAccountSwitchingEnabled = value
            default: return
            }
            self.updatePreferences(updated)
        }
        taskbarConceptState.onClipboardRetentionChanged = { [weak self] policy in
            guard let self else { return }
            var updated = self.preferences
            updated.clipboardRetention = policy
            self.updatePreferences(updated)
        }
    }

    public func updatePreferences(_ newPreferences: AppPreferences) {
        let previous = self.preferences
        self.preferences = newPreferences
        // Privacy gates are forwarded immediately so turning one off takes
        // effect without a relaunch.
        if previous.aiAccountSwitchingEnabled != newPreferences.aiAccountSwitchingEnabled {
            aiUsageService.accountSwitchingEnabled = newPreferences.aiAccountSwitchingEnabled
        }
        if previous.ipGeolocationEnabled != newPreferences.ipGeolocationEnabled {
            WeatherService.ipGeolocationEnabled = newPreferences.ipGeolocationEnabled
        }
        if previous.faviconServiceEnabled != newPreferences.faviconServiceEnabled {
            FaviconService.usesThirdPartyService = newPreferences.faviconServiceEnabled
        }
        clipboardCoordinator.applySettingsChange(
            from: previous.clipboardSettings,
            to: newPreferences.clipboardSettings
        )
        refreshSettingsWindow()
        // Açık flyout yeni temaya hemen uysun
        if state.flyout.isVisible, let activeID = state.flyout.activeItemID {
            syncFlyout(activeItemID: activeID)
        }
        if state.placement != newPreferences.placement {
            dispatch(action: .updatePlacement(newPreferences.placement))
        } else {
            updateDockContent()
            syncPanels()
            persistConfiguration()
        }
    }

    public func persistConfiguration() {
        Logger.persistence.debug("Persisting configuration snapshot")
        let snapshot = ConfigurationSnapshot(
            version: ConfigurationPersistence.currentVersion,
            preferences: self.preferences,
            dockItems: self.state.dockItems
        )
        do {
            try configPersistence.save(snapshot: snapshot)
        } catch {
            Logger.persistence.error("Failed to persist configuration error=\(error.localizedDescription, privacy: .private)")
        }
    }

    private func setupLiveStreaming() {
        currentMetricsInterval = 15.0
        currentAIUsageInterval = 300.0
        currentPlaybackInterval = 10.0
        startSystemMetricsStreaming(interval: currentMetricsInterval)
        startPlaybackStreaming(interval: currentPlaybackInterval)
        aiUsageService.startLiveMonitoring(interval: currentAIUsageInterval) { [weak self] _ in
            guard let self else { return }
            self.updateDockContent()
            if self.activeFlyoutWidgetID == "ai_usage",
               let activeID = self.state.flyout.activeItemID {
                self.syncFlyout(activeItemID: activeID)
            }
        }
    }

    private func setupRunningState() {
        let center = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didActivateApplicationNotification
        ] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshRunningState()
                }
            }
        }
        refreshRunningState()
    }

    private func refreshRunningState() {
        let running = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .sorted { $0.processIdentifier < $1.processIdentifier }
        let orderedIDs = running.compactMap(\.bundleIdentifier)
        taskbarConceptState.runningBundleIDs = Set(orderedIDs)
        taskbarConceptState.runningAppOrder = orderedIDs
        taskbarConceptState.frontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    public func handleTaskbarIconClick(bundleIdentifier: String) {
        let matches = NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == bundleIdentifier }
        guard let app = matches.first else {
            launchPinnedApplication(bundleIdentifier: bundleIdentifier)
            return
        }
        if app.isActive {
            if taskbarConceptState.minimizeMode == .minimize {
                if windowManagerService.isAccessibilityGranted() {
                    if windowManagerService.minimizeWindows(bundleIdentifier: bundleIdentifier) {
                        return
                    }
                } else {
                    windowManagerService.promptAccessibilityPermission()
                }
            }
            app.hide()
        } else {
            app.activate()
        }
    }

    func handleTaskbarTileAction(_ action: TaskbarTileAction) {
        switch action {
        case .revealInFinder(let bundleID):
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
            NSWorkspace.shared.activateFileViewerSelecting([url])
        case .hideApp(let bundleID):
            NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID })?.hide()
        case .quitApp(let bundleID):
            NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID })?.terminate()
        case .newWindow(let bundleID):
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
            // `-n` opens a fresh instance; NSWorkspace cannot express that.
            try? ProcessRunner.launch(executablePath: "/usr/bin/open", arguments: ["-n", url.path])
        case .togglePin(let bundleID):
            taskbarConceptState.togglePinned(bundleID)
        case .openRecent(let url):
            NSWorkspace.shared.open(url)
        case .addDivider(let bundleID):
            taskbarConceptState.addDivider(after: bundleID)
        case .removeDivider(let bundleID):
            for divider in taskbarConceptState.userDividers where divider.anchorBundleID == bundleID {
                taskbarConceptState.removeDivider(divider.id)
            }
        case .moveDivider(let id, let bundleID):
            taskbarConceptState.moveDivider(id, after: bundleID)
        }
    }

    private func setupWeatherForwarding() {
        taskbarConceptState.weather = weatherService.currentState
        taskbarConceptState.weatherWidgetState = .loading
        weatherService.onUpdate = { [weak self] state in
            self?.taskbarConceptState.weather = state
            self?.taskbarConceptState.weatherWidgetState = state.isLive ? .loaded : .error("Weather unavailable — showing sample")
        }
        taskbarConceptState.nowPlaying = nowPlayingService.currentState
        taskbarConceptState.onTogglePlayback = { [weak self] in
            self?.nowPlayingService.togglePlayPause()
        }
        taskbarConceptState.$hideMacDock
            .removeDuplicates()
            .sink { [weak self] hidden in
                self?.dockController.setHidden(hidden)
            }
            .store(in: &taskbarPanelSubscriptions)
    }

    private func setupDefaultShortcuts() {
        registerShortcutBindings()
        taskbarConceptState.$shortcutBindings
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.registerShortcutBindings()
            }
            .store(in: &taskbarPanelSubscriptions)
    }

    private func registerShortcutBindings() {
        let bindings = taskbarConceptState.shortcutBindings
        _ = shortcutService.register(bindings: bindings) { [weak self] action in
            Logger.shortcuts.debug("Triggered shortcut action")
            Task { @MainActor in
                self?.handleShortcutAction(action)
            }
        }
    }

    public func handleShortcutAction(_ action: ShortcutAction) {
        switch action {
        case .toggleDock:
            toggleDockVisibility()
        case .focusNext:
            guard !state.dockItems.isEmpty else { return }
            if let currentID = state.selectedItemID,
               let currentIndex = state.dockItems.firstIndex(where: { $0.id == currentID }) {
                let nextIndex = min(currentIndex + 1, state.dockItems.count - 1)
                dispatch(action: .selectItem(id: state.dockItems[nextIndex].id))
            } else {
                dispatch(action: .selectItem(id: state.dockItems[0].id))
            }
        case .focusPrevious:
            guard !state.dockItems.isEmpty else { return }
            if let currentID = state.selectedItemID,
               let currentIndex = state.dockItems.firstIndex(where: { $0.id == currentID }) {
                let prevIndex = max(currentIndex - 1, 0)
                dispatch(action: .selectItem(id: state.dockItems[prevIndex].id))
            } else {
                dispatch(action: .selectItem(id: state.dockItems[0].id))
            }
        case .activateSelected:
            if let selectedID = state.selectedItemID {
                dispatch(action: .selectItem(id: selectedID))
            }
        case .openAddPanel:
            openAddPanel()
        case .openClipboard:
            if let clipboardItem = state.dockItems.first(where: {
                if case .widget(let id) = $0.kind, id == "clipboard" { return true }
                return false
            }) {
                dispatch(action: .selectItem(id: clipboardItem.id))
            }
        case .openCommandPalette:
            openCommandPalette()
        case .activateItem(let id):
            dispatch(action: .selectItem(id: id))
        case .tileWindow(let tilingAction):
            windowManagerService.tileFrontmostWindow(action: tilingAction)
        }
    }

    public func dispatch(action: AppAction) {
        let previousState = self.state
        self.state = reduce(state: previousState, action: action)

        switch action {
        case .selectItem(let id):
            if let id = id, let item = state.dockItems.first(where: { $0.id == id }) {
                switch item.kind {
                case .application(let bundleID, let url):
                    launchTarget(.application(bundleIdentifier: bundleID, url: url))
                case .link(let url):
                    launchTarget(.link(url))
                case .widget:
                    // İç içe dispatch yerine flyout doğrudan uygulanır; aksi halde dock iki kez yeniden kurulur
                    let flyoutAction = nextFlyoutAction(forWidgetItemID: id)
                    self.state = reduce(state: self.state, action: .flyout(flyoutAction))
                    applyFlyoutSideEffects(flyoutAction)
                }
            }
        case .flyout(let flyoutAction):
            applyFlyoutSideEffects(flyoutAction)
        case .updatePlacement(let placement):
            // Kalıcı kayıt ve auto-hide davranışı preferences üzerinden okunduğu için onunla senkron tutulur
            self.preferences.placement = placement
            // Auto-hide kapatılırken dock gizliyse geri getirecek tutamaç da kalmaz; dock görünür yapılır
            if !placement.autoHide && !self.state.isDockRevealed {
                self.state = reduce(state: self.state, action: .revealDock)
            }
            refreshSettingsWindow()
        default:
            break
        }

        self.updateDockContent()
        self.syncPanels()
        // Yalnızca diske yazılan veri değiştiyse kaydet; flyout geçişleri gibi geçici durumlar disk yazımı gerektirmez
        if previousState.dockItems != self.state.dockItems || previousState.placement != self.state.placement {
            self.persistConfiguration()
        }
    }

    private func nextFlyoutAction(forWidgetItemID id: UUID) -> FlyoutAction {
        if state.flyout.isVisible && state.flyout.activeItemID == id {
            return .close
        }
        if state.flyout.isVisible {
            return .switchTo(id)
        }
        return .open(id)
    }

    // MARK: - AI Accounts

    /// Açık oturum denetimi ve kayıtlı girişin doğrulanması depoda yapılır; engel varsa nedeni hata olarak gösterilir.
    private func confirmAndSwitchAccount(_ account: AIAccount, flyoutItemID: UUID) {
        runAccountOperation(title: "Could not switch to \(account.email)", flyoutItemID: flyoutItemID) { service in
            try await service.switchAccount(to: account)
        }
    }

    private func startAccountRelogin(account: AIAccount) {
        do {
            try aiUsageService.openReloginInTerminal(account: account)
        } catch {
            presentError(title: "Could not open \(account.provider.displayName) login", error: error)
        }
    }

    private func confirmAndRemoveAccount(_ account: AIAccount, flyoutItemID: UUID) {
        let confirmed = confirm(
            title: "Remove \(account.email) from SplitBar?",
            message: "SplitBar deletes its saved copy of this \(account.provider.displayName) login. You can add it again by logging in.",
            confirmTitle: "Remove"
        )
        guard confirmed else { return }
        runAccountOperation(title: "Could not remove account", flyoutItemID: flyoutItemID) { service in
            try await service.removeAccount(account)
        }
    }

    private func startAccountLogin(provider: AIAccountProvider) {
        do {
            try aiUsageService.openLoginInTerminal(provider: provider)
        } catch {
            presentError(title: "Could not open \(provider.displayName) login", error: error)
        }
    }

    private func confirmAndConnectClaudeLimits(flyoutItemID: UUID) {
        let confirmed = confirm(
            title: "Connect Claude Code plan limits?",
            message: "SplitBar will wrap the statusLine command in ~/.claude/settings.json with a small script that saves Claude's official rate-limit data for SplitBar and then runs your existing status line unchanged. A backup of settings.json is created, and you can disconnect at any time from the account menu.",
            confirmTitle: "Connect"
        )
        guard confirmed else { return }
        runAccountOperation(title: "Could not connect Claude limits", flyoutItemID: flyoutItemID) { service in
            try await service.installClaudeLimitBridge()
        }
    }

    private func confirmAndDisconnectClaudeLimits(flyoutItemID: UUID) {
        let confirmed = confirm(
            title: "Disconnect Claude Code plan limits?",
            message: "Your previous statusLine setting is restored in ~/.claude/settings.json.",
            confirmTitle: "Disconnect"
        )
        guard confirmed else { return }
        runAccountOperation(title: "Could not disconnect Claude limits", flyoutItemID: flyoutItemID) { service in
            try await service.uninstallClaudeLimitBridge()
        }
    }

    private func runAccountOperation(
        title: String,
        flyoutItemID: UUID,
        operation: @escaping @MainActor (AIUsageService) async throws -> Void
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await operation(self.aiUsageService)
            } catch {
                self.presentError(title: title, error: error)
            }
            if self.state.flyout.isVisible && self.state.flyout.activeItemID == flyoutItemID {
                self.syncFlyout(activeItemID: flyoutItemID)
            }
            self.updateDockContent()
        }
    }

    private func confirm(title: String, message: String, confirmTitle: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func presentError(title: String, error: Error) {
        Logger.general.error("\(title, privacy: .private) error=\(String(describing: error), privacy: .private)")
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = String(describing: error)
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    /// Saniyelik izlemenin son ölçümü. CPU ve ağ değerleri iki örnek arasındaki farktan hesaplandığı için
    /// araya ek örnekleme sokmak aralığı sıfıra yakın kısaltır ve %0 gösterir; yalnızca izleme başlamadan
    /// önce (uygulama açılışında) doğrudan örneklenir.
    private func currentSystemMetrics() -> SystemMetrics {
        if let latestSystemMetrics {
            return latestSystemMetrics
        }
        return systemMonitorService.sampleMetrics()
    }

    private func applyFlyoutSideEffects(_ flyoutAction: FlyoutAction) {
        switch flyoutAction {
        case .open(let id), .switchTo(let id):
            syncFlyout(activeItemID: id)
        case .close:
            closeFlyoutMonitors()
            flyoutController.hide()
        }
        refreshLiveStreamingCadence()
    }

    private func refreshLiveStreamingCadence() {
        guard !isStreamingCadenceRefreshing else { return }
        isStreamingCadenceRefreshing = true
        defer { isStreamingCadenceRefreshing = false }

        let metricsAreVisible = detailedSystemMonitorWindow?.isVisible == true
            || activeFlyoutWidgetID == "system_monitor"
        let aiUsageIsVisible = activeFlyoutWidgetID == "ai_usage"
        let playbackIsVisible = activeFlyoutWidgetID == "now_playing" || nowPlayingService.currentState.isPlaying

        let metricsInterval = metricsAreVisible ? 1.0 : 15.0
        if metricsInterval != currentMetricsInterval {
            currentMetricsInterval = metricsInterval
            startSystemMetricsStreaming(interval: metricsInterval)
        }

        let aiInterval = aiUsageIsVisible ? 3.0 : 300.0
        if aiInterval != currentAIUsageInterval {
            currentAIUsageInterval = aiInterval
            aiUsageService.startLiveMonitoring(interval: aiInterval) { [weak self] _ in
                guard let self else { return }
                self.updateDockContent()
                if self.activeFlyoutWidgetID == "ai_usage",
                   let activeID = self.state.flyout.activeItemID {
                    self.syncFlyout(activeItemID: activeID)
                }
            }
        }

        let playbackInterval = playbackIsVisible ? 2.0 : 10.0
        if playbackInterval != currentPlaybackInterval {
            currentPlaybackInterval = playbackInterval
            startPlaybackStreaming(interval: playbackInterval)
        }
    }

    private var activeFlyoutWidgetID: String? {
        guard state.flyout.isVisible,
              let activeID = state.flyout.activeItemID,
              let item = state.dockItems.first(where: { $0.id == activeID }),
              case .widget(let widgetID) = item.kind
        else {
            return nil
        }
        return widgetID
    }

    private func startSystemMetricsStreaming(interval: TimeInterval) {
        systemMonitorService.startMonitoring(interval: interval) { [weak self] metrics in
            guard let self else { return }
            self.latestSystemMetrics = metrics
            self.taskbarConceptState.systemMetrics = metrics
            self.taskbarConceptState.networkPeakIn = max(self.taskbarConceptState.networkPeakIn, Double(metrics.network.bytesInPerSecond))
            self.taskbarConceptState.networkPeakOut = max(self.taskbarConceptState.networkPeakOut, Double(metrics.network.bytesOutPerSecond))
            self.updateDockContent()
            if self.detailedSystemMonitorWindow?.isVisible == true {
                self.refreshDetailedSystemMonitor()
            }
            if self.activeFlyoutWidgetID == "system_monitor",
               let activeID = self.state.flyout.activeItemID {
                self.syncFlyout(activeItemID: activeID)
            }
        }
    }

    private func startPlaybackStreaming(interval: TimeInterval) {
        nowPlayingService.startMonitoring(interval: interval) { [weak self] state in
            guard let self else { return }
            if state != self.taskbarConceptState.nowPlaying {
                self.taskbarConceptState.nowPlaying = state
            }
            self.updateDockContent()
            if self.activeFlyoutWidgetID == "now_playing",
               let activeID = self.state.flyout.activeItemID {
                self.syncFlyout(activeItemID: activeID)
            }
        }
    }

    private func flyoutSize(for item: DockItem) -> CGSize {
        switch item.kind {
        case .widget(let widgetID):
            switch widgetID {
            case "ai_usage":
                return CGSize(width: 460.0, height: 720.0)
            case "clipboard":
                return CGSize(width: 380.0, height: 460.0)
            case "system_monitor":
                return CGSize(width: 380.0, height: 450.0)
            case "weather":
                return CGSize(width: 360.0, height: 430.0)
            case "now_playing":
                return CGSize(width: 360.0, height: 450.0)
            case "bluetooth":
                return CGSize(width: 360.0, height: 420.0)
            case "quick_notes":
                return CGSize(width: 400.0, height: 450.0)
            default:
                return CGSize(width: 380.0, height: 440.0)
            }
        case .application, .link:
            return CGSize(width: 380.0, height: 440.0)
        }
    }

    private func syncFlyout(activeItemID: UUID) {
        guard let screen = screenService.primaryScreen(),
              let item = state.dockItems.first(where: { $0.id == activeItemID }) else {
            flyoutController.hide()
            return
        }

        let size = flyoutSize(for: item)
        let dockPanelFrame = panelController.dockPanel.frame
        let frame = flyoutPanelFrame(
            anchorFrame: dockPanelFrame,
            screen: screen,
            edge: state.placement.edge,
            flyoutSize: size,
            gap: 12.0
        )

        let contentView: AnyView
        if case .widget(let widgetID) = item.kind, widgetID == "clipboard" {
            let clipboardView = ClipboardHistoryView(
                history: clipboardCoordinator.history,
                onCopy: { [weak self] entry in
                    self?.clipboardCoordinator.copyToPasteboard(entry: entry)
                },
                onTogglePin: { [weak self] id in
                    self?.clipboardCoordinator.togglePin(id: id)
                },
                onDelete: { [weak self] id in
                    self?.clipboardCoordinator.delete(id: id)
                },
                onClearUnpinned: { [weak self] in
                    self?.clipboardCoordinator.clearUnpinned()
                },
                onClearAll: { [weak self] in
                    self?.clipboardCoordinator.clearAll()
                },
                onPause: { [weak self] seconds in
                    self?.clipboardCoordinator.pause(for: seconds)
                }
            )
            contentView = AnyView(
                WidgetFlyoutView(
                    title: "Clipboard History",
                    onClose: { [weak self] in
                        self?.dispatch(action: .flyout(.close))
                    }
                ) {
                    clipboardView
                }
            )
        } else if case .widget(let widgetID) = item.kind, widgetID == "system_monitor" {
            let metrics = currentSystemMetrics()
            let monitorView = SystemMonitorFlyoutView(
                metrics: metrics,
                onRefresh: { [weak self] in
                    self?.syncFlyout(activeItemID: activeItemID)
                },
                onOpenDetailedWindow: { [weak self] in
                    self?.dispatch(action: .flyout(.close))
                    self?.openDetailedSystemMonitor()
                }
            )
            contentView = AnyView(
                WidgetFlyoutView(
                    title: "System Monitor",
                    onClose: { [weak self] in
                        self?.dispatch(action: .flyout(.close))
                    }
                ) {
                    monitorView
                }
            )
        } else if case .widget(let widgetID) = item.kind, widgetID == "now_playing" {
            let state = nowPlayingService.fetchCurrentState()
            let musicView = NowPlayingFlyoutView(
                state: state,
                onTogglePlayPause: { [weak self] in
                    self?.nowPlayingService.togglePlayPause()
                    self?.syncFlyout(activeItemID: activeItemID)
                },
                onNextTrack: { [weak self] in
                    self?.nowPlayingService.nextTrack()
                    self?.syncFlyout(activeItemID: activeItemID)
                },
                onPreviousTrack: { [weak self] in
                    self?.nowPlayingService.previousTrack()
                    self?.syncFlyout(activeItemID: activeItemID)
                },
                onSeek: { [weak self] newPos in
                    self?.nowPlayingService.seek(to: newPos)
                    self?.syncFlyout(activeItemID: activeItemID)
                },
                onRefresh: { [weak self] in
                    self?.syncFlyout(activeItemID: activeItemID)
                }
            )
            contentView = AnyView(
                WidgetFlyoutView(
                    title: "Now Playing",
                    onClose: { [weak self] in
                        self?.dispatch(action: .flyout(.close))
                    }
                ) {
                    musicView
                }
            )
        } else if case .widget(let widgetID) = item.kind, widgetID == "weather" {
            let weatherView = WeatherFlyoutView(
                state: weatherService.currentState,
                onRefresh: { [weak self] in
                    Task { @MainActor [weak self] in
                        await self?.weatherService.refresh()
                        self?.syncFlyout(activeItemID: activeItemID)
                    }
                }
            )
            contentView = AnyView(
                WidgetFlyoutView(
                    title: "Weather",
                    onClose: { [weak self] in
                        self?.dispatch(action: .flyout(.close))
                    }
                ) {
                    weatherView
                }
            )
        } else if case .widget(let widgetID) = item.kind, widgetID == "bluetooth" {
            let bt = bluetoothService.fetchCurrentState()
            let btView = BluetoothFlyoutView(
                state: bt,
                onConnect: { [weak self] address in
                    self?.bluetoothService.connect(deviceID: address) { [weak self] in
                        guard let self, self.state.flyout.activeItemID == activeItemID else { return }
                        self.syncFlyout(activeItemID: activeItemID)
                    }
                },
                onDisconnect: { [weak self] address in
                    self?.bluetoothService.disconnect(deviceID: address)
                    self?.syncFlyout(activeItemID: activeItemID)
                },
                onRefresh: { [weak self] in
                    _ = self?.bluetoothService.fetchCurrentState()
                    self?.syncFlyout(activeItemID: activeItemID)
                }
            )
            contentView = AnyView(
                WidgetFlyoutView(
                    title: "Bluetooth Devices",
                    onClose: { [weak self] in
                        self?.dispatch(action: .flyout(.close))
                    }
                ) {
                    btView
                }
            )
        } else if case .widget(let widgetID) = item.kind, widgetID == "ai_usage" {
            let aiState = aiUsageService.sampleUsage()
            let aiView = AIUsageFlyoutView(
                state: aiState,
                onRefresh: { [weak self] in
                    Task { @MainActor [weak self] in
                        await self?.aiUsageService.refresh()
                        self?.syncFlyout(activeItemID: activeItemID)
                    }
                },
                onDispatchTask: { [weak self] agentType, prompt, openTerminal in
                    guard let self = self else { return "" }
                    return await self.aiUsageService.dispatchTask(
                        agentType: agentType,
                        prompt: prompt,
                        openTerminal: openTerminal
                    )
                },
                onSwitchAccount: { [weak self] account in
                    self?.confirmAndSwitchAccount(account, flyoutItemID: activeItemID)
                },
                onRemoveAccount: { [weak self] account in
                    self?.confirmAndRemoveAccount(account, flyoutItemID: activeItemID)
                },
                onAddAccount: { [weak self] provider in
                    self?.startAccountLogin(provider: provider)
                },
                onReloginAccount: { [weak self] account in
                    self?.startAccountRelogin(account: account)
                },
                onConnectClaudeLimits: { [weak self] in
                    self?.confirmAndConnectClaudeLimits(flyoutItemID: activeItemID)
                },
                onDisconnectClaudeLimits: { [weak self] in
                    self?.confirmAndDisconnectClaudeLimits(flyoutItemID: activeItemID)
                }
            )
            contentView = AnyView(
                WidgetFlyoutView(
                    title: "AI Agents & Task Hub",
                    onClose: { [weak self] in
                        self?.dispatch(action: .flyout(.close))
                    }
                ) {
                    aiView
                }
            )
        } else if case .widget(let widgetID) = item.kind, widgetID == "quick_notes" {
            let notesView = QuickNotesFlyoutView(
                initialText: quickNotesService.loadNotes(),
                onSave: { [weak self] updatedText in
                    self?.quickNotesService.saveNotes(updatedText)
                },
                onCopyAll: { text in
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(text, forType: .string)
                }
            )
            contentView = AnyView(
                WidgetFlyoutView(
                    title: "Quick Scratchpad",
                    onClose: { [weak self] in
                        self?.dispatch(action: .flyout(.close))
                    }
                ) {
                    notesView
                }
            )
        } else {
            contentView = AnyView(
                WidgetFlyoutView(
                    title: item.name,
                    onClose: { [weak self] in
                        self?.dispatch(action: .flyout(.close))
                    }
                ) {
                    VStack {
                        Text("Content for \(item.name)")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            )
        }

        if flyoutController.panel.isVisible {
            flyoutController.replace(content: AnyView(contentView.dockTheme(preferences.materialStyle)), frame: frame)
        } else {
            flyoutController.show(content: AnyView(contentView.dockTheme(preferences.materialStyle)), frame: frame)
        }

        setupFlyoutMonitors()
    }

    public func showAppWindowPreviews(appName: String, bundleIdentifier: String, appIconURL: URL?) {
        guard let screen = screenService.primaryScreen() else { return }
        let windows = windowPreviewService.windows(forBundleIdentifier: bundleIdentifier, appName: appName)
        guard !windows.isEmpty else {
            Logger.panels.info("No open windows found for \(appName)")
            return
        }

        let flyoutSize = CGSize(width: 360.0, height: min(480.0, CGFloat(windows.count * 135 + 85)))
        let anchorFrame = panelController.dockPanel.frame

        let frame = flyoutPanelFrame(
            anchorFrame: anchorFrame,
            screen: screen,
            edge: state.placement.edge,
            flyoutSize: flyoutSize,
            gap: 12.0
        )

        let previewsView = AppWindowPreviewsFlyoutView(
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            appIconURL: appIconURL,
            windows: windows,
            previewService: self.windowPreviewService,
            onSelectWindow: { [weak self] window in
                guard let self = self else { return }
                self.windowPreviewService.focusWindow(info: window, bundleIdentifier: bundleIdentifier)
                self.flyoutController.hide()
                self.closeFlyoutMonitors()
            },
            onClose: { [weak self] in
                self?.flyoutController.hide()
                self?.closeFlyoutMonitors()
            }
        )

        flyoutController.show(content: AnyView(previewsView.dockTheme(preferences.materialStyle)), frame: frame)
        setupFlyoutMonitors()
    }

    private func setupFlyoutMonitors() {
        // Açan tıklamanın flyout'u hemen kapatmaması için kurulum bir sonraki run loop turuna ertelenir;
        // bu arada flyout kapandıysa monitör kurulmaz, aksi halde Escape uygulama genelinde yutulur
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.flyoutController.panel.isVisible else { return }
            if self.flyoutGlobalMonitor == nil {
                self.flyoutGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                    Task { @MainActor in
                        guard let self = self else { return }
                        let mouseLocation = NSEvent.mouseLocation
                        if !self.flyoutController.panel.frame.contains(mouseLocation) &&
                           !self.panelController.dockPanel.frame.contains(mouseLocation) {
                            self.dispatch(action: .flyout(.close))
                            self.flyoutController.hide()
                            self.closeFlyoutMonitors()
                        }
                    }
                }
            }
            if self.flyoutLocalMonitor == nil {
                self.flyoutLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
                    guard let self = self else { return event }
                    if event.type == .keyDown && event.keyCode == 53 {
                        self.dispatch(action: .flyout(.close))
                        self.flyoutController.hide()
                        self.closeFlyoutMonitors()
                        return nil
                    }
                    if event.type == .leftMouseDown || event.type == .rightMouseDown {
                        let mouseLocation = NSEvent.mouseLocation
                        if !self.flyoutController.panel.frame.contains(mouseLocation) &&
                           !self.panelController.dockPanel.frame.contains(mouseLocation) {
                            self.dispatch(action: .flyout(.close))
                            self.flyoutController.hide()
                            self.closeFlyoutMonitors()
                        }
                    }
                    return event
                }
            }
        }
    }

    private func closeFlyoutMonitors() {
        if let monitor = flyoutGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            flyoutGlobalMonitor = nil
        }
        if let monitor = flyoutLocalMonitor {
            NSEvent.removeMonitor(monitor)
            flyoutLocalMonitor = nil
        }
    }

    // MARK: - Detailed System Monitor Window
    public func openDetailedSystemMonitor() {
        if let window = detailedSystemMonitorWindow {
            refreshDetailedSystemMonitor()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            refreshLiveStreamingCadence()
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 780, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SplitBar — System Monitor"
        window.center()
        window.isReleasedWhenClosed = false
        self.detailedSystemMonitorWindow = window
        refreshDetailedSystemMonitor()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        refreshLiveStreamingCadence()
    }

    public func refreshDetailedSystemMonitor() {
        guard let window = detailedSystemMonitorWindow else { return }
        let metrics = currentSystemMetrics()
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        let rootView = DetailedSystemMonitorView(
            metrics: metrics,
            runningApps: apps,
            onRefresh: { [weak self] in
                self?.refreshDetailedSystemMonitor()
            }
        )
        // Hosting view yeniden kullanılır; yeniden kurulursa seçili bölüm ve kaydırma konumu her saniye sıfırlanır
        if let detailedMonitorHostingView {
            detailedMonitorHostingView.rootView = rootView
            return
        }
        let hostingView = NSHostingView(rootView: rootView)
        window.contentView = hostingView
        self.detailedMonitorHostingView = hostingView
    }

    // MARK: - Command Palette (Quick Launcher)
    public func openCommandPalette() {
        if let _ = commandPalettePanel {
            closeCommandPalette()
            return
        }

        if state.flyout.isVisible {
            dispatch(action: .flyout(.close))
        }
        closeAddPanel()

        guard let screen = screenService.primaryScreen() else { return }

        var items: [CommandPaletteItem] = []

        // 1. Quick Actions
        items.append(
            CommandPaletteItem(
                id: "act-lock",
                title: "Lock Screen",
                subtitle: "Immediately lock Mac display and user session",
                iconSystemName: "lock.fill",
                iconColor: .red,
                category: .quickActions,
                action: {
                    do {
                        try lockScreenImmediately()
                    } catch {
                        Logger.general.error("Lock screen action failed error=\(String(describing: error), privacy: .private)")
                        NSSound.beep()
                    }
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-sleep",
                title: "Sleep Display",
                subtitle: "Put active display to sleep",
                iconSystemName: "moon.fill",
                iconColor: .indigo,
                category: .quickActions,
                action: {
                    // pmset'in bitmesi beklenirken arayüz donmasın diye arka planda çalıştırılır
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            try sleepDisplays()
                        } catch {
                            Logger.general.error("Sleep display action failed error=\(String(describing: error), privacy: .private)")
                            DispatchQueue.main.async {
                                NSSound.beep()
                            }
                        }
                    }
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-toggle-dock",
                title: state.isDockRevealed ? "Hide EdgeDock" : "Reveal EdgeDock",
                subtitle: "Toggle visibility of the vertical edge dock",
                iconSystemName: "dock.rectangle",
                iconColor: .blue,
                category: .quickActions,
                action: { [weak self] in
                    self?.toggleDockVisibility()
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-monitor",
                title: "Detailed System Monitor",
                subtitle: "Open full CPU, RAM, Network, and Process inspector",
                iconSystemName: "gauge.with.needle",
                iconColor: .cyan,
                category: .quickActions,
                action: { [weak self] in
                    self?.openDetailedSystemMonitor()
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-settings",
                title: "Open SplitBar Settings",
                subtitle: "Configure appearance, shortcuts, clipboard and widgets",
                iconSystemName: "gearshape.fill",
                iconColor: .gray,
                category: .quickActions,
                action: { [weak self] in
                    self?.openSettingsWindow()
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-dock-left",
                title: "Dock: Move to Left Edge",
                subtitle: "Position SplitBar on the left side of the screen",
                iconSystemName: "sidebar.left",
                iconColor: .blue,
                category: .quickActions,
                action: { [weak self] in
                    self?.dispatch(action: .updatePlacement(DockPlacement(edge: .left, verticalOffsetFraction: 0.5, autoHide: false)))
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-dock-right",
                title: "Dock: Move to Right Edge",
                subtitle: "Position SplitBar on the right side of the screen",
                iconSystemName: "sidebar.right",
                iconColor: .blue,
                category: .quickActions,
                action: { [weak self] in
                    self?.dispatch(action: .updatePlacement(DockPlacement(edge: .bottom, verticalOffsetFraction: 0.5, autoHide: false)))
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-dock-top",
                title: "Dock: Move to Top Edge",
                subtitle: "Position SplitBar horizontally at the top of the screen",
                iconSystemName: "menubar.dock.rectangle",
                iconColor: .blue,
                category: .quickActions,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.dispatch(action: .updatePlacement(DockPlacement(edge: .top, verticalOffsetFraction: 0.5, autoHide: self.preferences.placement.autoHide)))
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-toggle-autohide",
                title: "Dock: Toggle Auto-Hide",
                subtitle: "Automatically show or hide the dock on screen edge hover",
                iconSystemName: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                iconColor: .orange,
                category: .quickActions,
                action: { [weak self] in
                    guard let self = self else { return }
                    let current = self.preferences.placement.autoHide
                    let newPlacement = DockPlacement(
                        edge: self.preferences.placement.edge,
                        verticalOffsetFraction: self.preferences.placement.verticalOffsetFraction,
                        autoHide: !current
                    )
                    self.dispatch(action: .updatePlacement(newPlacement))
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-theme-system",
                title: "Theme: System Liquid Glass",
                subtitle: "Switch to adaptive Apple Liquid Glass material",
                iconSystemName: "sparkles",
                iconColor: .indigo,
                category: .quickActions,
                action: { [weak self] in
                    guard let self = self else { return }
                    var updated = self.preferences
                    updated.materialStyle = .system
                    self.updatePreferences(updated)
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-theme-crystal",
                title: "Theme: Crystal Clear",
                subtitle: "Ultra-transparent high-refraction diamond glass",
                iconSystemName: "diamond",
                iconColor: .cyan,
                category: .quickActions,
                action: { [weak self] in
                    guard let self = self else { return }
                    var updated = self.preferences
                    updated.materialStyle = .crystalClear
                    self.updatePreferences(updated)
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-theme-aurora",
                title: "Theme: Aurora Borealis",
                subtitle: "Northern lights emerald and cyan fluid gradient with ambient glow",
                iconSystemName: "waveform.path",
                iconColor: .green,
                category: .quickActions,
                action: { [weak self] in
                    guard let self = self else { return }
                    var updated = self.preferences
                    updated.materialStyle = .auroraGlow
                    self.updatePreferences(updated)
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "act-theme-cyberpunk",
                title: "Theme: Cyberpunk Neon",
                subtitle: "Electric cyan and neon magenta glowing glass",
                iconSystemName: "bolt.fill",
                iconColor: .pink,
                category: .quickActions,
                action: { [weak self] in
                    guard let self = self else { return }
                    var updated = self.preferences
                    updated.materialStyle = .cyberpunkGlass
                    self.updatePreferences(updated)
                }
            )
        )

        // 2. Window Management (Tiling)
        items.append(
            CommandPaletteItem(
                id: "win-left",
                title: "Tile Window Left",
                subtitle: "Snap active window to the left half of the display",
                iconSystemName: "rectangle.lefthalf.filled",
                iconColor: .cyan,
                category: .windowManagement,
                action: { [weak self] in
                    self?.windowManagerService.tileFrontmostWindow(action: .leftHalf)
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "win-right",
                title: "Tile Window Right",
                subtitle: "Snap active window to the right half of the display",
                iconSystemName: "rectangle.righthalf.filled",
                iconColor: .cyan,
                category: .windowManagement,
                action: { [weak self] in
                    self?.windowManagerService.tileFrontmostWindow(action: .rightHalf)
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "win-max",
                title: "Maximize Window",
                subtitle: "Expand active window to fill visible screen area",
                iconSystemName: "rectangle.inset.filled",
                iconColor: .green,
                category: .windowManagement,
                action: { [weak self] in
                    self?.windowManagerService.tileFrontmostWindow(action: .maximize)
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "win-almost-max",
                title: "Almost Maximize Window",
                subtitle: "Expand active window leaving a comfortable bezel margin",
                iconSystemName: "rectangle.center.inset.filled",
                iconColor: .teal,
                category: .windowManagement,
                action: { [weak self] in
                    self?.windowManagerService.tileFrontmostWindow(action: .almostMaximize)
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "win-center",
                title: "Center Window",
                subtitle: "Center active window comfortably in middle of screen",
                iconSystemName: "rectangle.portrait.arrowtriangle.2.outward",
                iconColor: .blue,
                category: .windowManagement,
                action: { [weak self] in
                    self?.windowManagerService.tileFrontmostWindow(action: .center)
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "win-top",
                title: "Tile Window Top Half",
                subtitle: "Snap active window to the top half of the display",
                iconSystemName: "rectangle.tophalf.filled",
                iconColor: .purple,
                category: .windowManagement,
                action: { [weak self] in
                    self?.windowManagerService.tileFrontmostWindow(action: .topHalf)
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "win-bottom",
                title: "Tile Window Bottom Half",
                subtitle: "Snap active window to the bottom half of the display",
                iconSystemName: "rectangle.bottomhalf.filled",
                iconColor: .purple,
                category: .windowManagement,
                action: { [weak self] in
                    self?.windowManagerService.tileFrontmostWindow(action: .bottomHalf)
                }
            )
        )

        // 3. SplitBar Widgets
        items.append(
            CommandPaletteItem(
                id: "wid-scratchpad",
                title: "Quick Scratchpad",
                subtitle: "Instant local markdown notes, snippets and drafts",
                iconSystemName: "note.text",
                iconColor: .orange,
                category: .widgets,
                action: { [weak self] in
                    guard let self = self else { return }
                    if let item = self.state.dockItems.first(where: {
                        if case .widget(let id) = $0.kind, id == "quick_notes" { return true }
                        return false
                    }) {
                        self.dispatch(action: .selectItem(id: item.id))
                    }
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "wid-weather",
                title: "Weather: \(weatherService.currentState.cityName) (\(weatherService.currentState.formattedTemperature))",
                subtitle: weatherService.currentState.conditionText,
                iconSystemName: "sun.max.fill",
                iconColor: .orange,
                category: .widgets,
                action: { [weak self] in
                    guard let self = self else { return }
                    if let item = self.state.dockItems.first(where: {
                        if case .widget(let id) = $0.kind, id == "weather" { return true }
                        return false
                    }) {
                        self.dispatch(action: .selectItem(id: item.id))
                    }
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "wid-music",
                title: "Now Playing Controls",
                subtitle: "Apple Music & Spotify playback",
                iconSystemName: "music.note",
                iconColor: .pink,
                category: .widgets,
                action: { [weak self] in
                    guard let self = self else { return }
                    if let item = self.state.dockItems.first(where: {
                        if case .widget(let id) = $0.kind, id == "now_playing" { return true }
                        return false
                    }) {
                        self.dispatch(action: .selectItem(id: item.id))
                    }
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "wid-clipboard",
                title: "Clipboard History",
                subtitle: "\(clipboardCoordinator.history.count) entries saved locally",
                iconSystemName: "doc.on.clipboard",
                iconColor: .purple,
                category: .widgets,
                action: { [weak self] in
                    guard let self = self else { return }
                    if let item = self.state.dockItems.first(where: {
                        if case .widget(let id) = $0.kind, id == "clipboard" { return true }
                        return false
                    }) {
                        self.dispatch(action: .selectItem(id: item.id))
                    }
                }
            )
        )
        items.append(
            CommandPaletteItem(
                id: "wid-ai",
                title: "Local AI Models & Processes",
                subtitle: "Ollama models & active AI tasks",
                iconSystemName: "sparkles",
                iconColor: .indigo,
                category: .widgets,
                action: { [weak self] in
                    guard let self = self else { return }
                    if let item = self.state.dockItems.first(where: {
                        if case .widget(let id) = $0.kind, id == "ai_usage" { return true }
                        return false
                    }) {
                        self.dispatch(action: .selectItem(id: item.id))
                    }
                }
            )
        )

        // 4. Applications
        let appDirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
        let apps = catalogService.scan(directories: appDirs)
        for app in apps.prefix(30) {
            let appURL = app.applicationURL
            let bundleID = app.bundleIdentifier
            items.append(
                CommandPaletteItem(
                    id: "app-\(bundleID)",
                    title: app.displayName,
                    subtitle: appURL.path,
                    iconSystemName: "app.fill",
                    iconColor: .blue,
                    category: .applications,
                    action: { [weak self] in
                        self?.launchTarget(.application(bundleIdentifier: bundleID, url: appURL))
                    }
                )
            )
        }

        let panelWidth: CGFloat = 580.0
        let panelHeight: CGFloat = 440.0
        let visibleFrame = screen.visibleFrame
        let originX = visibleFrame.origin.x + (visibleFrame.width - panelWidth) / 2.0
        let originY = visibleFrame.origin.y + (visibleFrame.height - panelHeight) / 2.0 + 80.0

        let panelRect = NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight)
        let panel = KeyablePanel(
            contentRect: panelRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.acceptsMouseMovedEvents = true

        let paletteView = CommandPaletteView(
            items: items,
            onExecuteAIQuery: { [weak self] prompt in
                return await self?.aiUsageService.generateResponse(prompt: prompt) ?? "Ollama is not running."
            },
            onClose: { [weak self] in
                self?.closeCommandPalette()
            }
        )

        panel.contentView = NSHostingView(rootView: paletteView.dockTheme(preferences.materialStyle))
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.commandPalettePanel = panel

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.commandPalettePanel != nil else { return }
            if self.commandPaletteGlobalMonitor == nil {
                self.commandPaletteGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                    Task { @MainActor in
                        guard let self = self, let p = self.commandPalettePanel else { return }
                        let mouseLocation = NSEvent.mouseLocation
                        if !p.frame.contains(mouseLocation) {
                            self.closeCommandPalette()
                        }
                    }
                }
            }
            if self.commandPaletteLocalMonitor == nil {
                self.commandPaletteLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                    guard let self = self else { return event }
                    if event.keyCode == 53 { // Escape
                        self.closeCommandPalette()
                        return nil
                    }
                    return event
                }
            }
        }
    }

    public func closeCommandPalette() {
        if let m = commandPaletteGlobalMonitor {
            NSEvent.removeMonitor(m)
            commandPaletteGlobalMonitor = nil
        }
        if let m = commandPaletteLocalMonitor {
            NSEvent.removeMonitor(m)
            commandPaletteLocalMonitor = nil
        }
        commandPalettePanel?.orderOut(nil)
        commandPalettePanel = nil
    }

    // MARK: - Configuration Import/Export & Recovery
    public func promptExportConfiguration() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export SplitBar Configuration"
        savePanel.allowedContentTypes = [UTType.json]
        savePanel.nameFieldStringValue = "SplitBarConfig.json"

        if savePanel.runModal() == .OK, let targetURL = savePanel.url {
            let snapshot = ConfigurationSnapshot(
                version: ConfigurationPersistence.currentVersion,
                preferences: self.preferences,
                dockItems: self.state.dockItems
            )
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(snapshot)
                try data.write(to: targetURL, options: .atomic)
                Logger.persistence.info("Successfully exported configuration to: \(targetURL.path)")
            } catch {
                Logger.persistence.error("Failed to export configuration: \(error.localizedDescription)")
            }
        }
    }

    public func promptImportConfiguration() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Import SplitBar Configuration"
        openPanel.allowedContentTypes = [UTType.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true

        if openPanel.runModal() == .OK, let fileURL = openPanel.url {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                let snapshot = try decoder.decode(ConfigurationSnapshot.self, from: data)

                self.preferences = snapshot.preferences
                self.state = AppState(
                    dockItems: snapshot.dockItems,
                    selectedItemID: nil,
                    placement: snapshot.preferences.placement,
                    isDockRevealed: true,
                    flyout: FlyoutState(activeItemID: nil, isVisible: false)
                )
                self.updateDockContent()
                self.syncPanels()
                self.persistConfiguration()
                Logger.persistence.info("Successfully imported configuration from: \(fileURL.path)")
            } catch {
                Logger.persistence.error("Failed to import configuration: \(error.localizedDescription)")
            }
        }
    }

    public func resetToDefaults() {
        Logger.persistence.info("Resetting configuration to factory defaults")
        let defaultPlacement = DockPlacement(
            edge: .bottom,
            verticalOffsetFraction: 0.5,
            autoHide: false
        )
        let defaultShortcuts: [ShortcutBinding] = [
            ShortcutBinding(
                id: UUID(),
                chord: ShortcutChord(carbonKeyCode: 0x02, carbonModifiers: 0x0800),
                action: .toggleDock
            ),
            ShortcutBinding(
                id: UUID(),
                chord: ShortcutChord(carbonKeyCode: 0x31, carbonModifiers: 0x0800),
                action: .openCommandPalette
            ),
            ShortcutBinding(
                id: UUID(),
                chord: ShortcutChord(carbonKeyCode: 0x09, carbonModifiers: 0x0800),
                action: .openClipboard
            )
        ]
        let defaultPrefs = AppPreferences(
            placement: defaultPlacement,
            materialStyle: .system,
            shortcutBindings: defaultShortcuts,
            clipboardRetention: ClipboardRetentionPolicy(maxEntries: 100, maxBlobBytes: 10 * 1024 * 1024),
            clipboardExcludedBundleIdentifiers: ClipboardPrivacyFilter.defaultExcludedBundleIdentifiers,
            selectedScreenIdentifier: nil,
            reduceMotion: false,
            language: .english,
            clipboardHistoryEnabled: false,
            aiAccountSwitchingEnabled: false,
            ipGeolocationEnabled: false,
            faviconServiceEnabled: false,
            dockIconSize: 46.0
        )
        var defaultItems: [DockItem] = [
            DockItem(id: UUID(), name: "Now Playing", kind: .widget(widgetIdentifier: "now_playing")),
            DockItem(id: UUID(), name: "Weather", kind: .widget(widgetIdentifier: "weather")),
            DockItem(id: UUID(), name: "Clipboard", kind: .widget(widgetIdentifier: "clipboard")),
            DockItem(id: UUID(), name: "AI Activity", kind: .widget(widgetIdentifier: "ai_usage")),
            DockItem(id: UUID(), name: "Scratchpad", kind: .widget(widgetIdentifier: "quick_notes"))
        ]
        if FileManager.default.fileExists(atPath: "/System/Library/CoreServices/Finder.app") {
            defaultItems.append(DockItem(id: UUID(), name: "Finder", kind: .application(bundleIdentifier: "com.apple.finder", applicationURL: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"))))
        }
        if FileManager.default.fileExists(atPath: "/Applications/Safari.app") {
            defaultItems.append(DockItem(id: UUID(), name: "Safari", kind: .application(bundleIdentifier: "com.apple.Safari", applicationURL: URL(fileURLWithPath: "/Applications/Safari.app"))))
        }

        self.preferences = defaultPrefs
        self.state = AppState(
            dockItems: defaultItems,
            selectedItemID: nil,
            placement: defaultPlacement,
            isDockRevealed: true,
            flyout: FlyoutState(activeItemID: nil, isVisible: false)
        )
        self.updateDockContent()
        self.syncPanels()
        self.persistConfiguration()
    }

    public func openAddPanel() {
        if let existing = addItemPanel {
            existing.orderFrontRegardless()
            return
        }

        let appDirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
        let apps = catalogService.scan(directories: appDirs)
        let initialAddState = AddItemState(
            category: .apps,
            searchQuery: "",
            selectedIndex: apps.isEmpty ? nil : 0,
            isVisible: true
        )

        let panel = KeyablePanel(
            contentRect: CGRect(x: 0.0, y: 0.0, width: 440.0, height: 500.0),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = edgePanelCollectionBehavior()
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.acceptsMouseMovedEvents = true

        guard let screen = screenService.primaryScreen() else { return }
        let dockPanelFrame = panelController.dockPanel.frame
        let flyoutFrame = flyoutPanelFrame(
            anchorFrame: dockPanelFrame,
            screen: screen,
            edge: state.placement.edge,
            flyoutSize: CGSize(width: 440.0, height: 500.0),
            gap: 12.0
        )
        panel.setFrame(flyoutFrame, display: true)

        let addView = AddItemViewHostingContainer(
            applications: apps,
            initialState: initialAddState,
            onAddApplication: { [weak self] app in
                let item = DockItem(
                    id: UUID(),
                    name: app.displayName,
                    kind: .application(
                        bundleIdentifier: app.bundleIdentifier,
                        applicationURL: app.applicationURL
                    )
                )
                self?.dispatch(action: .addItem(item))
                self?.closeAddPanel()
            },
            onAddLink: { [weak self] linkStr in
                if let url = URL(string: linkStr) {
                    let item = DockItem(
                        id: UUID(),
                        name: url.host ?? "Web Link",
                        kind: .link(url: url)
                    )
                    self?.dispatch(action: .addItem(item))
                }
                self?.closeAddPanel()
            },
            onAddWidget: { [weak self] id, name in
                let item = DockItem(
                    id: UUID(),
                    name: name,
                    kind: .widget(widgetIdentifier: id)
                )
                self?.dispatch(action: .addItem(item))
                self?.closeAddPanel()
            },
            onClose: { [weak self] in
                self?.closeAddPanel()
            }
        )

        panel.contentView = NSHostingView(rootView: addView.dockTheme(preferences.materialStyle))
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.addItemPanel = panel

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.addItemPanel != nil else { return }
            if self.addPanelGlobalMonitor == nil {
                self.addPanelGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                    Task { @MainActor in
                        guard let self = self, let panel = self.addItemPanel else { return }
                        let mouseLocation = NSEvent.mouseLocation
                        if !panel.frame.contains(mouseLocation) &&
                           !self.panelController.dockPanel.frame.contains(mouseLocation) {
                            self.closeAddPanel()
                        }
                    }
                }
            }

            if self.addPanelLocalMonitor == nil {
                self.addPanelLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
                    guard let self = self, let panel = self.addItemPanel else { return event }
                    if event.type == .keyDown && event.keyCode == 53 {
                        self.closeAddPanel()
                        return nil
                    }
                    if event.type == .leftMouseDown || event.type == .rightMouseDown {
                        let mouseLocation = NSEvent.mouseLocation
                        if !panel.frame.contains(mouseLocation) &&
                           !self.panelController.dockPanel.frame.contains(mouseLocation) {
                            self.closeAddPanel()
                        }
                    }
                    return event
                }
            }
        }
    }

    public func closeAddPanel() {
        if let monitor = addPanelGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            addPanelGlobalMonitor = nil
        }
        if let monitor = addPanelLocalMonitor {
            NSEvent.removeMonitor(monitor)
            addPanelLocalMonitor = nil
        }
        addItemPanel?.orderOut(nil)
        addItemPanel = nil
    }

    public func updateDockContent() {
        Logger.dock.debug("Updating dock content hosting view")
        let container = DockInteractiveContainerView(
            state: self.state,
            preferences: self.preferences,
            config: self.magnificationConfiguration,
            weatherState: self.weatherService.currentState,
            aiUsageState: self.aiUsageService.sampleUsage(),
            // Yeniden örnekleme CPU/ağ delta'larını bozar ve her dispatch'te gereksiz sistem çağrısı yapar
            systemMetrics: self.latestSystemMetrics,
            nowPlayingState: self.nowPlayingService.currentState,
            onAction: { [weak self] action in
                self?.dispatch(action: action)
            },
            onOpenAddPanel: { [weak self] in
                self?.openAddPanel()
            },
            onSelectTheme: { [weak self] newTheme in
                guard let self = self else { return }
                var updated = self.preferences
                updated.materialStyle = newTheme
                self.updatePreferences(updated)
            },
            onToggleAutoHide: { [weak self] in
                guard let self = self else { return }
                let current = self.preferences.placement.autoHide
                let newPlacement = DockPlacement(
                    edge: self.preferences.placement.edge,
                    verticalOffsetFraction: self.preferences.placement.verticalOffsetFraction,
                    autoHide: !current
                )
                self.dispatch(action: .updatePlacement(newPlacement))
            },
            onShowAppWindows: { [weak self] appName, bundleID, appURL in
                self?.showAppWindowPreviews(appName: appName, bundleIdentifier: bundleID, appIconURL: appURL)
            },
            onHoverItem: { [weak self] item, center in
                guard let self = self else { return }
                if let item = item, let center = center {
                    let anchorFrame = self.panelController.dockPanel.frame
                    let screenX = anchorFrame.minX + center.x
                    let screenY = anchorFrame.maxY - center.y
                    self.tooltipController.show(
                        title: item.name,
                        badge: item.badgeText,
                        isRunning: item.isRunning,
                        anchorFrame: anchorFrame,
                        screenY: screenY,
                        screenX: screenX,
                        edge: self.state.placement.edge
                    )
                } else {
                    self.tooltipController.hide()
                }
            },
            onUpdateIconSize: { [weak self] newSize in
                guard let self = self else { return }
                var updated = self.preferences
                updated.dockIconSize = newSize
                self.updatePreferences(updated)
            }
        )
        // Hosting view yeniden oluşturulmaz; aksi halde hover ve auto-hide @State'i her canlı güncellemede sıfırlanır
        if let dockHostingView {
            dockHostingView.rootView = container
            return
        }
        let hostingView = NSHostingView(rootView: container)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panelController.setContentView(hostingView)
        self.dockHostingView = hostingView
    }

    public func syncPanels() {
        Logger.panels.debug("Synchronizing panel frames and auto-hide")
        guard isLegacyEdgeDockEnabled else {
            panelController.setAutoHide(
                enabled: false,
                handleFrame: .zero,
                edge: state.placement.edge,
                style: preferences.materialStyle
            )
            if panelController.dockPanel.isVisible {
                panelController.hide(edge: state.placement.edge)
            }
            tooltipController.hide()
            return
        }
        guard let screen = screenService.primaryScreen() else {
            return
        }

        let iconBaseSize = CGFloat(preferences.dockIconSize)
        let capsuleThickness = iconBaseSize + 22.0
        let itemSlotSize = iconBaseSize + 8.0

        let panelSize: CGSize
        if state.placement.edge == .top || state.placement.edge == .bottom {
            let width = max(160.0, CGFloat(state.dockItems.count) * itemSlotSize + 72.0)
            panelSize = CGSize(width: width, height: capsuleThickness)
        } else {
            let height = max(160.0, CGFloat(state.dockItems.count) * itemSlotSize + 72.0)
            panelSize = CGSize(width: capsuleThickness, height: height)
        }

        let frame = edgePanelFrame(
            screen: screen,
            panelSize: panelSize,
            edge: state.placement.edge,
            edgeInset: 10.0
        )

        // Tutamaç önce konumlanır ki dock gizlenirken onu belirtebilsin
        if state.placement.autoHide {
            let handleFrame = edgeHandleFrame(
                dockFrame: frame,
                screen: screen,
                edge: state.placement.edge,
                length: 92.0,
                thickness: 16.0
            )
            panelController.setAutoHide(enabled: true, handleFrame: handleFrame, edge: state.placement.edge, style: preferences.materialStyle)
        } else {
            panelController.setAutoHide(enabled: false, handleFrame: .zero, edge: state.placement.edge, style: preferences.materialStyle)
        }

        if state.isDockRevealed {
            panelController.show(frame: frame, edge: state.placement.edge)
        } else {
            panelController.hide(edge: state.placement.edge)
            tooltipController.hide()
        }
    }
}
