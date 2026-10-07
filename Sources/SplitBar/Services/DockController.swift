import AppKit
import Darwin
import Foundation
import OSLog

public struct DockSettings: Codable, Equatable, Sendable {
    public static let currentVersion = 1
    public let version: Int
    public let orientation: String
    public let autohide: Bool
    public let autohideDelay: Double?

    public init(version: Int = currentVersion, orientation: String, autohide: Bool, autohideDelay: Double? = nil) {
        self.version = version
        self.orientation = orientation
        self.autohide = autohide
        self.autohideDelay = autohideDelay
    }
}

@MainActor
public final class DockController {
    /// Autohide delay applied while SplitBar hides the Dock. Large enough to
    /// suppress edge-hover reveal; the saved value is restored on quit.
    public static let suppressionDelay: Double = 1000
    public static let restoreAgentLabel = "com.baraka.splitbar.restore"
    private let stateFileURL: URL
    private let logger = Logger(subsystem: "com.baraka.splitbar", category: "dock")

    public init(stateFileURL: URL) {
        self.stateFileURL = stateFileURL
    }

    public var isHiddenByUs: Bool {
        FileManager.default.fileExists(atPath: stateFileURL.path)
    }

    private var signalSources: [DispatchSourceSignal] = []

    public func setupSignalHandlers(restore: @escaping @Sendable () -> Void) {
        for sig in [SIGTERM, SIGINT] {
            let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            source.setEventHandler {
                restore()
                NSApp.terminate(nil)
            }
            source.resume()
            signalSources.append(source)
            signal(sig, SIG_IGN)
        }
    }

    public func restoreIfNeeded() {
        guard isHiddenByUs else { return }
        logger.info("Found dock state file from a previous session; restoring the macOS Dock")
        restore()
    }

    public func setHidden(_ hidden: Bool) {
        if bypassEnabled() {
            logger.info("Dock mutation bypassed by SPLITBAR_SKIP_DOCK")
            return
        }
        if hidden {
            do {
                try persistCurrentSettings()
            } catch {
                logger.error("Refusing to hide the Dock without a saved state error=\(error.localizedDescription, privacy: .private)")
                return
            }
            writeDockDefaults(autohide: true, autohideDelay: Self.suppressionDelay)
            installRestoreAgent()
            restartDock()
        } else {
            restore()
        }
    }

    /// Installs the login-time restore helper while the Dock is hidden, so a
    /// crash or SIGKILL still leaves a path back to the saved Dock state.
    private func installRestoreAgent() {
        let helperURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Helpers/SplitBarDockRestore")
        guard FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            logger.warning("Restore helper not found in bundle; skipping LaunchAgent install")
            return
        }
        let agentsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        let plistURL = agentsURL.appendingPathComponent("\(Self.restoreAgentLabel).plist")
        let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key><string>\(Self.restoreAgentLabel)</string>
                <key>ProgramArguments</key><array><string>\(helperURL.path)</string></array>
                <key>RunAtLoad</key><true/>
            </dict>
            </plist>
            """
        do {
            try FileManager.default.createDirectory(at: agentsURL, withIntermediateDirectories: true)
            try plist.write(to: plistURL, atomically: true, encoding: .utf8)
            logger.info("Installed Dock restore LaunchAgent")
        } catch {
            logger.error("Failed to install restore LaunchAgent error=\(error.localizedDescription, privacy: .private)")
        }
    }

    private func removeRestoreAgent() {
        let plistURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(Self.restoreAgentLabel).plist")
        try? FileManager.default.removeItem(at: plistURL)
    }

    private func restore() {
        guard let saved = readSavedSettings() else {
            logger.warning("No saved Dock state to restore")
            return
        }
        writeDockDefaults(autohide: saved.autohide, autohideDelay: saved.autohideDelay)
        if saved.orientation != currentOrientation() {
            writeDockString(saved.orientation, forKey: "orientation")
        }
        try? FileManager.default.removeItem(at: stateFileURL)
        removeRestoreAgent()
        restartDock()
        logger.info("macOS Dock restored")
    }

    private func persistCurrentSettings() throws {
        let settings = DockSettings(
            orientation: currentOrientation() ?? "bottom",
            autohide: currentAutohide(),
            autohideDelay: currentAutohideDelay()
        )
        let data = try JSONEncoder().encode(settings)
        try FileManager.default.createDirectory(
            at: stateFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: stateFileURL, options: .atomic)
    }

    private func readSavedSettings() -> DockSettings? {
        guard let data = try? Data(contentsOf: stateFileURL),
              let settings = try? JSONDecoder().decode(DockSettings.self, from: data)
        else {
            return nil
        }
        guard settings.version <= DockSettings.currentVersion else {
            logger.fault("Dock state file has newer schema version=\(settings.version, privacy: .public) current=\(DockSettings.currentVersion, privacy: .public); refusing to restore blindly")
            return nil
        }
        return settings
    }

    private func bypassEnabled() -> Bool {
        ProcessInfo.processInfo.environment["SPLITBAR_SKIP_DOCK"] != nil
    }

    private func currentOrientation() -> String? {
        readDockString(forKey: "orientation")
    }

    private func currentAutohide() -> Bool {
        readDockBool(forKey: "autohide")
    }

    private func currentAutohideDelay() -> Double? {
        guard let value = readDockString(forKey: "autohide-delay") else { return nil }
        return Double(value)
    }

    private func readDockString(forKey key: String) -> String? {
        guard let result = try? ProcessRunner.run(
            executablePath: "/usr/bin/defaults",
            arguments: ["read", "com.apple.dock", key],
            timeout: 5
        ), result.succeeded else { return nil }
        let value = result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func readDockBool(forKey key: String) -> Bool {
        readDockString(forKey: key) == "1"
    }

    private func writeDockDefaults(autohide: Bool, autohideDelay: Double?) {
        writeDockBool(autohide, forKey: "autohide")
        if let autohideDelay {
            runDefaults(arguments: ["write", "com.apple.dock", "autohide-delay", "-float", String(autohideDelay)])
        } else {
            deleteDockKey("autohide-delay")
        }
    }

    private func writeDockBool(_ value: Bool, forKey key: String) {
        runDefaults(arguments: ["write", "com.apple.dock", key, "-bool", value ? "true" : "false"])
    }

    private func writeDockString(_ value: String, forKey key: String) {
        runDefaults(arguments: ["write", "com.apple.dock", key, value])
    }

    private func runDefaults(arguments: [String]) {
        _ = try? ProcessRunner.run(executablePath: "/usr/bin/defaults", arguments: arguments, timeout: 5)
    }

    private func deleteDockKey(_ key: String) {
        _ = try? ProcessRunner.run(executablePath: "/usr/bin/defaults", arguments: ["delete", "com.apple.dock", key], timeout: 5)
    }

    private func restartDock() {
        // Fire-and-forget: we deliberately do not block the main actor on the
        // Dock restart, but we still go through ProcessRunner for path safety.
        try? ProcessRunner.launch(executablePath: "/usr/bin/killall", arguments: ["Dock"])
    }
}
