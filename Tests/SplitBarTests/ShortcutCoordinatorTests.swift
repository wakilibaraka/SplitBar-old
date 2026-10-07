import Combine
import Foundation
import Testing

@testable import SplitBar

private final class SpyShortcutService: GlobalShortcutRegistering {
    private(set) var registeredBindings: [[ShortcutBinding]] = []
    private var handler: (@Sendable (ShortcutAction) -> Void)?

    func register(
        bindings: [ShortcutBinding],
        handler: @escaping @Sendable (ShortcutAction) -> Void
    ) -> [ShortcutRegistrationResult] {
        registeredBindings.append(bindings)
        self.handler = handler
        return []
    }

    func trigger(_ action: ShortcutAction) {
        handler?(action)
    }
}

@MainActor
private final class SpyRoute: ShortcutActionRouting {
    var dockItemIDs: [UUID] = []
    var selectedItemID: UUID?
    var clipboardItemID: UUID?

    private(set) var toggledDock = 0
    private(set) var openedAddPanel = 0
    private(set) var openedCommandPalette = 0
    private(set) var selected: [UUID] = []

    func clearSelections() { selected = [] }
    private(set) var tiled: [WindowTilingAction] = []

    func toggleDockVisibility() { toggledDock += 1 }
    func openAddPanel() { openedAddPanel += 1 }
    func openCommandPalette() { openedCommandPalette += 1 }
    /// Selecting an item moves the selection, as dispatching does in the app.
    func selectItem(id: UUID) {
        selected.append(id)
        selectedItemID = id
    }
    func tileFrontmostWindow(action: WindowTilingAction) { tiled.append(action) }
}

@Suite("Shortcut coordinator")
@MainActor
struct ShortcutCoordinatorTests {
    private func makeCoordinator() -> (ShortcutCoordinator, SpyShortcutService, SpyRoute) {
        let service = SpyShortcutService()
        let route = SpyRoute()
        return (ShortcutCoordinator(service: service), service, route)
    }

    @Test("the current bindings are registered as soon as observation starts") func registersCurrentBindings() {
        let (coordinator, service, route) = makeCoordinator()
        let bindings = [
            ShortcutBinding(id: UUID(), chord: ShortcutChord(carbonKeyCode: 2, carbonModifiers: 256), action: .toggleDock),
        ]
        let subject = CurrentValueSubject<[ShortcutBinding], Never>(bindings)

        coordinator.start(observing: subject.eraseToAnyPublisher())

        #expect(service.registeredBindings.count == 1)
        #expect(service.registeredBindings.first?.count == 1)
        route.selectedItemID = nil
    }

    @Test("changing the bindings re-registers, and an identical value does not") func reregistersOnlyOnChange() {
        let (coordinator, service, _) = makeCoordinator()
        let subject = CurrentValueSubject<[ShortcutBinding], Never>([])
        coordinator.start(observing: subject.eraseToAnyPublisher())
        #expect(service.registeredBindings.count == 1)

        subject.send([])
        #expect(service.registeredBindings.count == 1, "an unchanged value must not rebuild every shortcut")

        subject.send([
            ShortcutBinding(id: UUID(), chord: ShortcutChord(carbonKeyCode: 2, carbonModifiers: 256), action: .toggleDock),
        ])
        #expect(service.registeredBindings.count == 2)
    }

    @Test("focus moves one item and stops at both ends") func focusClampsAtEnds() {
        let (coordinator, _, route) = makeCoordinator()
        coordinator.route(to: route)
        let ids = [UUID(), UUID(), UUID()]
        route.dockItemIDs = ids

        route.selectedItemID = ids[0]
        coordinator.handle(.focusNext)
        coordinator.handle(.focusNext)
        coordinator.handle(.focusNext)
        #expect(route.selected == [ids[1], ids[2], ids[2]], "focus stops at the last item")

        route.clearSelections()
        route.selectedItemID = ids[2]
        coordinator.handle(.focusPrevious)
        coordinator.handle(.focusPrevious)
        coordinator.handle(.focusPrevious)
        #expect(route.selected == [ids[1], ids[0], ids[0]], "focus stops at the first item")
    }

    @Test("focus with nothing selected lands on the first item") func focusWithNoSelection() {
        let (coordinator, _, route) = makeCoordinator()
        coordinator.route(to: route)
        let ids = [UUID(), UUID()]
        route.dockItemIDs = ids
        route.selectedItemID = nil

        coordinator.handle(.focusNext)

        #expect(route.selected == [ids[0]])
    }

    @Test("focus does nothing when the dock is empty") func focusWithEmptyDock() {
        let (coordinator, _, route) = makeCoordinator()
        coordinator.route(to: route)
        route.dockItemIDs = []

        coordinator.handle(.focusNext)
        coordinator.handle(.focusPrevious)
        coordinator.handle(.activateSelected)

        #expect(route.selected.isEmpty)
    }

    @Test("a selection that is no longer in the dock is treated as no selection") func staleSelection() {
        let (coordinator, _, route) = makeCoordinator()
        coordinator.route(to: route)
        let ids = [UUID(), UUID()]
        route.dockItemIDs = ids
        route.selectedItemID = UUID()

        coordinator.handle(.focusNext)

        #expect(route.selected == [ids[0]], "an unknown selection must not index out of range")
    }

    @Test("actions route to the app behaviours behind them") func routesActions() {
        let (coordinator, _, route) = makeCoordinator()
        coordinator.route(to: route)
        let ids = [UUID()]
        route.dockItemIDs = ids
        let clipboardID = UUID()
        route.clipboardItemID = clipboardID
        route.selectedItemID = ids[0]

        coordinator.handle(.toggleDock)
        coordinator.handle(.openAddPanel)
        coordinator.handle(.openCommandPalette)
        coordinator.handle(.activateSelected)
        coordinator.handle(.activateItem(clipboardID))
        coordinator.handle(.openClipboard)
        coordinator.handle(.tileWindow(.leftHalf))

        #expect(route.toggledDock == 1)
        #expect(route.openedAddPanel == 1)
        #expect(route.openedCommandPalette == 1)
        #expect(route.tiled == [.leftHalf])
        #expect(route.selected == [ids[0], clipboardID, clipboardID])
    }

    @Test("opening the clipboard without a clipboard widget does nothing") func openClipboardWithoutWidget() {
        let (coordinator, _, route) = makeCoordinator()
        coordinator.route(to: route)
        route.dockItemIDs = [UUID()]
        route.clipboardItemID = nil

        coordinator.handle(.openClipboard)

        #expect(route.selected.isEmpty)
    }

    @Test("a triggered shortcut reaches the routing rules") func triggerRoutesAction() async throws {
        let (coordinator, service, route) = makeCoordinator()
        coordinator.route(to: route)
        let subject = CurrentValueSubject<[ShortcutBinding], Never>([])
        coordinator.start(observing: subject.eraseToAnyPublisher())

        service.trigger(.toggleDock)

        // The service calls back off the main actor; the coordinator hops.
        for _ in 0..<100 where route.toggledDock == 0 {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(route.toggledDock == 1)
    }
}
