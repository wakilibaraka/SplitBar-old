import AppKit
import Foundation
import SwiftUI

@MainActor
public final class FlyoutPanelController {
    public let panel: KeyablePanel

    public init() {
        let panel = KeyablePanel(
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
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true
        self.panel = panel
    }

    public func show(content: AnyView, frame: CGRect) {
        panel.contentView = makeFixedFrameHostingView(rootView: content)
        panel.setFrame(frame, display: true, animate: false)
        panel.makeKeyAndOrderFront(nil)
    }

    /// Açık flyout'un içeriğini yerinde günceller; aynı hosting view korunduğu için görünümlerin @State'i
    /// (ör. AI görev çıktısı, arama metni) periyodik canlı güncellemelerde sıfırlanmaz.
    public func replace(content: AnyView, frame: CGRect) {
        if let hostingView = panel.contentView as? NSHostingView<AnyView> {
            hostingView.rootView = content
        } else {
            panel.contentView = makeFixedFrameHostingView(rootView: content)
        }
        // Periyodik güncellemelerde boyut aynıysa pencere senkron olarak yeniden çizdirilmez
        if panel.frame != frame {
            panel.setFrame(frame, display: true, animate: false)
        }
    }

    public func hide() {
        panel.orderOut(nil)
    }
}

/// Çerçevesi kod tarafından verilen panel için hosting view üretir. Varsayılan `sizingOptions` içeriğin
/// min/ideal/max boyutunu pencereye kısıt olarak ekler; sabit çerçeveyle çatışınca AppKit'in "Update Constraints"
/// geçişi sonsuz döngüye girip uygulamayı sonlandırır. Boyut yalnızca `setFrame` ile belirlenir.
@MainActor
private func makeFixedFrameHostingView(rootView: AnyView) -> NSHostingView<AnyView> {
    let hostingView = NSHostingView(rootView: rootView)
    hostingView.sizingOptions = []
    return hostingView
}
