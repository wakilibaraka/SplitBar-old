import Testing

@testable import SplitBar
import Foundation

struct DockStateTests {
    @Test func settingsRoundTrip() throws {
        let original = DockSettings(orientation: "right", autohide: true, autohideDelay: 0.5)
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(DockSettings.self, from: data)
        #expect(restored == original)
        #expect(restored.version == DockSettings.currentVersion)
    }

    @Test func settingsWithoutDelayRoundTrip() throws {
        let original = DockSettings(orientation: "bottom", autohide: false)
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(DockSettings.self, from: data)
        #expect(restored == original)
        #expect(restored.autohideDelay == nil)
    }

    @Test func legacyPayloadWithoutVersionDecodesNil() {
        // A pre-version payload has no "version" key and must fail loudly
        // rather than decode with a garbage version.
        let legacy = #"{"orientation":"bottom","autohide":true}"#.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(DockSettings.self, from: legacy)
        }
    }
}
