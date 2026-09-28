import Foundation

public struct ShortcutChord: Codable, Equatable, Hashable, Sendable {
    public let carbonKeyCode: UInt32
    public let carbonModifiers: UInt32

    public init(
        carbonKeyCode: UInt32,
        carbonModifiers: UInt32
    ) {
        self.carbonKeyCode = carbonKeyCode
        self.carbonModifiers = carbonModifiers
    }
}
