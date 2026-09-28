import Foundation

public struct ApplicationDescriptor: Identifiable, Equatable, Sendable {
    public var id: String { bundleIdentifier }
    public let bundleIdentifier: String
    public let displayName: String
    public let applicationURL: URL

    public init(
        bundleIdentifier: String,
        displayName: String,
        applicationURL: URL
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.applicationURL = applicationURL
    }
}
