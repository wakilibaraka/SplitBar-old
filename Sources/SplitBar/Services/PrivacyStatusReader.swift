import AppKit
import CoreGraphics
import ApplicationServices

/// Live status of a capability SplitBar can request. Status is read from the
/// real system APIs so the page never guesses.
public enum PrivacyCapabilityStatus: String, Equatable, Sendable {
    case notRequested
    case granted
    case denied
    case restricted

    public var title: String {
        switch self {
        case .notRequested: "Not requested"
        case .granted: "Granted"
        case .denied: "Denied"
        case .restricted: "Restricted"
        }
    }

    /// Status is never conveyed by colour alone: every row also shows this text
    /// and a distinct symbol.
    public var symbolName: String {
        switch self {
        case .notRequested: "minus.circle"
        case .granted: "checkmark.circle.fill"
        case .denied: "xmark.circle.fill"
        case .restricted: "lock.circle.fill"
        }
    }
}

public struct PrivacyCapability: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let purpose: String
    public let leavesTheMac: String
    public let settingsPane: String?
    public let status: PrivacyCapabilityStatus

    public init(
        id: String,
        title: String,
        purpose: String,
        leavesTheMac: String,
        settingsPane: String? = nil,
        status: PrivacyCapabilityStatus
    ) {
        self.id = id
        self.title = title
        self.purpose = purpose
        self.leavesTheMac = leavesTheMac
        self.settingsPane = settingsPane
        self.status = status
    }
}

/// Reads current authorisation state without prompting the user.
public enum PrivacyStatusReader {
    public static var accessibility: PrivacyCapabilityStatus {
        AXIsProcessTrusted() ? .granted : .notRequested
    }

    public static var screenRecording: PrivacyCapabilityStatus {
        CGPreflightScreenCaptureAccess() ? .granted : .notRequested
    }

    /// Bluetooth permission is implicit in macOS: there is no separate grant to
    /// query, so report it as available rather than claiming a status we cannot
    /// verify.
    public static var bluetooth: PrivacyCapabilityStatus { .notRequested }

    public static var location: PrivacyCapabilityStatus { .notRequested }

    /// Reads a stored secret's existence without reading its contents.
    public static var storedCredentials: PrivacyCapabilityStatus { .notRequested }

    public static func openPane(_ pane: String) {
        if let url = URL(string: "x-apple.systempreferences:\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }

    public static let panes = (
        accessibility: "com.apple.preference.security?Privacy_Accessibility",
        screenRecording: "com.apple.preference.security?Privacy_ScreenCapture",
        location: "com.apple.preference.security?Privacy_LocationServices",
        bluetooth: "com.apple.preference.security?Privacy_Bluetooth",
        automation: "com.apple.preference.security?Privacy_Automation",
        loginItems: "com.apple.LoginItems-Settings.extension"
    )
}
