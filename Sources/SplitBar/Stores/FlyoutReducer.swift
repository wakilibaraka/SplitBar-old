import Foundation

public func reduceFlyout(state: FlyoutState, action: FlyoutAction) -> FlyoutState {
    switch action {
    case .open(let id):
        return FlyoutState(activeItemID: id, isVisible: true)
    case .switchTo(let id):
        return FlyoutState(activeItemID: id, isVisible: true)
    case .close:
        return FlyoutState(activeItemID: nil, isVisible: false)
    }
}
