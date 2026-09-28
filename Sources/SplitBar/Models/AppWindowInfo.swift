import CoreGraphics
import Foundation

public struct AppWindowInfo: Identifiable, Sendable {
    public let id: CGWindowID
    public let title: String
    public let bounds: CGRect
    public let ownerPID: pid_t
    public let ownerName: String

    public init(
        id: CGWindowID,
        title: String,
        bounds: CGRect,
        ownerPID: pid_t,
        ownerName: String
    ) {
        self.id = id
        self.title = title
        self.bounds = bounds
        self.ownerPID = ownerPID
        self.ownerName = ownerName
    }
}
