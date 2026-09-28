import AppKit
import Foundation
import SwiftUI

public struct DockTooltipView: View {
    public let title: String
    public let badge: String?
    public let isRunning: Bool
    public let edge: DockEdge

    public init(
        title: String,
        badge: String?,
        isRunning: Bool,
        edge: DockEdge
    ) {
        self.title = title
        self.badge = badge
        self.isRunning = isRunning
        self.edge = edge
    }

    public var body: some View {
        HStack(spacing: 6.0) {
            if isRunning {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 4.5, height: 4.5)
                    .shadow(color: Color.white.opacity(0.60), radius: 2.0)
            }

            Text(title)
                .font(.system(size: 12.0, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            if let badge = badge, !badge.isEmpty {
                Text(badge)
                    .font(.system(size: 10.0, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.80))
                    .padding(.horizontal, 5.0)
                    .padding(.vertical, 2.0)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                    )
            }
        }
        .padding(.horizontal, 11.0)
        .padding(.vertical, 6.0)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 9.0, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 9.0, style: .continuous)
                    .fill(Color(white: 0.05).opacity(0.90))
                RoundedRectangle(cornerRadius: 9.0, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.85), location: 0.0),
                                .init(color: Color.white.opacity(0.25), location: 0.40),
                                .init(color: Color.white.opacity(0.10), location: 0.70),
                                .init(color: Color.white.opacity(0.50), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.38), radius: 8.0, x: 0.0, y: 3.0)
        .fixedSize()
    }
}

@MainActor
public final class DockTooltipPanelController {
    public let panel: NSPanel
    private var lastTitle: String? = nil

    public init() {
        let p = NSPanel(
            contentRect: CGRect(x: 0.0, y: 0.0, width: 200.0, height: 36.0),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isFloatingPanel = true
        p.level = .popUpMenu
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.hidesOnDeactivate = false
        p.ignoresMouseEvents = true
        self.panel = p
    }

    public func show(
        title: String,
        badge: String?,
        isRunning: Bool,
        anchorFrame: CGRect,
        screenY: CGFloat,
        screenX: CGFloat,
        edge: DockEdge
    ) {
        if lastTitle != title {
            lastTitle = title
            let view = DockTooltipView(
                title: title,
                badge: badge,
                isRunning: isRunning,
                edge: edge
            )
            let hosting = NSHostingView(rootView: view)
            hosting.wantsLayer = true
            panel.contentView = hosting
        }

        guard let contentView = panel.contentView else { return }
        let fittingSize = contentView.fittingSize
        let width = max(60.0, fittingSize.width)
        let height = max(30.0, fittingSize.height)

        let targetX: CGFloat
        let targetY: CGFloat

        switch edge {
        case .left:
            targetX = anchorFrame.maxX + 10.0
            targetY = screenY - (height / 2.0)
        case .right:
            targetX = anchorFrame.minX - width - 10.0
            targetY = screenY - (height / 2.0)
        case .top:
            targetX = screenX - (width / 2.0)
            targetY = anchorFrame.minY - height - 10.0
        }

        panel.setFrame(
            CGRect(x: targetX, y: targetY, width: width, height: height),
            display: true,
            animate: false
        )

        if !panel.isVisible {
            panel.alphaValue = 1.0
            panel.orderFront(nil)
        }
    }

    public func hide() {
        lastTitle = nil
        if panel.isVisible {
            panel.orderOut(nil)
        }
    }
}
