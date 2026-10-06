import AppKit
import Foundation
import SwiftUI

final class NonActivatingTaskbarPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

struct TaskbarPanelRequest {
    var strip: AnyView
    var islands: TaskbarStrip.IslandLayout?
    var islandContent: (Int, [TaskbarSection]) -> AnyView

    init(
        strip: AnyView,
        islands: TaskbarStrip.IslandLayout? = nil,
        islandContent: @escaping (Int, [TaskbarSection]) -> AnyView
    ) {
        self.strip = strip
        self.islands = islands
        self.islandContent = islandContent
    }
}

@MainActor
public final class TaskbarPanelController {
    private var panels: [String: NonActivatingTaskbarPanel] = [:]
    private var hostingViews: [String: NSHostingView<AnyView>] = [:]
    private var panelFrames: [String: CGRect] = [:]
    private var enabledDisplayIDs: Set<String> = []
    private var screenObserver: NSObjectProtocol?
    private var workspaceObservers: [NSObjectProtocol] = []
    private let screenService = ScreenService()
    private let fullscreenMonitor = FullscreenMonitor()
    private var lastHeight: CGFloat = 46
    private var lastRequest: TaskbarPanelRequest?
    private var requestProvider: (() -> TaskbarPanelRequest)?

    public var onFullscreenBegan: (() -> Void)?

    public init() {}

    public var isShown: Bool {
        panels.values.contains { $0.isVisible }
    }

    public var currentFrame: CGRect? {
        let visible = panels.filter { $0.value.isVisible && enabledDisplayIDs.contains($0.key) }
        guard !visible.isEmpty else { return nil }
        return visible.values.reduce(into: CGRect.null) { $0 = $0.union($1.frame) }
    }

    func show(content: AnyView, height: CGFloat) {
        lastHeight = height
        let request = TaskbarPanelRequest(strip: content, islandContent: { _, _ in AnyView(EmptyView()) })
        requestProvider = nil
        show(request)
    }

    func show(provider: @escaping () -> TaskbarPanelRequest) {
        requestProvider = provider
        refresh()
    }

    public func refresh() {
        guard let requestProvider else {
            guard let lastRequest else { return }
            show(lastRequest)
            return
        }
        show(requestProvider())
    }

    func show(_ request: TaskbarPanelRequest) {
        enabledDisplayIDs = Set(
            screenService.primaryScreen().map { [$0.identifier] } ?? []
        )
        var wantedKeys = Set<String>()
        for identifier in enabledDisplayIDs {
            if let islands = request.islands, !islands.islands.isEmpty {
                for (index, island) in islands.islands.enumerated() {
                    let key = "\(identifier)#\(index)"
                    wantedKeys.insert(key)
                    ensurePanel(
                        key: key,
                        displayID: identifier,
                        content: request.islandContent(index, island.sections),
                        frame: islandFrame(displayID: identifier, island: island.frame)
                    )
                }
            } else {
                let key = "\(identifier)#strip"
                wantedKeys.insert(key)
                ensurePanel(
                    key: key,
                    displayID: identifier,
                    content: request.strip,
                    frame: stripFrame(displayID: identifier, height: lastHeight)
                )
            }
        }
        for key in panels.keys where !wantedKeys.contains(key) {
            panels[key]?.orderOut(nil)
            panelFrames[key] = nil
        }
        startObservingChanges()
        refreshFullscreenVisibility()
    }

    public func updateHeight(_ height: CGFloat) {
        lastHeight = height
        refresh()
    }

    public func hide() {
        stopObservingChanges()
        enabledDisplayIDs = []
        panelFrames = [:]
        for panel in panels.values {
            panel.orderOut(nil)
        }
    }

    public func refreshFullscreenVisibility() {
        let fullscreenIDs = fullscreenMonitor.fullscreenDisplayIdentifiers()
        for (key, panel) in panels {
            guard enabledDisplayIDs.contains(displayID(forKey: key)) else {
                panel.orderOut(nil)
                continue
            }
            if fullscreenIDs.contains(displayID(forKey: key)) {
                if panel.isVisible {
                    panel.orderOut(nil)
                    onFullscreenBegan?()
                }
            } else if !panel.isVisible, let content = hostingViews[key]?.rootView {
                if let frame = panelFrames[key] {
                    panel.setFrame(frame, display: false, animate: false)
                }
                panel.orderFrontRegardless()
                hostingViews[key]?.rootView = content
            }
        }
    }

    private func displayID(forKey key: String) -> String {
        String(key.split(separator: "#").first ?? "")
    }

    private func ensurePanel(key: String, displayID: String, content: AnyView, frame: CGRect) {
        let panel: NonActivatingTaskbarPanel
        if let existing = panels[key] {
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
            hostingViews[key] = hostingView
            panels[key] = panel
        }
        hostingViews[key]?.rootView = content
        if panelFrames[key] != frame {
            panel.setFrame(frame, display: true, animate: true)
            panelFrames[key] = frame
        }
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    private func stripFrame(displayID: String, height: CGFloat) -> CGRect {
        let screens = screenService.screens()
        if let screen = screens.first(where: { $0.identifier == displayID }) {
            return edgeActivationFrame(screen: screen, edge: .bottom, thickness: height)
        }
        return CGRect(x: 0, y: 0, width: 1440, height: height)
    }

    private func islandFrame(displayID: String, island: CGRect) -> CGRect {
        let screens = screenService.screens()
        guard let screen = screens.first(where: { $0.identifier == displayID }) else { return island }
        return CGRect(
            x: screen.visibleFrame.minX + island.minX,
            y: screen.visibleFrame.minY + island.minY,
            width: island.width,
            height: island.height
        )
    }

    private func startObservingChanges() {
        guard screenObserver == nil else { return }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
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
