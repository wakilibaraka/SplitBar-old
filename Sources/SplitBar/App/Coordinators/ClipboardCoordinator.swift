import AppKit
import Foundation
import OSLog

/// Why the clipboard history changed.
///
/// The runtime refreshed the flyout under two different conditions before this
/// coordinator existed: a new capture only refreshed a visible flyout, while
/// pinning, deleting or clearing refreshed whenever a flyout was open at all.
/// The distinction is carried explicitly so the extraction cannot quietly
/// change which of the two happens.
enum ClipboardHistoryChange {
    /// A new entry was captured from the pasteboard.
    case captured
    /// The user pinned, deleted or cleared entries.
    case edited
}

/// The clipboard-related preferences, as the coordinator needs them.
///
/// A dedicated value type rather than `AppPreferences`, so this type does not
/// depend on the whole settings model and its behaviour can be tested directly.
struct ClipboardSettings: Equatable {
    var historyEnabled: Bool
    var retention: ClipboardRetentionPolicy
    var excludedBundleIdentifiers: Set<String>
}

extension AppPreferences {
    var clipboardSettings: ClipboardSettings {
        ClipboardSettings(
            historyEnabled: clipboardHistoryEnabled,
            retention: clipboardRetention,
            excludedBundleIdentifiers: clipboardExcludedBundleIdentifiers
        )
    }
}

@MainActor
protocol ClipboardCoordinating: AnyObject {
    var history: [ClipboardEntry] { get }
    var historyDidChange: ((ClipboardHistoryChange) -> Void)? { get set }
    func refreshMonitoring(for settings: ClipboardSettings)
    func applySettingsChange(from previous: ClipboardSettings, to current: ClipboardSettings)
    func pause(for seconds: TimeInterval)
    func copyToPasteboard(entry: ClipboardEntry)
    func togglePin(id: UUID)
    func delete(id: UUID)
    func clearUnpinned()
    func clearAll()
}

/// The pasteboard watcher, narrowed to what the coordinator needs.
protocol ClipboardMonitoring: AnyObject {
    func startMonitoring(
        interval: TimeInterval,
        excludedBundleIdentifiers: Set<String>,
        onNewEntry: @escaping (ClipboardCapture) -> Void
    )
    func stopMonitoring()
    func updateExcludedBundleIdentifiers(_ identifiers: Set<String>)
}

/// Persistence is `Sendable` because the coordinator hands it to its background
/// queue. The real implementation is a value type over a URL; tests use a spy.
protocol ClipboardPersisting: Sendable {
    func loadHistory() throws -> [ClipboardEntry]
    func saveHistory(_ entries: [ClipboardEntry]) throws
    func saveBlob(data: Data, relativePath: String) throws
    func loadBlob(relativePath: String) -> Data?
    func cleanupUnreferencedBlobs(referencedPaths: Set<String>) throws
    func quarantineCorruptHistory() throws -> URL
}

/// Owns clipboard history: capture, retention, persistence and the user's edits.
///
/// Extracted from `AppRuntimeController`, which used to hold the monitor, the
/// persistence queue, the pause deadline and the history array itself. Disk work
/// stays on one serial queue so a blob is written before the history entry that
/// references it, and pruning runs in call order.
@MainActor
final class ClipboardCoordinator: ClipboardCoordinating {
    private let monitor: any ClipboardMonitoring
    private let persistence: any ClipboardPersisting
    private let ioQueue: DispatchQueue
    private let now: () -> Date

    /// Clipboard history is opt-in: while it is off, no timer is scheduled and
    /// nothing new is written to disk. Retention arrives with the first refresh;
    /// until then a capture is stored without pruning, rather than against a
    /// limit the user never chose.
    private var retentionPolicy: ClipboardRetentionPolicy?
    private var pausedUntil: Date?
    private(set) var history: [ClipboardEntry] = []
    var historyDidChange: ((ClipboardHistoryChange) -> Void)?

    init(
        monitor: any ClipboardMonitoring,
        persistence: any ClipboardPersisting,
        ioQueue: DispatchQueue = DispatchQueue(label: "com.baraka.splitbar.clipboard-io", qos: .utility),
        now: @escaping () -> Date = { Date() }
    ) {
        self.monitor = monitor
        self.persistence = persistence
        self.ioQueue = ioQueue
        self.now = now
        do {
            self.history = try persistence.loadHistory()
        } catch {
            Logger.persistence.error("Failed to load clipboard history error=\(error.localizedDescription, privacy: .private)")
            do {
                let backupURL = try persistence.quarantineCorruptHistory()
                Logger.persistence.notice("Moved unreadable clipboard history aside backup=\(backupURL.path, privacy: .private)")
            } catch {
                Logger.persistence.error("Failed to quarantine clipboard history error=\(error.localizedDescription, privacy: .private)")
            }
            self.history = []
        }
    }

