import AppKit
import Collaboration
import Foundation

public struct UserIdentity: Equatable, Sendable {
    public let displayName: String
    public let initials: String
    public let avatarImageData: Data?

    public init(displayName: String, initials: String, avatarImageData: Data? = nil) {
        self.displayName = displayName
        self.initials = initials
        self.avatarImageData = avatarImageData
    }

    public static func fallback() -> UserIdentity {
        UserIdentity(displayName: NSFullUserName(), initials: "U", avatarImageData: nil)
    }
}

public enum UserIdentityService {
    public static func currentIdentity() -> UserIdentity {
        let displayName = NSFullUserName()
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? NSUserName() : trimmed
        return UserIdentity(
            displayName: name,
            initials: initials(for: name),
            avatarImageData: avatarData()
        )
    }

    public static func avatarImage(for identity: UserIdentity) -> NSImage? {
        guard let data = identity.avatarImageData else { return nil }
        return NSImage(data: data)
    }

    private static func initials(for name: String) -> String {
        let parts = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !parts.isEmpty else { return "U" }
        if parts.count == 1 {
            return String(parts[0].prefix(1)).uppercased()
        }
        return (String(parts.first!.prefix(1)) + String(parts.last!.prefix(1))).uppercased()
    }

    private static func avatarData() -> Data? {
        guard let identity = CBIdentity(name: NSUserName(), authority: .default()),
              let image = identity.image,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else {
            return nil
        }
        return png
    }
}
