import Foundation

public enum AppAction: Equatable, Sendable {
    case addItem(DockItem)
    case removeItem(id: UUID)
    case moveItem(sourceID: UUID, destinationID: UUID)
    case selectItem(id: UUID?)
    case updatePlacement(DockPlacement)
    case revealDock
    case hideDock
    case flyout(FlyoutAction)
}