    /// Starts or stops capture to match the current settings.
    ///
    /// A pause outlives a settings change: the deadline is only cleared once it
    /// has passed, so toggling a preference cannot shorten a pause the user asked
    /// for.
    func refreshMonitoring(for settings: ClipboardSettings) {
        retentionPolicy = settings.retention
        if let pausedUntil, pausedUntil > now() {
            monitor.stopMonitoring()
            return
        }
        pausedUntil = nil
        guard settings.historyEnabled else {
            monitor.stopMonitoring()
            Logger.clipboard.debug("Clipboard history disabled")
            return
        }
        monitor.startMonitoring(
            interval: 0.6,
            excludedBundleIdentifiers: settings.excludedBundleIdentifiers
        ) { [weak self] capture in
            Task { @MainActor in
                self?.handleCapture(capture)
            }
        }
    }

    /// Applies a settings change to capture.
    ///
    /// Turning history off stops the timer but leaves the pause deadline alone,
    /// and the exclusion list is pushed to the running monitor rather than
    /// restarting it, which is what the monitor supports.
    func applySettingsChange(from previous: ClipboardSettings, to current: ClipboardSettings) {
        if previous.historyEnabled != current.historyEnabled {
            if current.historyEnabled {
                refreshMonitoring(for: current)
            } else {
                monitor.stopMonitoring()
            }
        }
        monitor.updateExcludedBundleIdentifiers(current.excludedBundleIdentifiers)
    }

    /// Suspends capture for `seconds` without forgetting the setting.
    func pause(for seconds: TimeInterval) {
        monitor.stopMonitoring()
        pausedUntil = now().addingTimeInterval(seconds)
        Logger.clipboard.notice("Clipboard capture paused")
    }

    func copyToPasteboard(entry: ClipboardEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch entry.payload {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .url(let url):
            pasteboard.setString(url.absoluteString, forType: .URL)
        case .fileURLs(let urls):
            pasteboard.writeObjects(urls as [NSURL])
        case .imageBlob(let relativePath, _):
            guard let data = persistence.loadBlob(relativePath: relativePath) else {
                Logger.clipboard.error("Clipboard image blob is missing path=\(relativePath, privacy: .private)")
                NSSound.beep()
                return
            }
            pasteboard.setData(data, forType: .png)
        }
    }

    func togglePin(id: UUID) {
        guard let index = history.firstIndex(where: { $0.id == id }) else { return }
        let current = history[index]
        let toggled = ClipboardEntry(
            id: current.id,
            timestamp: current.timestamp,
            sourceBundleIdentifier: current.sourceBundleIdentifier,
            isPinned: !current.isPinned,
            searchableText: current.searchableText,
            payload: current.payload
        )
        history[index] = toggled
        persist()
        historyDidChange?(.edited)
    }

    func delete(id: UUID) {
        history.removeAll { $0.id == id }
        persist()
        historyDidChange?(.edited)
    }

    func clearUnpinned() {
        history.removeAll { !$0.isPinned }
        persist()
        historyDidChange?(.edited)
    }

    func clearAll() {
        history.removeAll()
        persist()
        historyDidChange?(.edited)
    }

    private func handleCapture(_ capture: ClipboardCapture) {
        Logger.clipboard.debug("Received new clipboard candidate")
        if let imageData = capture.imageData, case .imageBlob(let relativePath, _) = capture.entry.payload {
            // The blob is written before the history entry on the same serial
            // queue, so pruning cannot delete a file the entry still needs.
            let persistence = persistence
            ioQueue.async {
                do {
                    try persistence.saveBlob(data: imageData, relativePath: relativePath)
                } catch {
                    Logger.persistence.error("Failed to save clipboard image blob path=\(relativePath, privacy: .private) bytes=\(imageData.count, privacy: .public) error=\(error.localizedDescription, privacy: .private)")
                }
            }
        }
        history = mergeClipboardEntry(
            history: history,
            candidate: capture.entry,
            policy: retentionPolicy ?? ClipboardRetentionPolicy(maxEntries: .max, maxBlobBytes: .max)
        )
        persist()
        historyDidChange?(.captured)
    }

    /// Writes the history to disk and deletes image files no entry references.
    ///
    /// Runs on the serial background queue in call order so the disk is never
    /// blocked and a later write cannot overtake an earlier prune.
    private func persist() {
        let entries = history
        let persistence = persistence
        let referencedBlobPaths: Set<String> = Set(entries.compactMap { entry in
            if case .imageBlob(let relativePath, _) = entry.payload {
                return relativePath
            }
            return nil
        })
        ioQueue.async {
            do {
                try persistence.saveHistory(entries)
                try persistence.cleanupUnreferencedBlobs(referencedPaths: referencedBlobPaths)
            } catch {
                Logger.persistence.error("Failed to persist clipboard history entries=\(entries.count, privacy: .public) error=\(error.localizedDescription, privacy: .private)")
            }
        }
    }
}

extension ClipboardMonitor: ClipboardMonitoring {}
extension ClipboardPersistence: ClipboardPersisting {}
