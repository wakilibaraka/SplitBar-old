import Foundation

public struct ClipboardPersistence: Sendable {
    public let baseURL: URL

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    private var historyFileURL: URL {
        baseURL.appendingPathComponent("clipboard_history.json")
    }

    private var blobsDirectoryURL: URL {
        baseURL.appendingPathComponent("blobs")
    }

    /// Creates a directory that only the user can traverse.
    private func createPrivateDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: url.path
        )
    }

    /// Writes a file readable only by its owner.
    private func writePrivate(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: url.path
        )
    }

    public func saveHistory(_ entries: [ClipboardEntry]) throws {
        try createPrivateDirectory(at: baseURL)
        let encoder = JSONEncoder()
        // Compact, not pretty-printed: history is machine-read, not a document.
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(entries)
        try writePrivate(data, to: historyFileURL)
    }

    public func loadHistory() throws -> [ClipboardEntry] {
        guard FileManager.default.fileExists(atPath: historyFileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: historyFileURL)
        let decoder = JSONDecoder()
        return try decoder.decode([ClipboardEntry].self, from: data)
    }

    /// Okunamayan geçmiş dosyasını, bir sonraki kayıtta üzerine yazılmaması için tanı yedeği olarak kenara taşır.
    public func quarantineCorruptHistory() throws -> URL {
        let backupURL = historyFileURL
            .deletingPathExtension()
            .appendingPathExtension("corrupt.\(UUID().uuidString).bak")
        try FileManager.default.moveItem(at: historyFileURL, to: backupURL)
        return backupURL
    }

    public func saveBlob(data: Data, relativePath: String) throws {
        let fileURL = blobsDirectoryURL.appendingPathComponent(relativePath)
        try createPrivateDirectory(at: blobsDirectoryURL)
        try createPrivateDirectory(at: fileURL.deletingLastPathComponent())
        try writePrivate(data, to: fileURL)
    }

    public func loadBlob(relativePath: String) -> Data? {
        let fileURL = blobsDirectoryURL.appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return try? Data(contentsOf: fileURL)
    }

    public func cleanupUnreferencedBlobs(referencedPaths: Set<String>) throws {
        guard FileManager.default.fileExists(atPath: blobsDirectoryURL.path) else {
            return
        }
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: blobsDirectoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        for url in fileURLs {
            let relative = url.lastPathComponent
            if !referencedPaths.contains(relative) {
                try FileManager.default.removeItem(at: url)
            }
        }
    }
}
