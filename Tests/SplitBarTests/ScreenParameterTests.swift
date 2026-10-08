import Testing

@testable import SplitBar
import AppKit
import Foundation

/// Wave 3 (HYBRID_PLAN C3): display-configuration changes must reach the
/// DisplayCoordinator (which drives strip refresh); the AppRuntimeController
/// additionally re-anchors open flyouts and the edge dock on the same
/// notification.
struct ScreenParameterTests {

    private final class Counter: @unchecked Sendable {
        var count = 0
    }

    @MainActor
    @Test func screenParameterChangeReachesCoordinator() async {
        let coordinator = DisplayCoordinator()
        let counter = Counter()
        coordinator.onScreensChanged = { counter.count += 1 }
        coordinator.startObserving()
        defer { coordinator.stopObserving() }

        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // The coordinator hops through Task { @MainActor in } — poll briefly.
        var polls = 0
        while counter.count == 0, polls < 50 {
            try? await Task.sleep(nanoseconds: 20_000_000)
            polls += 1
        }
        #expect(counter.count >= 1)
    }

    @MainActor
    @Test func stopObservingStopsDelivery() async {
        let coordinator = DisplayCoordinator()
        let counter = Counter()
        coordinator.onScreensChanged = { counter.count += 1 }
        coordinator.startObserving()
        coordinator.stopObserving()

        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(counter.count == 0)
    }
}
