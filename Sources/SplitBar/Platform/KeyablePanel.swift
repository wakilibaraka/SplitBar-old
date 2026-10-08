import AppKit
import Foundation

/// An NSPanel subclass that allows borderless, non-activating floating panels
/// to become key window when interacted with, enabling text fields, focus rings,
/// copy/paste shortcuts, and mouse clicks.
open class KeyablePanel: NSPanel {
    /// Fired when this panel loses key status — app switch (cmd-tab), another
    /// SplitBar window taking key, etc. Flyouts use it to dismiss cleanly
    /// (HYBRID_PLAN C2). Ignored while the panel is not visible so ordering
    /// out does not re-enter dismissal.
    var onResignKey: (() -> Void)?

    override open var canBecomeKey: Bool {
        return true
    }

    override open var canBecomeMain: Bool {
        return true
    }

    override open func resignKey() {
        super.resignKey()
        if isVisible {
            onResignKey?()
        }
    }
}
