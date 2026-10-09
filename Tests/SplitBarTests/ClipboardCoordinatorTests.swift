import Foundation
import Testing

@testable import SplitBar

/// Records what the coordinator asked of the pasteboard watcher.
private final class SpyMonitor: ClipboardMonitoring {
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var lastInterval: TimeInterval?
    private(set) var lastExcluded: Set<String>?
    private(set) var lastExcludedUpdate: Set<String>?
    private(set) var onNewEntry: ((ClipboardCapture) -> Void)?

    func startMonitoring(
        interval: TimeInterval,
        excludedBundleIdentifiers: Set<String>,
        onNewEntry: @escaping (ClipboardCapture) -> Void
    ) {
        startCount += 1
        lastInterval = interval
        lastExcluded = excludedBundleIdentifiers
        self.onNewEntry = onNewEntry
    }

    func stopMonitoring() {
        stopCount += 1
        onNewEntry = nil
    }

    func updateExcludedBundleIdentifiers(_ identifiers: Set<String>) {
        lastExcludedUpdate = identifiers
    }

    func emit(_ capture: ClipboardCapture) {
        onNewEntry?(capture)
    }
}

/// Records disk work, and can be made to fail.
private final class SpyPersistence: ClipboardPersisting {
    nonisolated(unsafe) private(set) var savedHistories: [[ClipboardEntry]] = []
    nonisolated(unsafe) private(set) var savedBlobs: [(data: Data, path: String)] = []
    nonisolated(unsafe) private(set) var cleanups: [Set<String>] = []
    nonisolated(unsafe) private(set) var quarantined = false
    nonisolated(unsafe) var loadError: Error?
    nonisolated(unsafe) var saveError: Error?

    init(initialHistory: [ClipboardEntry] = []) {
        storedHistory = initialHistory
    }

    nonisolated(unsafe) private var storedHistory: [ClipboardEntry]

    func loadHistory() throws -> [ClipboardEntry] {
        if let loadError { throw loadError }
        return storedHistory
    }

    func saveHistory(_ entries: [ClipboardEntry]) throws {
        if let saveError { throw saveError }
        savedHistories.append(entries)
    }

    func saveBlob(data: Data, relativePath: String) throws {
        if let saveError { throw saveError }
        savedBlobs.append((data, relativePath))
    }

    func loadBlob(relativePath: String) -> Data? {
        Data([0x89, 0x50])
    }

    func cleanupUnreferencedBlobs(referencedPaths: Set<String>) throws {
        cleanups.append(referencedPaths)
    }

    func quarantineCorruptHistory() throws -> URL {
        quarantined = true
        return URL(fileURLWithPath: "/tmp/quarantine.json")
    }
}

private enum TestFailure: Error { case boom }

/// Persistence happens on a background queue, so assertions wait for it rather
/// than assuming it has already run.
private func waitUntil(
    _ description: String,
    timeout: TimeInterval = 2,
    _ condition: () -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() >= deadline {
            Issue.record("timed out waiting for \(description)")
            return
        }
        try await Task.sleep(for: .milliseconds(10))
    }
}

@MainActor
private func makeCoordinator(
    monitor: SpyMonitor,
    persistence: SpyPersistence,
    now: @escaping () -> Date
) -> ClipboardCoordinator {
    ClipboardCoordinator(
        monitor: monitor,
        persistence: persistence,
        // A concurrent queue keeps the test off the calling thread's ordering
        // assumptions, so assertions wait on the persistence spy instead.
        ioQueue: DispatchQueue(label: "clipboard-coordinator-tests"),
        now: now
    )
}

private func settings(
    enabled: Bool = true,
    retention: ClipboardRetentionPolicy = ClipboardRetentionPolicy(maxEntries: 50, maxBlobBytes: 5_000_000),
    excluded: Set<String> = []
) -> ClipboardSettings {
    ClipboardSettings(
        historyEnabled: enabled,
        retention: retention,
        excludedBundleIdentifiers: excluded
    )
}

private func textEntry(_ text: String, pinned: Bool = false) -> ClipboardEntry {
    ClipboardEntry(
        id: UUID(),
        timestamp: Date(timeIntervalSinceNow: -5),
        sourceBundleIdentifier: "com.example.app",
        isPinned: pinned,
        searchableText: text,
        payload: .text(text)
    )
}

@Suite("Clipboard coordinator")
@MainActor
struct ClipboardCoordinatorTests {
    @Test("history stays off and nothing is scheduled when the setting is off") func disabledDoesNotMonitor() {
        let monitor = SpyMonitor()
        let persistence = SpyPersistence()
        let coordinator = makeCoordinator(monitor: monitor, persistence: persistence, now: { Date() })

        coordinator.refreshMonitoring(for: settings(enabled: false))

        #expect(monitor.startCount == 0)
        #expect(monitor.stopCount == 1)
        #expect(monitor.lastInterval == nil)
    }

    @Test("enabling history starts capture with the configured exclusion list") func enabledStartsMonitoring() {
        let monitor = SpyMonitor()
        let coordinator = makeCoordinator(
            monitor: monitor,
            persistence: SpyPersistence(),
            now: { Date() }
        )

        coordinator.refreshMonitoring(for: settings(excluded: ["com.apple.Safari"]))

        #expect(monitor.startCount == 1)
        #expect(monitor.lastInterval == 0.6)
        #expect(monitor.lastExcluded == ["com.apple.Safari"])
    }

