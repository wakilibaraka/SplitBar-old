import Foundation

public enum LaunchTarget: Equatable, Sendable {
    case application(bundleIdentifier: String, url: URL)
    case link(URL)
}

public enum LaunchResult: Equatable, Sendable {
    case launched
    case invalidTarget
    case systemFailure(String)
}
