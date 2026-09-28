import Foundation

public struct FlyoutState: Equatable, Sendable {
    public let activeItemID: UUID?
    public let isVisible: Bool

    public init(
        activeItemID: UUID?,
        isVisible: Bool
    ) {
        self.activeItemID = activeItemID
        self.isVisible = isVisible
    }
}

public enum FlyoutAction: Equatable, Sendable {
    case open(UUID)
    case switchTo(UUID)
    case close
}
