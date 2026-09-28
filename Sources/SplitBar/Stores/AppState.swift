import Foundation

public struct AppState: Equatable, Sendable {
    public let dockItems: [DockItem]
    public let selectedItemID: UUID?
    public let placement: DockPlacement
    public let isDockRevealed: Bool
    public let flyout: FlyoutState

    public init(
        dockItems: [DockItem],
        selectedItemID: UUID?,
        placement: DockPlacement,
        isDockRevealed: Bool,
        flyout: FlyoutState
    ) {
        self.dockItems = dockItems
        self.selectedItemID = selectedItemID
        self.placement = placement
        self.isDockRevealed = isDockRevealed
        self.flyout = flyout
    }
}
