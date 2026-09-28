import Foundation

public enum DockEdge: String, Codable, CaseIterable, Sendable {
    case left
    case right
    case top
}

public struct DockPlacement: Codable, Equatable, Sendable {
    public let edge: DockEdge
    public let verticalOffsetFraction: Double
    public let autoHide: Bool

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
