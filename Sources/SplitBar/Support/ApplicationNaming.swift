import AppKit
import Foundation

func taskbarDisplayName(for bundleIdentifier: String) -> String {
    if let known = LauncherDefaults.apps.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
        return known.title
    }
    if let running = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }),
       let name = running.localizedName, !name.isEmpty {
        return name
    }
    return bundleIdentifier
}
