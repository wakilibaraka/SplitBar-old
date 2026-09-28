import Foundation

public func moveDockItem(
    items: [DockItem],
    sourceID: UUID,
    destinationID: UUID
) -> [DockItem] {
    if sourceID == destinationID {
        return items
    }
    guard let sourceIndex = items.firstIndex(where: { $0.id == sourceID }),
          let destinationIndex = items.firstIndex(where: { $0.id == destinationID }) else {
        return items
    }
    var newItems = items
    let movedItem = newItems.remove(at: sourceIndex)
    newItems.insert(movedItem, at: destinationIndex)
    return newItems
}

public func reduce(state: AppState, action: AppAction) -> AppState {
    switch action {
    case .addItem(let item):
        let newItems = state.dockItems + [item]
        return AppState(
            dockItems: newItems,
            selectedItemID: state.selectedItemID,
            placement: state.placement,
            isDockRevealed: state.isDockRevealed,
            flyout: state.flyout
        )
    case .removeItem(let id):
        let newItems = state.dockItems.filter { $0.id != id }
        let newSelectedID = state.selectedItemID == id ? nil : state.selectedItemID
        let newFlyout = state.flyout.activeItemID == id
            ? FlyoutState(activeItemID: nil, isVisible: false)
            : state.flyout
        return AppState(
            dockItems: newItems,
            selectedItemID: newSelectedID,
            placement: state.placement,
            isDockRevealed: state.isDockRevealed,
            flyout: newFlyout
        )
    case .moveItem(let sourceID, let destinationID):
        let newItems = moveDockItem(
            items: state.dockItems,
            sourceID: sourceID,
            destinationID: destinationID
        )
        return AppState(
            dockItems: newItems,
            selectedItemID: state.selectedItemID,
            placement: state.placement,
            isDockRevealed: state.isDockRevealed,
            flyout: state.flyout
        )
    case .selectItem(let id):
        return AppState(
            dockItems: state.dockItems,
            selectedItemID: id,
            placement: state.placement,
            isDockRevealed: state.isDockRevealed,
            flyout: state.flyout
        )
    case .updatePlacement(let placement):
        return AppState(
            dockItems: state.dockItems,
            selectedItemID: state.selectedItemID,
            placement: placement,
            isDockRevealed: state.isDockRevealed,
            flyout: state.flyout
        )
    case .revealDock:
        return AppState(
            dockItems: state.dockItems,
            selectedItemID: state.selectedItemID,
            placement: state.placement,
            isDockRevealed: true,
            flyout: state.flyout
        )
    case .hideDock:
        return AppState(
            dockItems: state.dockItems,
            selectedItemID: state.selectedItemID,
            placement: state.placement,
            isDockRevealed: false,
            flyout: state.flyout
        )
    case .flyout(let flyoutAction):
        let newFlyout = reduceFlyout(state: state.flyout, action: flyoutAction)
        return AppState(
            dockItems: state.dockItems,
            selectedItemID: newFlyout.activeItemID ?? state.selectedItemID,
            placement: state.placement,
            isDockRevealed: state.isDockRevealed,
            flyout: newFlyout
        )
    }
}
