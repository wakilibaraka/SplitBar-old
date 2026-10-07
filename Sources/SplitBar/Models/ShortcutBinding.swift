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

    public var title: String {
        switch self {
        case .toggleDock: "Toggle Dock"
        case .focusNext: "Focus next item"
        case .focusPrevious: "Focus previous item"
        case .activateSelected: "Activate selected item"
        case .openAddPanel: "Open add panel"
        case .openClipboard: "Open clipboard"
        case .openCommandPalette: "Open command palette"
        case .activateItem: "Activate item"
        case .tileWindow(.leftHalf): "Tile window left"
        case .tileWindow(.rightHalf): "Tile window right"
        case .tileWindow(.maximize): "Maximize window"
        case .tileWindow(.center): "Center window"
        case .tileWindow: "Tile window"
        }
    }

    /// Actions users may rebind in settings. Item-specific actions are excluded.
    public var isRebindable: Bool {
        switch self {
        case .activateItem: false
        default: true
        }
    }
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
