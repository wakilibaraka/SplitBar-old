import AppKit
import Foundation

/// An NSPanel subclass that allows borderless, non-activating floating panels
/// to become key window when interacted with, enabling text fields, focus rings,
/// copy/paste shortcuts, and mouse clicks.
open class KeyablePanel: NSPanel {
    override open var canBecomeKey: Bool {
        return true
    }

    override open var canBecomeMain: Bool {
        return true
    }
}