    @Test("a pause suppresses capture until its deadline passes") func pauseExpires() {
        let monitor = SpyMonitor()
        var clock = Date(timeIntervalSinceReferenceDate: 1_000)
        let coordinator = ClipboardCoordinator(
            monitor: monitor,
            persistence: SpyPersistence(),
            ioQueue: DispatchQueue(label: "clipboard-coordinator-tests"),
            now: { clock }
        )

        coordinator.refreshMonitoring(for: settings(enabled: true))
        #expect(monitor.startCount == 1)

        coordinator.pause(for: 60)
        #expect(monitor.onNewEntry == nil, "capture stops immediately")

        // A settings change inside the pause window must not resume capture.
        coordinator.refreshMonitoring(for: settings(enabled: true))
        #expect(monitor.startCount == 1, "a pause is not shortened by a settings change")

        // Once the deadline has passed, capture resumes.
        clock = Date(timeIntervalSinceReferenceDate: 1_061)
        coordinator.refreshMonitoring(for: settings(enabled: true))
        #expect(monitor.startCount == 2)
    }

    @Test("turning the setting off stops capture without forgetting the pause") func disablingStopsCapture() {
        let monitor = SpyMonitor()
        let coordinator = makeCoordinator(
            monitor: monitor,
            persistence: SpyPersistence(),
            now: { Date(timeIntervalSinceReferenceDate: 500) }
        )

        coordinator.applySettingsChange(
            from: settings(enabled: false),
            to: settings(enabled: true)
        )
        #expect(monitor.startCount == 1)

        coordinator.applySettingsChange(
            from: settings(enabled: true),
            to: settings(enabled: false)
        )
        #expect(monitor.stopCount == 1)

        // The exclusion list is pushed to the running monitor rather than by a
        // restart, so the timer is not disturbed.
        coordinator.applySettingsChange(
            from: settings(enabled: false),
            to: settings(enabled: false, excluded: ["com.apple.Mail"])
        )
        #expect(monitor.lastExcludedUpdate == ["com.apple.Mail"])
        #expect(monitor.startCount == 1)
    }

    @Test("a capture is merged and reported as a capture change") func captureMergesAndReports() async throws {
        let monitor = SpyMonitor()
        let persistence = SpyPersistence()
        let coordinator = makeCoordinator(monitor: monitor, persistence: persistence, now: { Date() })
        var changes: [ClipboardHistoryChange] = []
        coordinator.historyDidChange = { changes.append($0) }

        coordinator.refreshMonitoring(for: settings())
        let capture = ClipboardCapture(entry: textEntry("first"), imageData: nil)
        monitor.emit(capture)
        // The monitor delivers on its own queue; the coordinator hops to the main
        // actor, so the assertion waits for that hop.
        try await waitUntil("the capture to be merged") { coordinator.history.count == 1 }

        #expect(coordinator.history.count == 1)
        #expect(changes.count == 1)
        if case .captured = changes.first {} else {
            Issue.record("a new capture must report .captured, not .edited")
        }
    }

    @Test("pinning, deleting and clearing persist and report an edit") func editsPersistAndReport() async throws {
        let monitor = SpyMonitor()
        let persistence = SpyPersistence(initialHistory: [
            textEntry("keep", pinned: true),
            textEntry("drop"),
        ])
        let coordinator = makeCoordinator(monitor: monitor, persistence: persistence, now: { Date() })
        var changes: [ClipboardHistoryChange] = []
        coordinator.historyDidChange = { changes.append($0) }

        let target = coordinator.history[1]
        coordinator.togglePin(id: target.id)
        #expect(coordinator.history[1].isPinned)

        coordinator.delete(id: coordinator.history[0].id)
        #expect(coordinator.history.count == 1)
        #expect(coordinator.history.first?.isPinned == true)

        coordinator.clearUnpinned()
        #expect(coordinator.history.count == 1, "a pinned entry survives clearing unpinned")

        coordinator.clearAll()
        #expect(coordinator.history.isEmpty)
        #expect(changes.count == 4)
        try await waitUntil("every edit to reach disk") { persistence.savedHistories.count == 4 }
        #expect(persistence.savedHistories.count == 4, "every edit is written to disk")
    }

    @Test("a corrupt history file is quarantined rather than lost") func corruptHistoryIsQuarantined() {
        let persistence = SpyPersistence()
        persistence.loadError = TestFailure.boom
        let coordinator = makeCoordinator(
            monitor: SpyMonitor(),
            persistence: persistence,
            now: { Date() }
        )

        #expect(coordinator.history.isEmpty, "an unreadable history starts empty rather than crashing")
        #expect(persistence.quarantined, "the unreadable file is kept for recovery")
    }

    @Test("a failure on disk is logged, not fatal") func diskFailureIsNotFatal() {
        let monitor = SpyMonitor()
        let persistence = SpyPersistence(initialHistory: [textEntry("kept")])
        persistence.saveError = TestFailure.boom
        let coordinator = makeCoordinator(monitor: monitor, persistence: persistence, now: { Date() })

        coordinator.clearAll()

        #expect(coordinator.history.isEmpty, "the in-memory edit still stands")
    }

    @Test("history loaded at startup is available immediately") func loadsHistoryAtStartup() {
        let existing = textEntry("from disk")
        let coordinator = makeCoordinator(
            monitor: SpyMonitor(),
            persistence: SpyPersistence(initialHistory: [existing]),
            now: { Date() }
        )

        #expect(coordinator.history == [existing])
    }
}
