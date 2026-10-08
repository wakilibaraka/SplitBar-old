import CoreGraphics
import Foundation

// MARK: - FlyoutDismissal
//
// The single dismissal rule shared by every flyout event monitor
// (HYBRID_PLAN C2). Pure so the outside-click behavior is unit-testable
// instead of being re-derived inside four different closures.

enum FlyoutDismissal {
    /// A click at `location` (screen coordinates, y-down — `NSEvent.mouseLocation`)
    /// dismisses the open flyout unless it landed on the flyout itself or on
    /// another shell surface that owns its own click handling (the taskbar
    /// strip, the dock panel — their buttons toggle panels themselves).
    static func shouldDismiss(location: CGPoint, protected: [CGRect]) -> Bool {
        !protected.contains(where: { $0.contains(location) })
    }

    /// Protected frames for the taskbar flyouts (settings/start/controls/
    /// calendar/widgets): the flyout if visible, plus the strip.
    static func protectedFrames(flyoutFrame: CGRect?, flyoutVisible: Bool, stripFrame: CGRect?) -> [CGRect] {
        var frames: [CGRect] = []
        if flyoutVisible, let flyoutFrame { frames.append(flyoutFrame) }
        if let stripFrame, stripFrame != .zero { frames.append(stripFrame) }
        return frames
    }
}
