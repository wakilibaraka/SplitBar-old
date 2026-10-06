import AppKit
import Foundation
import SwiftUI

final class NonActivatingTaskbarPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
public final class TaskbarPanelController {
    private var panel: NonActivatingTaskbarPanel?
    private var hostingView: NSHostingView<AnyView>?
    private var screenObserver: NSObjectProtocol?
    private let screenService = ScreenService()

    public init() {}

    public var isShown: Bool {
        panel?.isVisible == true
    }

    public var currentFrame: CGRect? {
        panel?.frame
    }

    public func show(content: AnyView, height: CGFloat) {
        if panel == nil {
            createPanel()
        }
        guard let panel else { return }
        hostingView?.rootView = content
        panel.setFrame(panelFrame(height: height), display: true, animate: false)
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
        startObservingScreenChanges()
    }

    public func updateHeight(_ height: CGFloat) {
        guard let panel, panel.isVisible else { return }
        let frame = panelFrame(height: height)
        if panel.frame != frame {
            panel.setFrame(frame, display: true, animate: true)
        }
    }

    public func hide() {
        stopObservingScreenChanges()
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let panel = NonActivatingTaskbarPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = edgePanelCollectionBehavior()
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true
        let hostingView = NSHostingView(rootView: AnyView(EmptyView()))
        hostingView.sizingOptions = []
        panel.contentView = hostingView
        self.hostingView = hostingView
        self.panel = panel
    }

    private func panelFrame(height: CGFloat) -> CGRect {
        guard let screen = screenService.primaryScreen() else {
            return CGRect(x: 0, y: 0, width: 1440, height: height)
        }
        return edgeActivationFrame(screen: screen, edge: .bottom, thickness: height)
    }

    private func startObservingScreenChanges() {
        guard screenObserver == nil else { return }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, let panel = self.panel, panel.isVisible else { return }
                panel.setFrame(self.panelFrame(height: panel.frame.height), display: true, animate: false)
            }
        }
    }

    private func stopObservingScreenChanges() {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
    }
}
