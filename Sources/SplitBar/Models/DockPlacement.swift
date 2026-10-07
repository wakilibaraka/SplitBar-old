import Foundation

public enum DockEdge: String, Codable, CaseIterable, Sendable {
    case left
    case right
    case top
    case bottom
}

public struct DockPlacement: Codable, Equatable, Sendable {
    public var edge: DockEdge
    public var verticalOffsetFraction: Double
    public var autoHide: Bool

    public init(
        edge: DockEdge,
        verticalOffsetFraction: Double,
        autoHide: Bool
    ) {
        self.edge = edge
        self.verticalOffsetFraction = verticalOffsetFraction
        self.autoHide = autoHide
    }
}
