import Foundation

/// Login-time backstop for Dock hiding. If SplitBar crashed or was killed
/// (SIGKILL) while the macOS Dock was hidden, the state file survives and this
/// helper restores the saved Dock settings, then exits. Run once at login via
/// the com.baraka.splitbar.restore LaunchAgent installed while the Dock is
/// hidden; it is removed again on clean restore.

struct SavedDockSettings: Codable {
    var version: Int
    var orientation: String
    var autohide: Bool
    var autohideDelay: Double?
}

func runDefaults(_ arguments: [String]) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
    process.arguments = arguments
    try? process.run()
    process.waitUntilExit()
}

func restartDock() {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
    process.arguments = ["Dock"]
    try? process.run()
    process.waitUntilExit()
}

let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
    .appendingPathComponent("com.baraka.splitbar")
let stateFileURL = supportURL?.appendingPathComponent("dock-prior-state.json")

guard let stateFileURL,
      let data = try? Data(contentsOf: stateFileURL),
      let saved = try? JSONDecoder().decode(SavedDockSettings.self, from: data),
      saved.version <= 1
else {
    exit(0)
}

runDefaults(["write", "com.apple.dock", "autohide", "-bool", saved.autohide ? "true" : "false"])
if let delay = saved.autohideDelay {
    runDefaults(["write", "com.apple.dock", "autohide-delay", "-float", String(delay)])
} else {
    runDefaults(["delete", "com.apple.dock", "autohide-delay"])
}
if ["bottom", "left", "right"].contains(saved.orientation) {
    runDefaults(["write", "com.apple.dock", "orientation", "-string", saved.orientation])
}
try? FileManager.default.removeItem(at: stateFileURL)
restartDock()
exit(0)
