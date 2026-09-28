import Foundation

public enum DockItemKind: Codable, Equatable, Sendable {
    case application(bundleIdentifier: String, applicationURL: URL)
    case link(url: URL)
    case widget(widgetIdentifier: String)
}

public struct DockItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let kind: DockItemKind

    public init(
        id: UUID,
        name: String,
        kind: DockItemKind
    ) {
        self.id = id
        self.name = name
        self.kind = kind
    }
}
