import AppKit
import Foundation
import SwiftUI

private final class EdgeActivationTrackingView: NSView {
    private let onReveal: () -> Void
    private var trackingArea: NSTrackingArea?

    init(onReveal: @escaping () -> Void) {
        self.onReveal = onReveal
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        onReveal()
    }
}

/// Dock gizliyken kenarda görünen cam tutamaç; seçili temayı izler.
struct EdgeHandleView: View {
    let edge: DockEdge
    let style: DockMaterialStyle

    var body: some View {
        let isVertical = edge != .top
        ZStack {
            ThemedGlassBackground(style: style, cornerRadius: 8.0)
            Group {
                if isVertical {
                    VStack(spacing: 5.0) { dots }
                } else {
                    HStack(spacing: 5.0) { dots }
                }
            }
        }
        .dockTheme(style)
    }

    private var dots: some View {
        ForEach(0..<3, id: \.self) { _ in
            Circle()
                .fill(Color.primary.opacity(0.75))
                .frame(width: 3.5, height: 3.5)
        }
    }
}

@MainActor
public final class EdgePanelController {
    public let dockPanel: NSPanel
    public let activationPanel: NSPanel
    private let onReveal: () -> Void
    private let handleHostingView: NSHostingView<EdgeHandleView>
    /// Üst üste binen aç/kapa animasyonlarında yalnızca en son isteğin tamamlanma işlemi uygulanır.
    private var animationGeneration: Int = 0
    private static let revealDuration: TimeInterval = 0.32
    private static let hideDuration: TimeInterval = 0.24
    private static let slideDistance: CGFloat = 28.0

    public init(onReveal: @escaping () -> Void) {
        self.onReveal = onReveal
        self.handleHostingView = NSHostingView(rootView: EdgeHandleView(edge: .right, style: .system))

        let collectionBehavior = edgePanelCollectionBehavior()

        let dock = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        dock.isFloatingPanel = true
        dock.level = .floating
        dock.collectionBehavior = collectionBehavior
        dock.isOpaque = false
        dock.backgroundColor = .clear
        dock.hasShadow = false
        dock.hidesOnDeactivate = false
        dock.acceptsMouseMovedEvents = true
        self.dockPanel = dock

        let activation = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        activation.isFloatingPanel = true
        activation.level = .floating
        activation.collectionBehavior = collectionBehavior
        activation.isOpaque = false
        activation.backgroundColor = .clear
        activation.hasShadow = false
        activation.hidesOnDeactivate = false
        activation.acceptsMouseMovedEvents = true

        // Tutamaç görünümünün üstünde, fareyi algılayan şeffaf izleme katmanı
        let container = NSView(frame: .zero)
        let trackingView = EdgeActivationTrackingView(onReveal: onReveal)
        for view in [handleHostingView, trackingView] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                view.topAnchor.constraint(equalTo: container.topAnchor),
                view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
        }
        activation.contentView = container
        self.activationPanel = activation
    }

    /// Dock'un gizliyken kenara doğru kayacağı yön.
    private func slideOffset(for edge: DockEdge) -> CGVector {
        switch edge {
        case .right:
            return CGVector(dx: Self.slideDistance, dy: 0.0)
        case .left:
            return CGVector(dx: -Self.slideDistance, dy: 0.0)
        case .top:
            return CGVector(dx: 0.0, dy: Self.slideDistance)
        }
    }

    private func setHandleVisible(_ visible: Bool, duration: TimeInterval) {
        activationPanel.ignoresMouseEvents = !visible
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            activationPanel.animator().alphaValue = visible ? 1.0 : 0.0
        }
    }

    /// Çerçeve değişmediyse pencereyi yeniden boyutlandırıp senkron olarak yeniden çizmez; her dispatch'te çağrılır.
    /// Gizliyken açılıyorsa dock kenardan kayarak ve belirerek gelir.
    public func show(frame: CGRect, edge: DockEdge) {
        guard !dockPanel.isVisible || dockPanel.alphaValue < 1.0 else {
            if dockPanel.frame != frame {
                dockPanel.setFrame(frame, display: true, animate: false)
            }
            return
        }
        animationGeneration += 1
        let offset = slideOffset(for: edge)
        dockPanel.alphaValue = 0.0
        dockPanel.setFrame(frame.offsetBy(dx: offset.dx, dy: offset.dy), display: true, animate: false)
        dockPanel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.revealDuration
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.25, 1.0)
            dockPanel.animator().setFrame(frame, display: true)
            dockPanel.animator().alphaValue = 1.0
        }
        setHandleVisible(false, duration: Self.revealDuration * 0.6)
    }

    /// Dock kenara doğru kayarak kaybolur; ardından tutamaç (auto-hide açıksa) belirir.
    public func hide(edge: DockEdge) {
        guard dockPanel.isVisible else { return }
        animationGeneration += 1
        let generation = animationGeneration
        let restingFrame = dockPanel.frame
        let offset = slideOffset(for: edge)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.hideDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            dockPanel.animator().setFrame(restingFrame.offsetBy(dx: offset.dx, dy: offset.dy), display: true)
            dockPanel.animator().alphaValue = 0.0
        } completionHandler: {
            MainActor.assumeIsolated {
                // Bu arada yeniden açıldıysa gizleme uygulanmaz
                guard generation == self.animationGeneration else { return }
                self.dockPanel.orderOut(nil)
                self.dockPanel.setFrame(restingFrame, display: false, animate: false)
                self.dockPanel.alphaValue = 1.0
            }
        }
        if activationPanel.isVisible {
            setHandleVisible(true, duration: Self.hideDuration * 1.4)
        }
    }

    public func reposition(frame: CGRect) {
        dockPanel.setFrame(frame, display: true, animate: false)
    }

    /// Auto-hide açıkken kenardaki tutamacı konumlandırır; dock görünürken tutamaç sönük ve tıklanamaz kalır.
    public func setAutoHide(enabled: Bool, handleFrame: CGRect, edge: DockEdge, style: DockMaterialStyle) {
        guard enabled else {
            if activationPanel.isVisible {
                activationPanel.orderOut(nil)
            }
            return
        }
        handleHostingView.rootView = EdgeHandleView(edge: edge, style: style)
        if activationPanel.frame != handleFrame {
            activationPanel.setFrame(handleFrame, display: true, animate: false)
        }
        if !activationPanel.isVisible {
            let dockShowing = dockPanel.isVisible && dockPanel.alphaValue > 0.0
            activationPanel.alphaValue = dockShowing ? 0.0 : 1.0
            activationPanel.ignoresMouseEvents = dockShowing
            activationPanel.orderFrontRegardless()
        }
    }

    public func setContentView(_ view: NSView) {
        dockPanel.contentView = view
    }
}
