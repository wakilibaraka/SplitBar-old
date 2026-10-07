import Foundation
import OSLog

public enum ClaudeStatusLineBridgeError: Error, CustomStringConvertible {
    case settingsUnreadable(path: String, underlying: Error)
    case settingsNotAnObject(path: String)
    case writeFailed(path: String, underlying: Error)
    case notInstalled

    public var description: String {
        switch self {
        case .settingsUnreadable(let path, let underlying):
            return "Cannot read Claude settings at \(path): \(underlying.localizedDescription)"
        case .settingsNotAnObject(let path):
            return "Claude settings at \(path) is not a JSON object"
        case .writeFailed(let path, let underlying):
            return "Cannot write \(path): \(underlying.localizedDescription)"
        case .notInstalled:
            return "The SplitBar Claude status line bridge is not installed"
        }
    }
}

/// Claude Code resmi plan limitlerini (`rate_limits`) yalnızca status line komutuna gönderir.
/// Köprü, `statusLine` komutunu küçük bir betikle sarar: betik gelen JSON'u SplitBar için bir dosyaya
/// yazar ve ardından kullanıcının önceki status line komutunu aynı girdiyle çalıştırır.
public struct ClaudeStatusLineBridge: Sendable {
    public let captureURL: URL
    private let scriptURL: URL
    private let originalStatusLineURL: URL
    private let settingsURL: URL

    public init(supportDirectory: URL, homeDirectory: URL) {
        self.captureURL = supportDirectory.appendingPathComponent("claude-statusline.json")
        self.scriptURL = supportDirectory.appendingPathComponent("splitbar-claude-statusline.sh")
        self.originalStatusLineURL = supportDirectory.appendingPathComponent("claude-statusline-original.json")
        self.settingsURL = homeDirectory.appendingPathComponent(".claude/settings.json")
    }

    public func isInstalled() throws -> Bool {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return false
        }
        let settings = try readSettings()
        guard let statusLine = settings["statusLine"] as? [String: Any],
              let command = statusLine["command"] as? String else {
            return false
        }
        return command.contains(scriptURL.lastPathComponent)
    }

    public func install() throws {
        guard try !isInstalled() else {
            Logger.general.notice("Claude status line bridge already installed")
            return
        }
        var settings = FileManager.default.fileExists(atPath: settingsURL.path) ? try readSettings() : [:]

        // Önceki status line birebir saklanır; kaldırırken aynen geri yazılır
        let original = settings["statusLine"] as? [String: Any]
        let originalRecord: [String: Any] = original.map { ["statusLine": $0] } ?? [:]
        try write(try serialize(originalRecord, path: originalStatusLineURL.path), to: originalStatusLineURL, permissions: nil)
        try write(Data(bridgeScript(originalCommand: original?["command"] as? String).utf8), to: scriptURL, permissions: 0o755)
        try backupSettings()

        var statusLine: [String: Any] = ["type": "command", "command": shellQuoted(scriptURL.path)]
        if let padding = original?["padding"] {
            statusLine["padding"] = padding
        }
        settings["statusLine"] = statusLine
        try write(try serialize(settings, path: settingsURL.path), to: settingsURL, permissions: nil)
        Logger.general.info("Installed Claude status line bridge script=\(scriptURL.path, privacy: .private)")
    }

    public func uninstall() throws {
        guard try isInstalled() else {
            throw ClaudeStatusLineBridgeError.notInstalled
        }
        var settings = try readSettings()
        let originalData: Data
        do {
            originalData = try Data(contentsOf: originalStatusLineURL)
        } catch {
            throw ClaudeStatusLineBridgeError.settingsUnreadable(path: originalStatusLineURL.path, underlying: error)
        }
        let original = try parseObject(originalData, path: originalStatusLineURL.path)
        try backupSettings()
        settings["statusLine"] = original["statusLine"]
        try write(try serialize(settings, path: settingsURL.path), to: settingsURL, permissions: nil)
        Logger.general.info("Removed Claude status line bridge")
    }

    private func bridgeScript(originalCommand: String?) -> String {
        let capture = shellQuoted(captureURL.path)
        let captureTemp = shellQuoted(captureURL.path + ".tmp")
        let forward = originalCommand.map { "printf '%s' \"$input\" | \($0)" } ?? ":"
        return """
        #!/bin/sh
        # SplitBar köprüsü: Claude Code'un status line JSON'unu (rate_limits dahil) SplitBar için saklar,
        # ardından önceki status line komutunu aynı girdiyle çalıştırır. SplitBar AI Usage hesap menüsünden kaldırılabilir.
        input=$(cat)
        printf '%s' "$input" > \(captureTemp) && mv -f \(captureTemp) \(capture)
        \(forward)

        """
    }

    // MARK: - JSON helpers

    /// Claude ayar dosyasının şeması Claude Code'a aittir; bilinmeyen alanlar korunmak için tipsiz okunur.
    private func readSettings() throws -> [String: Any] {
        let data: Data
        do {
            data = try Data(contentsOf: settingsURL)
        } catch {
            throw ClaudeStatusLineBridgeError.settingsUnreadable(path: settingsURL.path, underlying: error)
        }
        return try parseObject(data, path: settingsURL.path)
    }

    private func parseObject(_ data: Data, path: String) throws -> [String: Any] {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw ClaudeStatusLineBridgeError.settingsUnreadable(path: path, underlying: error)
        }
        guard let dictionary = object as? [String: Any] else {
            throw ClaudeStatusLineBridgeError.settingsNotAnObject(path: path)
        }
        return dictionary
    }

    private func serialize(_ object: [String: Any], path: String) throws -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        } catch {
            throw ClaudeStatusLineBridgeError.writeFailed(path: path, underlying: error)
        }
    }

    private func backupSettings() throws {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else { return }
        let stamp = Int(Date().timeIntervalSince1970)
        let backupURL = settingsURL.deletingLastPathComponent().appendingPathComponent("settings.json.splitbar-backup-\(stamp)")
        do {
            try FileManager.default.copyItem(at: settingsURL, to: backupURL)
        } catch {
            throw ClaudeStatusLineBridgeError.writeFailed(path: backupURL.path, underlying: error)
        }
    }

    private func write(_ data: Data, to url: URL, permissions: Int?) throws {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            if let permissions {
                try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path)
            }
        } catch {
            throw ClaudeStatusLineBridgeError.writeFailed(path: url.path, underlying: error)
        }
    }
}
