import AppKit

/// Human-readable label for a shortcut chord, e.g. "⌃⌥←".
func shortcutChordLabel(_ chord: ShortcutChord) -> String {
    var modifiers = ""
    if chord.carbonModifiers & 0x1000 != 0 { modifiers += "⌃" }
    if chord.carbonModifiers & 0x0800 != 0 { modifiers += "⌥" }
    if chord.carbonModifiers & 0x0100 != 0 { modifiers += "⌘" }
    if chord.carbonModifiers & 0x0200 != 0 { modifiers += "⇧" }
    let keys: [UInt32: String] = [
        0x00: "A", 0x0B: "B", 0x08: "C", 0x02: "D", 0x0E: "E", 0x03: "F",
        0x05: "G", 0x04: "H", 0x22: "I", 0x26: "J", 0x28: "K", 0x25: "L",
        0x2E: "M", 0x2D: "N", 0x1F: "O", 0x23: "P", 0x0C: "Q", 0x0F: "R",
        0x01: "S", 0x11: "T", 0x20: "U", 0x09: "V", 0x0D: "W", 0x07: "X",
        0x10: "Y", 0x06: "Z",
        0x1D: "0", 0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4",
        0x17: "5", 0x16: "6", 0x1A: "7", 0x1C: "8", 0x19: "9",
        0x31: "Space", 0x33: "⌫", 0x24: "↩", 0x30: "⇥", 0x35: "⎋",
        0x7B: "←", 0x7C: "→", 0x7D: "↓", 0x7E: "↑",
    ]
    return modifiers + (keys[chord.carbonKeyCode] ?? String(format: "Key 0x%02X", chord.carbonKeyCode))
}


/// Carbon modifier flags from a key-down event's modifier flags.
func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var result: UInt32 = 0
    if flags.contains(.control) { result |= 0x1000 }
    if flags.contains(.option) { result |= 0x0800 }
    if flags.contains(.command) { result |= 0x0100 }
    if flags.contains(.shift) { result |= 0x0200 }
    return result
}
