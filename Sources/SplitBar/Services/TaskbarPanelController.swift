import AppKit
import Foundation
import SwiftUI

final class NonActivatingTaskbarPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
public final class TaskbarPanelController {
    private var panels: [String: NonActivatingTaskbarPanel] = [:]
    private var hostingViews: [String: NSHostingView<AnyView>] = [:]
    private var enabledDisplayIDs: Set<String> = []
    private var screenObserver: NSObjectProtocol?
    private var workspaceObservers: [NSObjectProtocol] = []
    private let screenService = ScreenService()
    private let fullscreenMonitor = FullscreenMonitor()
    private var lastHeight: CGFloat = 46

    public var onFullscreenBegan: (() -> Void)?

    public init() {}

    public var isShown: Bool {
        panels.values.contains { $0.isVisible }
    }

    public var currentFrame: CGRect? {
        panels.values.first(where: { $0.isVisible })?.frame
    }

    public func show(content: AnyView, height: CGFloat) {
        lastHeight = height
        enabledDisplayIDs = Set(
            screenService.primaryScreen().map { [$0.identifier] } ?? []
        )
        for identifier in enabledDisplayIDs {
            ensurePanel(displayID: identifier, content: content, height: height)
        }
        for identifier in panels.keys where !enabledDisplayIDs.contains(identifier) {
            panels[identifier]?.orderOut(nil)
        }
        startObservingChanges()
        refreshFullscreenVisibility()
    }

    public func updateHeight(_ height: CGFloat) {
        lastHeight = height
        for (identifier, panel) in panels where enabledDisplayIDs.contains(identifier) {
            let frame = panelFrame(displayID: identifier, height: height)
            if panel.frame != frame {
                panel.setFrame(frame, display: true, animate: true)
            }
        }
    }

    public func hide() {
        stopObservingChanges()
        enabledDisplayIDs = []
        for panel in panels.values {
            panel.orderOut(nil)
        }
    }

    public func refreshFullscreenVisibility() {
        let fullscreenIDs = fullscreenMonitor.fullscreenDisplayIdentifiers()
        for (identifier, panel) in panels {
            guard enabledDisplayIDs.contains(identifier) else {
                panel.orderOut(nil)
                continue
            }
            if fullscreenIDs.contains(identifier) {
                if panel.isVisible {
                    panel.orderOut(nil)
                    onFullscreenBegan?()
                }
            } else if !panel.isVisible, let content = hostingViews[identifier]?.rootView {
                panel.setFrame(panelFrame(displayID: identifier, height: lastHeight), display: false, animate: false)
                panel.orderFrontRegardless()
                hostingViews[identifier]?.rootView = content
            }
        }
    }

    private func ensurePanel(displayID: String, content: AnyView, height: CGFloat) {
        let panel: NonActivatingTaskbarPanel
        if let existing = panels[displayID] {
            panel = existing
        } else {
            panel = NonActivatingTaskbarPanel(
                contentRect: .zero,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = taskbarStripCollectionBehavior()
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.hidesOnDeactivate = false
            panel.acceptsMouseMovedEvents = true
            let hostingView = NSHostingView(rootView: AnyView(EmptyView()))
            hostingView.sizingOptions = []
            panel.contentView = hostingView
            hostingViews[displayID] = hostingView
            panels[displayID] = panel
        }
        hostingViews[displayID]?.rootView = content
        panel.setFrame(panelFrame(displayID: displayID, height: height), display: true, animate: false)
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    private func panelFrame(displayID: String, height: CGFloat) -> CGRect {
        let screens = screenService.screens()
        if let screen = screens.first(where: { $0.identifier == displayID }) {
            return edgeActivationFrame(screen: screen, edge: .bottom, thickness: height)
        }
        return CGRect(x: 0, y: 0, width: 1440, height: height)
    }

    private func startObservingChanges() {
        guard screenObserver == nil else { return }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateHeight(self?.lastHeight ?? 46)
            }
        }
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers = [
            workspaceCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshFullscreenVisibility()
                }
            },
            workspaceCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshFullscreenVisibility()
                }
            }
        ]
    }

    private func stopObservingChanges() {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        workspaceObservers = []
    }
}
