import Foundation

public struct ConfigurationSnapshot: Codable, Equatable, Sendable {
    public let version: Int
    public let preferences: AppPreferences
    public let dockItems: [DockItem]

    public init(
        version: Int,
        preferences: AppPreferences,
        dockItems: [DockItem]
    ) {
        self.version = version
        self.preferences = preferences
        self.dockItems = dockItems
    }
}

public enum ConfigurationLoadResult: Equatable, Sendable {
    case loaded(ConfigurationSnapshot)
    case recoveredDefault(ConfigurationSnapshot, diagnosticBackupURL: URL)
    case migrationRequired(foundVersion: Int)
}

public struct ConfigurationPersistence: Sendable {
    public let fileURL: URL
    public static let currentVersion: Int = 1

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func save(snapshot: ConfigurationSnapshot) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }

    public func load(defaultSnapshot: ConfigurationSnapshot) -> ConfigurationLoadResult {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .loaded(defaultSnapshot)
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            let backupURL = fileURL.deletingPathExtension().appendingPathExtension("corrupt.\(UUID().uuidString).bak")
            return .recoveredDefault(defaultSnapshot, diagnosticBackupURL: backupURL)
        }

        struct VersionProbe: Decodable {
            let version: Int
        }

        guard let probe = try? JSONDecoder().decode(VersionProbe.self, from: data) else {
            let backupURL = fileURL.deletingPathExtension().appendingPathExtension("corrupt.\(UUID().uuidString).bak")
            try? FileManager.default.moveItem(at: fileURL, to: backupURL)
            return .recoveredDefault(defaultSnapshot, diagnosticBackupURL: backupURL)
        }

        if probe.version > Self.currentVersion {
            return .migrationRequired(foundVersion: probe.version)
        }

        guard let snapshot = try? JSONDecoder().decode(ConfigurationSnapshot.self, from: data) else {
            let backupURL = fileURL.deletingPathExtension().appendingPathExtension("corrupt.\(UUID().uuidString).bak")
            try? FileManager.default.moveItem(at: fileURL, to: backupURL)
            return .recoveredDefault(defaultSnapshot, diagnosticBackupURL: backupURL)
        }

        return .loaded(snapshot)
    }
}
