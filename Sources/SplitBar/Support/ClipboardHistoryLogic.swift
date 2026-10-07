import Foundation

public func shouldCaptureClipboard(
    frontmostBundleIdentifier: String?,
    excludedBundleIdentifiers: Set<String>
) -> Bool {
    if let bundleID = frontmostBundleIdentifier, excludedBundleIdentifiers.contains(bundleID) {
        return false
    }
    return true
}

public func mergeClipboardEntry(
    history: [ClipboardEntry],
    candidate: ClipboardEntry,
    policy: ClipboardRetentionPolicy,
    now: Date = Date()
) -> [ClipboardEntry] {
    if let first = history.first, first.payload == candidate.payload {
        return history
    }

    // Time-based expiry runs before the count limit so an old history is never
    // carried forward by a new capture.
    var merged = policy.prune([candidate] + history, now: now)
    while merged.count > policy.maxEntries {
        if let lastUnpinnedIndex = merged.lastIndex(where: { !$0.isPinned }) {
            merged.remove(at: lastUnpinnedIndex)
        } else {
            merged.removeLast()
        }
    }
    return merged
}


/// Removes entries the policy has expired, plus any image blobs no longer
/// referenced by the surviving entries.
public func pruneClipboardHistory(
    _ history: [ClipboardEntry],
    policy: ClipboardRetentionPolicy,
    now: Date = Date()
) -> [ClipboardEntry] {
    policy.prune(history, now: now)
}
