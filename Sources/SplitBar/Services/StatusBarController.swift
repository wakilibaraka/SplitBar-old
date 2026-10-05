import AppKit
import Foundation
import OSLog

@MainActor
public final class StatusBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let onToggleDock: () -> Void
    private let onOpenCommandPalette: () -> Void
    private let onOpenTaskbarPreview: () -> Void
    private let onOpenSystemMonitor: () -> Void
    private let onOpenSettings: () -> Void
    private let onChangeEdge: (DockEdge) -> Void
    private let onToggleAutoHide: () -> Void
    private let onSelectTheme: (DockMaterialStyle) -> Void
    private let onExportBackup: () -> Void
    private let onImportBackup: () -> Void
    private let onQuit: () -> Void

    public init(
        onToggleDock: @escaping () -> Void,
        onOpenCommandPalette: @escaping () -> Void,
        onOpenTaskbarPreview: @escaping () -> Void,
        onOpenSystemMonitor: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onChangeEdge: @escaping (DockEdge) -> Void,
        onToggleAutoHide: @escaping () -> Void,
        onSelectTheme: @escaping (DockMaterialStyle) -> Void,
        onExportBackup: @escaping () -> Void,
        onImportBackup: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onToggleDock = onToggleDock
        self.onOpenCommandPalette = onOpenCommandPalette
        self.onOpenTaskbarPreview = onOpenTaskbarPreview
        self.onOpenSystemMonitor = onOpenSystemMonitor
        self.onOpenSettings = onOpenSettings
        self.onChangeEdge = onChangeEdge
        self.onToggleAutoHide = onToggleAutoHide
        self.onSelectTheme = onSelectTheme
        self.onExportBackup = onExportBackup
        self.onImportBackup = onImportBackup
        self.onQuit = onQuit
        super.init()
        self.setupStatusItem()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(
                systemSymbolName: "sidebar.right",
                accessibilityDescription: "SplitBar"
            )
            image?.isTemplate = true
            button.image = image
            button.toolTip = "SplitBar — macOS Productivity Dock"
        }

        let menu = NSMenu()
        menu.delegate = self

        let toggleItem = NSMenuItem(
            title: "Toggle Legacy Edge Dock",
            action: #selector(handleToggleDock),
            keyEquivalent: "d"
        )
        toggleItem.keyEquivalentModifierMask = [.option]
        toggleItem.target = self
        menu.addItem(toggleItem)

        let taskbarPreviewItem = NSMenuItem(
            title: "Taskbar Design Preview...",
            action: #selector(handleOpenTaskbarPreview),
            keyEquivalent: ""
        )
        taskbarPreviewItem.target = self
        menu.addItem(taskbarPreviewItem)

        let paletteItem = NSMenuItem(
            title: "Command Palette...",
            action: #selector(handleOpenCommandPalette),
            keyEquivalent: " "
        )
        paletteItem.keyEquivalentModifierMask = [.option]
        paletteItem.target = self
        menu.addItem(paletteItem)

        let monitorItem = NSMenuItem(
            title: "Detailed System Monitor...",
            action: #selector(handleOpenSystemMonitor),
            keyEquivalent: "m"
        )
        monitorItem.keyEquivalentModifierMask = [.option, .command]
        monitorItem.target = self
        menu.addItem(monitorItem)

        let autoHideItem = NSMenuItem(
            title: "Toggle Auto-Hide",
            action: #selector(handleToggleAutoHide),
            keyEquivalent: "h"
        )
        autoHideItem.keyEquivalentModifierMask = [.option]
        autoHideItem.target = self
        menu.addItem(autoHideItem)

        // Dock Position Submenu
        let positionSubmenu = NSMenu()
        let leftItem = NSMenuItem(
            title: "Left Edge",
            action: #selector(handleSetLeftEdge),
            keyEquivalent: ""
        )
        leftItem.target = self
        positionSubmenu.addItem(leftItem)

        let rightItem = NSMenuItem(
            title: "Right Edge",
            action: #selector(handleSetRightEdge),
            keyEquivalent: ""
        )
        rightItem.target = self
        positionSubmenu.addItem(rightItem)

        let topItem = NSMenuItem(
            title: "Top Edge",
            action: #selector(handleSetTopEdge),
            keyEquivalent: ""
        )
        topItem.target = self
        positionSubmenu.addItem(topItem)

        let bottomItem = NSMenuItem(
            title: "Bottom Edge",
            action: #selector(handleSetBottomEdge),
            keyEquivalent: ""
        )
        bottomItem.target = self
        positionSubmenu.addItem(bottomItem)

        let positionMenuItem = NSMenuItem(title: "Dock Position", action: nil, keyEquivalent: "")
        positionMenuItem.submenu = positionSubmenu
        menu.addItem(positionMenuItem)

        // Material Themes Submenu
        let themeSubmenu = NSMenu()
        let themes: [(String, DockMaterialStyle)] = DockMaterialStyle.presets.map { ($0.displayName, $0) }
        for (themeTitle, themeStyle) in themes {
            let item = NSMenuItem(title: themeTitle, action: #selector(handleSelectTheme(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = themeStyle
            themeSubmenu.addItem(item)
        }
        let themeMenuItem = NSMenuItem(title: "Liquid Glass Theme", action: nil, keyEquivalent: "")
        themeMenuItem.submenu = themeSubmenu
        menu.addItem(themeMenuItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(handleOpenSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = self
        menu.addItem(settingsItem)

        let exportItem = NSMenuItem(
            title: "Export Backup...",
            action: #selector(handleExportBackup),
            keyEquivalent: ""
        )
        exportItem.target = self
        menu.addItem(exportItem)

        let importItem = NSMenuItem(
            title: "Import Backup...",
            action: #selector(handleImportBackup),
            keyEquivalent: ""
        )
        importItem.target = self
        menu.addItem(importItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit SplitBar",
            action: #selector(handleQuit),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        self.statusItem = item
        Logger.lifecycle.info("Status bar menu item initialized")
    }

    @objc private func handleToggleDock() {
        onToggleDock()
    }

    @objc private func handleOpenCommandPalette() {
        onOpenCommandPalette()
    }

    @objc private func handleOpenTaskbarPreview() {
        onOpenTaskbarPreview()
    }

    @objc private func handleOpenSystemMonitor() {
        onOpenSystemMonitor()
    }

    @objc private func handleToggleAutoHide() {
        onToggleAutoHide()
    }

    @objc private func handleSetLeftEdge() {
        onChangeEdge(.left)
    }

    @objc private func handleSetRightEdge() {
        onChangeEdge(.right)
    }

    @objc private func handleSetTopEdge() {
        onChangeEdge(.top)
    }

    @objc private func handleSetBottomEdge() {
        onChangeEdge(.bottom)
    }

    @objc private func handleSelectTheme(_ sender: NSMenuItem) {
        if let style = sender.representedObject as? DockMaterialStyle {
            onSelectTheme(style)
        }
    }

    @objc private func handleOpenSettings() {
        onOpenSettings()
    }

    @objc private func handleExportBackup() {
        onExportBackup()
    }

    @objc private func handleImportBackup() {
        onImportBackup()
    }

    @objc private func handleQuit() {
        onQuit()
    }
}
