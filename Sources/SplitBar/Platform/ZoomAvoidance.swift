import CoreGraphics
import Foundation

// MARK: - ZoomAvoidance
//
// Pure detection math for maximize-avoids-the-taskbar (HYBRID_PLAN D2).
// Coordinates are **AX global space**: top-left origin, y down — the same
// space as `CGWindowListCopyWindowInfo` bounds. In that space the bottom of
// the screen (where the strip lives) is the *larger* y edge of the window.

enum ZoomAvoidance {
    /// True when `windowFrame` fills the visible frame (a zoom/maximize —
    /// green button, ⌘-zoom, or the "Maximize" action from anywhere) within
    /// `tolerance` points on every edge, and the window is tall enough that
    /// removing the strut still leaves a usable window.
    static func shouldReinset(
        windowFrame: CGRect,
        visibleAX: CGRect,
        strut: CGFloat,
        tolerance: CGFloat = 3
    ) -> Bool {
        guard strut > 0 else { return false }
        guard abs(windowFrame.minX - visibleAX.minX) <= tolerance,
              abs(windowFrame.minY - visibleAX.minY) <= tolerance,
              abs(windowFrame.maxX - visibleAX.maxX) <= tolerance,
              abs(windowFrame.maxY - visibleAX.maxY) <= tolerance
        else {
            return false
        }
        return windowFrame.height - strut >= 100
    }

    /// The re-inset frame: the top edge stays, the bottom edge rises above
    /// the strip band. Applying this makes the window stop matching
    /// `visibleAX`, so the observer cannot loop.
    static func insetFrame(_ windowFrame: CGRect, strut: CGFloat) -> CGRect {
        CGRect(
            x: windowFrame.minX,
            y: windowFrame.minY,
            width: windowFrame.width,
            height: max(100, windowFrame.height - max(0, strut))
        )
    }

    /// Cocoa (y-up, origin bottom-left of primary) visible frame → AX global.
    static func visibleAX(fromCocoa visible: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(
            x: visible.minX,
            y: primaryScreenHeight - visible.maxY,
            width: visible.width,
            height: visible.height
        )
    }
}
