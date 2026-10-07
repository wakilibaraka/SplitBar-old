import Testing

@testable import SplitBar
import Foundation

/// Uses a temporary `$HOME` so nothing touches the developer's real
/// `~/.claude/settings.json`.
private func withTemporaryHome(_ body: (URL) throws -> Void) throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("splitbar-tests-\(UUID().uuidString)")
    let home = root.appendingPathComponent("home")
    try FileManager.default.createDirectory(at: home.appendingPathComponent(".claude"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try body(home)
}

struct SecretsStoreTests {
    @Test func inMemoryRoundTrip() throws {
        let store = InMemorySecretsStore()
        #expect(throws: SecretsStoreError.self) {
            try store.read(service: "svc", account: "acct")
        }
        try store.write(Data("secret".utf8), service: "svc", account: "acct")
        #expect(try store.read(service: "svc", account: "acct") == Data("secret".utf8))
        #expect(store.contains(service: "svc", account: "acct"))
        try store.delete(service: "svc", account: "acct")
        #expect(!store.contains(service: "svc", account: "acct"))
    }

    @Test func storesAreKeyedByServiceAndAccount() {
        let store = InMemorySecretsStore()
        try? store.write(Data("a".utf8), service: "svc", account: "one")
        try? store.write(Data("b".utf8), service: "svc", account: "two")
        try? store.write(Data("c".utf8), service: "other", account: "one")
        #expect(store.contains(service: "svc", account: "one"))
        #expect(store.contains(service: "svc", account: "two"))
        #expect(store.contains(service: "other", account: "one"))
    }

    @Test func cliStoreRefusesWrites() {
        let store = SecurityCLISecretsStore()
        #expect(throws: SecretsStoreError.writeNotSupported(service: "Claude Code-credentials")) {
            try store.write(Data("x".utf8), service: "Claude Code-credentials", account: "any")
        }
    }
}

struct ClaudeStatusLineBridgeTests {
    private func originalSettings() -> Data {
        Data("""
        {
          "model": "opus",
          "statusLine": {"type": "command", "command": "/bin/echo original"},
          "unrelated": {"keep": true}
        }
        """.utf8)
    }

    @Test func disconnectRestoresOriginalSettingsExactly() throws {
        try withTemporaryHome { home in
            let settingsURL = home.appendingPathComponent(".claude/settings.json")
            try originalSettings().write(to: settingsURL)
            let before = try Data(contentsOf: settingsURL)

            let support = home.appendingPathComponent("support")
            try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
            let bridge = ClaudeStatusLineBridge(supportDirectory: support, homeDirectory: home)

            _ = try bridge.isInstalled()
            try bridge.install()
            let installed = try Data(contentsOf: settingsURL)
            #expect(installed != before)

            try bridge.uninstall()
            let restored = try Data(contentsOf: settingsURL)
            // Byte-for-byte, including the unrelated keys.
            #expect(restored == before)
        }
    }

    @Test func installIsIdempotent() throws {
        try withTemporaryHome { home in
            let settingsURL = home.appendingPathComponent(".claude/settings.json")
            try originalSettings().write(to: settingsURL)
            let support = home.appendingPathComponent("support")
            try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
            let bridge = ClaudeStatusLineBridge(supportDirectory: support, homeDirectory: home)

            try bridge.install()
            let first = try Data(contentsOf: settingsURL)
            try bridge.install()
            let second = try Data(contentsOf: settingsURL)
            #expect(first == second)
        }
    }
}
