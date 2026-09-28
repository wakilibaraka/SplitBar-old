import Foundation

public struct ClipboardRetentionPolicy: Codable, Equatable, Sendable {
    public let maxEntries: Int
    public let maxBlobBytes: Int

    public init(
        maxEntries: Int,
        maxBlobBytes: Int
    ) {
        self.maxEntries = maxEntries
        self.maxBlobBytes = maxBlobBytes
    }
}
