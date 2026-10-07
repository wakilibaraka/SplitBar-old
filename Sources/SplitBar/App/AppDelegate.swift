import AppKit
import Foundation
import OSLog

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public private(set) var runtimeController: AppRuntimeController?

    private func claimSingleInstance() -> Bool {
        let myPID = ProcessInfo.processInfo.processIdentifier
        let executableName = (ProcessInfo.processInfo.arguments.first as NSString?)?.lastPathComponent ?? "SplitBar"
        let others = NSWorkspace.shared.runningApplications.filter { app in
            app.processIdentifier != myPID
                && (app.bundleIdentifier == "com.baraka.splitbar"
                    || app.executableURL?.lastPathComponent == executableName)
        }
        guard others.isEmpty else {
            others.first?.activate(options: .activateAllWindows)
            Logger.lifecycle.info("Another SplitBar instance is already running; this launch yields to it")
            NSApp.terminate(nil)
            return false
        }
        return true
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        guard claimSingleInstance() else { return }
        Logger.lifecycle.info("SplitBar application did finish launching")
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first?.appendingPathComponent("com.baraka.splitbar")
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("com.baraka.splitbar")

        let configFileURL = appSupport.appendingPathComponent("config.json")
        let configPersistence = ConfigurationPersistence(fileURL: configFileURL)

        let defaultPlacement = DockPlacement(
            edge: .bottom,
            verticalOffsetFraction: 0.5,
            autoHide: false
        )

        let defaultShortcuts: [ShortcutBinding] = [
            ShortcutBinding(
                id: UUID(),
                chord: ShortcutChord(carbonKeyCode: 0x02, carbonModifiers: 0x0800), // Option + D
                action: .toggleDock
            ),
            ShortcutBinding(
                id: UUID(),
                chord: ShortcutChord(carbonKeyCode: 0x31, carbonModifiers: 0x0800), // Option + Space
                action: .openCommandPalette
            ),
            ShortcutBinding(
                id: UUID(),
                chord: ShortcutChord(carbonKeyCode: 0x09, carbonModifiers: 0x0800), // Option + V
                action: .openClipboard
            ),
            ShortcutBinding(
                id: UUID(),
                chord: ShortcutChord(carbonKeyCode: 0x7B, carbonModifiers: 0x1800), // Control + Option + Left
                action: .tileWindow(.leftHalf)
            ),
            ShortcutBinding(
                id: UUID(),
                chord: ShortcutChord(carbonKeyCode: 0x7C, carbonModifiers: 0x1800), // Control + Option + Right
                action: .tileWindow(.rightHalf)
            ),
            ShortcutBinding(
                id: UUID(),
                chord: ShortcutChord(carbonKeyCode: 0x7E, carbonModifiers: 0x1800), // Control + Option + Up
                action: .tileWindow(.maximize)
            ),
            ShortcutBinding(
                id: UUID(),
                chord: ShortcutChord(carbonKeyCode: 0x7D, carbonModifiers: 0x1800), // Control + Option + Down
                action: .tileWindow(.center)
            )
        ]

        let defaultPreferences = AppPreferences(
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
        var defaultItems: [DockItem] = []

        // Real macOS Applications
        let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
        defaultItems.append(
            DockItem(
                id: UUID(),
                name: "Finder",
                kind: .application(
                    bundleIdentifier: "com.apple.finder",
                    applicationURL: finderURL
                )
            )
        )

        if let safariURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") ?? (FileManager.default.fileExists(atPath: "/Applications/Safari.app") ? URL(fileURLWithPath: "/Applications/Safari.app") : nil) {
            defaultItems.append(
                DockItem(
                    id: UUID(),
                    name: "Safari",
                    kind: .application(
                        bundleIdentifier: "com.apple.Safari",
                        applicationURL: safariURL
                    )
                )
            )
        }

        if let chromeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") ?? (FileManager.default.fileExists(atPath: "/Applications/Google Chrome.app") ? URL(fileURLWithPath: "/Applications/Google Chrome.app") : nil) {
            defaultItems.append(
                DockItem(
                    id: UUID(),
                    name: "Google Chrome",
                    kind: .application(
                        bundleIdentifier: "com.google.Chrome",
                        applicationURL: chromeURL
                    )
                )
            )
        }

        let notesPath = "/System/Applications/Notes.app"
        if FileManager.default.fileExists(atPath: notesPath) {
            defaultItems.append(
                DockItem(
                    id: UUID(),
                    name: "Notes",
                    kind: .application(
                        bundleIdentifier: "com.apple.Notes",
                        applicationURL: URL(fileURLWithPath: notesPath)
                    )
                )
            )
        }

        let terminalPath = "/System/Applications/Utilities/Terminal.app"
        if FileManager.default.fileExists(atPath: terminalPath) {
            defaultItems.append(
                DockItem(
                    id: UUID(),
                    name: "Terminal",
                    kind: .application(
                        bundleIdentifier: "com.apple.Terminal",
                        applicationURL: URL(fileURLWithPath: terminalPath)
                    )
                )
            )
        }

        let settingsPath = "/System/Applications/System Settings.app"
        if FileManager.default.fileExists(atPath: settingsPath) {
            defaultItems.append(
                DockItem(
                    id: UUID(),
                    name: "System Settings",
                    kind: .application(
                        bundleIdentifier: "com.apple.systempreferences",
                        applicationURL: URL(fileURLWithPath: settingsPath)
                    )
                )
            )
        }

        // Widgets
        defaultItems.append(
            DockItem(
                id: UUID(),
                name: "Weather",
                kind: .widget(widgetIdentifier: "weather")
            )
        )
        defaultItems.append(
            DockItem(
                id: UUID(),
                name: "Now Playing",
                kind: .widget(widgetIdentifier: "now_playing")
            )
        )
        defaultItems.append(
            DockItem(
                id: UUID(),
                name: "Clipboard",
                kind: .widget(widgetIdentifier: "clipboard")
            )
        )
        defaultItems.append(
            DockItem(
                id: UUID(),
                name: "System Monitor",
                kind: .widget(widgetIdentifier: "system_monitor")
            )
        )
        defaultItems.append(
            DockItem(
                id: UUID(),
                name: "AI Activity",
                kind: .widget(widgetIdentifier: "ai_usage")
            )
        )
        defaultItems.append(
            DockItem(
                id: UUID(),
                name: "Scratchpad",
                kind: .widget(widgetIdentifier: "quick_notes")
            )
        )

        let defaultSnapshot = ConfigurationSnapshot(
            version: ConfigurationPersistence.currentVersion,
            preferences: defaultPreferences,
            dockItems: defaultItems
        )

        let loadedSnapshot: ConfigurationSnapshot
        switch configPersistence.load(defaultSnapshot: defaultSnapshot) {
        case .loaded(let snapshot):
            loadedSnapshot = snapshot
        case .recoveredDefault(let snapshot, _):
            loadedSnapshot = snapshot
        case .migrationRequired:
            loadedSnapshot = defaultSnapshot
        }

        // Sanitize loaded items to ensure real apps and remove broken/defunct entries
        var sanitizedItems: [DockItem] = []
        var seenKeys = Set<String>()

        for item in loadedSnapshot.dockItems {
            switch item.kind {
            case .application(let bundleID, let appURL):
                let exists = (NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil) ||
                             FileManager.default.fileExists(atPath: appURL.path)
                if exists && !seenKeys.contains(bundleID) {
                    seenKeys.insert(bundleID)
                    sanitizedItems.append(item)
                }
            case .widget(let wid):
                let key = "widget.\(wid)"
                if !seenKeys.contains(key) {
                    seenKeys.insert(key)
                    sanitizedItems.append(item)
                }
            case .link(let url):
                let key = "link.\(url.absoluteString)"
                if !seenKeys.contains(key) {
                    seenKeys.insert(key)
                    sanitizedItems.append(item)
                }
            }
        }

        // Ensure core native macOS applications (Finder, Safari, Chrome, Notes, Terminal, System Settings) are in the dock
        for defItem in defaultItems.reversed() {
            if case .application(let bundleID, _) = defItem.kind {
                if !seenKeys.contains(bundleID) {
                    seenKeys.insert(bundleID)
                    sanitizedItems.insert(defItem, at: 0)
                }
            }
        }

        if sanitizedItems != loadedSnapshot.dockItems {
            let updatedSnapshot = ConfigurationSnapshot(
                version: ConfigurationPersistence.currentVersion,
                preferences: loadedSnapshot.preferences,
                dockItems: sanitizedItems
            )
            try? configPersistence.save(snapshot: updatedSnapshot)
        }

        let initialState = AppState(
            dockItems: sanitizedItems,
            selectedItemID: nil,
            placement: loadedSnapshot.preferences.placement,
            isDockRevealed: false,
            flyout: FlyoutState(activeItemID: nil, isVisible: false)
        )

        let screenService = ScreenService()
        let launchService = AppLaunchService()
        let catalogService = ApplicationCatalogService()
        let shortcutService = GlobalShortcutService()
        let flyoutController = FlyoutPanelController()
        let clipboardPersistence = ClipboardPersistence(baseURL: appSupport)
        let clipboardMonitor = ClipboardMonitor()
        let systemMonitorService = SystemMonitorService()
        let nowPlayingService = NowPlayingService()
        let weatherService = WeatherService(
            initialState: WeatherState.defaultSample(),
            cacheURL: appSupport.appendingPathComponent("weather.json")
        )
        // Gerçek cihazlar flyout açılınca okunur; sahte örnek cihazlarla başlanmaz
        let bluetoothService = BluetoothService(
            initialState: BluetoothState(isBluetoothEnabled: false, devices: [], lastUpdated: Date())
        )
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let claudeBridge = ClaudeStatusLineBridge(supportDirectory: appSupport, homeDirectory: homeDirectory)
        // Gerçek veriler ilk yenilemede okunur; sahte örnek oturumlarla başlanmaz
        let aiUsageService = AIUsageService(
            initialState: .empty,
            accountStore: AIAccountStore(
                registryURL: appSupport.appendingPathComponent("ai_accounts.json"),
                homeDirectory: homeDirectory
            ),
            usageScanner: ProviderUsageScanner(homeDirectory: homeDirectory, claudeCaptureURL: claudeBridge.captureURL),
            claudeBridge: claudeBridge
        )
        let windowManagerService = WindowManagerService(
            configuration: WindowTilingConfiguration(gap: 8.0, edgeMargin: 10.0)
        )
        let launchAtLoginService = LaunchAtLoginService()
        let quickNotesService = QuickNotesService(baseURL: appSupport)
        // Privacy gates are process-wide defaults; flip them before any service
        // can act on them.
        WeatherService.ipGeolocationEnabled = loadedSnapshot.preferences.ipGeolocationEnabled
        FaviconService.usesThirdPartyService = loadedSnapshot.preferences.faviconServiceEnabled

        let dockController = DockController(
            stateFileURL: appSupport.appendingPathComponent("dock-prior-state.json")
        )
        dockController.restoreIfNeeded()
        dockController.setupSignalHandlers {
            Task { @MainActor in
                DockController(stateFileURL: appSupport.appendingPathComponent("dock-prior-state.json")).setHidden(false)
            }
        }

        self.runtimeController = AppRuntimeController(
            initialState: initialState,
            preferences: loadedSnapshot.preferences,
            screenService: screenService,
            launchService: launchService,
            catalogService: catalogService,
            shortcutService: shortcutService,
            flyoutController: flyoutController,
            clipboardPersistence: clipboardPersistence,
            clipboardMonitor: clipboardMonitor,
            configPersistence: configPersistence,
            systemMonitorService: systemMonitorService,
            nowPlayingService: nowPlayingService,
            weatherService: weatherService,
            bluetoothService: bluetoothService,
            aiUsageService: aiUsageService,
            windowManagerService: windowManagerService,
            launchAtLoginService: launchAtLoginService,
            quickNotesService: quickNotesService,
            dockController: dockController
        )
    }

    public func applicationWillTerminate(_ notification: Notification) {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first?.appendingPathComponent("com.baraka.splitbar")
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("com.baraka.splitbar")
        DockController(stateFileURL: appSupport.appendingPathComponent("dock-prior-state.json")).setHidden(false)
    }
}
