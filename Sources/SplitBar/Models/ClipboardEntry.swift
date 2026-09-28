import Foundation

public enum ClipboardPayloadDescriptor: Codable, Equatable, Sendable {
    case text(String)
    case url(URL)
    case imageBlob(relativePath: String, byteCount: Int)
    case fileURLs([URL])
}

public struct ClipboardEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let sourceBundleIdentifier: String?
    public let isPinned: Bool
    public let searchableText: String
    public let payload: ClipboardPayloadDescriptor

    public init(
        id: UUID,
        timestamp: Date,
        sourceBundleIdentifier: String?,
        isPinned: Bool,
        searchableText: String,
        payload: ClipboardPayloadDescriptor
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.isPinned = isPinned
        self.searchableText = searchableText
        self.payload = payload
    }
}
