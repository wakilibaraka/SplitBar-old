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
    policy: ClipboardRetentionPolicy
) -> [ClipboardEntry] {
    if let first = history.first, first.payload == candidate.payload {
        return history
    }

    var merged = [candidate] + history
    while merged.count > policy.maxEntries {
        if let lastUnpinnedIndex = merged.lastIndex(where: { !$0.isPinned }) {
            merged.remove(at: lastUnpinnedIndex)
        } else {
            merged.removeLast()
        }
    }
    return merged
}
