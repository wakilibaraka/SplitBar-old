import CoreGraphics
import Foundation

// MARK: - WindowTracking
//
// The AX (Accessibility) seam — HYBRID_PLAN B2. Shell *policy* code
// (tiling, maximize avoidance, focus rules) talks to this protocol;
// `WindowManagerService` is the single production implementation and tests
// can inject a fake. Anything undocumented or private stays behind
// implementations of this seam and stays feature-detected (CLAUDE.md).
//
// Coordinate contract: frames are in **screen coordinates, top-left origin,
// y down** — the same space as `CGWindowListCopyWindowInfo` bounds and
// SwiftUI/AppKit window conversion done at the call site.

public protocol WindowTracking: AnyObject {
    /// Whether the process holds the Accessibility permission.
    func isAccessibilityGranted() -> Bool
    /// Lazily show the system permission prompt (first use, never at launch).
    func promptAccessibilityPermission()

    /// Focused window of the frontmost app, or nil when SplitBar itself is
    /// frontmost, no window is focused, or AX is unavailable.
    func frontmostWindowFrame() -> CGRect?

    /// Move and resize the frontmost app's focused window. Applies position →
    /// size → position (counteracting window size constraints).
    @discardableResult
    func setFrontmostWindowFrame(_ frame: CGRect) -> Bool

    @discardableResult
    func raiseWindow(_ info: AppWindowInfo) -> Bool

    @discardableResult
    func minimizeWindows(bundleIdentifier: String) -> Bool

    @discardableResult
    func tileFrontmostWindow(action: WindowTilingAction) -> Bool
}
