import Combine
import Foundation
import OSLog

/// Registers global shortcuts and routes the actions they trigger.
///
/// Extracted from `AppRuntimeController`, which held the registration, the
/// subscription that re-registered on every settings change, and the switch that
/// decided what each action does. The routing rules are here because they are the
/// part worth testing: focus stops at the ends of the dock instead of wrapping,
/// and several actions depend on which item is selected.
@MainActor
protocol ShortcutCoordinating: AnyObject {
    func start(observing bindings: AnyPublisher<[ShortcutBinding], Never>)
    func handle(_ action: ShortcutAction)
}

/// What a shortcut action needs from the rest of the app.
///
/// `AppRuntimeController` conforms to this; the tests supply a stub.
@MainActor
protocol ShortcutActionRouting: AnyObject {
    var dockItemIDs: [UUID] { get }
    var selectedItemID: UUID? { get }
    var clipboardItemID: UUID? { get }
    func toggleDockVisibility()
    func openAddPanel()
    func openCommandPalette()
    func selectItem(id: UUID)
    func tileFrontmostWindow(action: WindowTilingAction)
}

/// The registration surface the coordinator needs from the shortcut service.
protocol GlobalShortcutRegistering: AnyObject {
    func register(
        bindings: [ShortcutBinding],
        handler: @escaping @Sendable (ShortcutAction) -> Void
    ) -> [ShortcutRegistrationResult]
}

@MainActor
final class ShortcutCoordinator: ShortcutCoordinating {
    private let service: any GlobalShortcutRegistering
    private weak var routing: (any ShortcutActionRouting)?
    private var subscriptions = Set<AnyCancellable>()

    init(service: any GlobalShortcutRegistering) {
        self.service = service
    }

    /// Attaches the route target.
    ///
    /// Separate from `init` because the runtime is still initialising itself when
    /// its properties are assigned, so it cannot be handed over yet.
    func route(to routing: any ShortcutActionRouting) {
        self.routing = routing
    }

    /// Registers the current bindings and keeps registration in step with them.
    ///
    /// The publisher replays the current value on subscription, so the first
    /// emission registers what the user has right now and later emissions
    /// re-register after a change. `removeDuplicates` stops an unrelated settings
    /// change from tearing down and rebuilding every shortcut.
    func start(observing bindings: AnyPublisher<[ShortcutBinding], Never>) {
        bindings
            .removeDuplicates()
            .sink { [weak self] bindings in
                self?.register(bindings)
            }
            .store(in: &subscriptions)
    }

    func register(_ bindings: [ShortcutBinding]) {
        // Registration results describe conflicts and failures per binding; the
        // settings window reports those from its own state, so they are not
        // consumed here.
        _ = service.register(bindings: bindings) { [weak self] action in
            Logger.shortcuts.debug("Triggered shortcut action")
            Task { @MainActor in
                self?.handle(action)
            }
        }
    }

    /// Turns a triggered action into the app behaviour behind it.
    ///
    /// Focus stops at the ends of the dock rather than wrapping, so holding the
    /// shortcut settles on the last or first item. Every action that needs a
    /// selection is a no-op when the dock is empty, which is what a user with no
    /// items pinned expects.
    func handle(_ action: ShortcutAction) {
        guard let routing else { return }
        switch action {
        case .toggleDock:
            routing.toggleDockVisibility()
        case .focusNext:
            guard let next = stepping(1, in: routing.dockItemIDs, from: routing.selectedItemID) else { return }
            routing.selectItem(id: next)
        case .focusPrevious:
            guard let previous = stepping(-1, in: routing.dockItemIDs, from: routing.selectedItemID) else { return }
            routing.selectItem(id: previous)
        case .activateSelected:
            if let selectedID = routing.selectedItemID {
                routing.selectItem(id: selectedID)
            }
        case .openAddPanel:
            routing.openAddPanel()
        case .openClipboard:
            if let clipboardItemID = routing.clipboardItemID {
                routing.selectItem(id: clipboardItemID)
            }
        case .openCommandPalette:
            routing.openCommandPalette()
        case .activateItem(let id):
            routing.selectItem(id: id)
        case .tileWindow(let tilingAction):
            routing.tileFrontmostWindow(action: tilingAction)
        }
    }

    /// The neighbour `offset` places from `current`, stopping at either end.
    ///
    /// With nothing selected the first item is used, so the shortcut always has a
    /// visible effect on an otherwise idle dock. A selection that is no longer in
    /// the dock is treated the same way, since its index cannot be trusted.
    private func stepping(_ offset: Int, in ids: [UUID], from current: UUID?) -> UUID? {
        guard !ids.isEmpty else { return nil }
        guard let current, let index = ids.firstIndex(of: current) else { return ids[0] }
        let target = min(max(index + offset, 0), ids.count - 1)
        return ids[target]
    }
}

extension GlobalShortcutService: GlobalShortcutRegistering {}
