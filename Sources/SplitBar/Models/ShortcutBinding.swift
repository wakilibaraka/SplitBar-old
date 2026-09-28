import Foundation

public enum ShortcutAction: Codable, Equatable, Sendable {
    case toggleDock
    case focusNext
    case focusPrevious
    case activateSelected
    case openAddPanel
    case openClipboard
    case openCommandPalette
    case activateItem(UUID)
    case tileWindow(WindowTilingAction)
}

public struct ShortcutBinding: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let chord: ShortcutChord
    public let action: ShortcutAction

    public init(
        id: UUID,
        chord: ShortcutChord,
        action: ShortcutAction
    ) {
        self.id = id
        self.chord = chord
        self.action = action
    }
}

public struct ShortcutConflict: Equatable, Sendable {
    public let bindingIDs: Set<UUID>
    public let chord: ShortcutChord

    public init(
        bindingIDs: Set<UUID>,
        chord: ShortcutChord
    ) {
        self.bindingIDs = bindingIDs
        self.chord = chord
    }
}

public enum ShortcutRegistrationResult: Equatable, Sendable {
    case registered(UUID)
    case conflict(ShortcutConflict)
    case systemFailure(UUID, OSStatus)
}
