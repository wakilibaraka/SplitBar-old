import Foundation

public struct AppPreferences: Codable, Equatable, Sendable {
    public var placement: DockPlacement
    public var materialStyle: DockMaterialStyle
    public var shortcutBindings: [ShortcutBinding]
    public var clipboardRetention: ClipboardRetentionPolicy
    public var clipboardExcludedBundleIdentifiers: Set<String>
    public var selectedScreenIdentifier: String?
    public var reduceMotion: Bool
    public var language: AppLanguage
    /// Opt-in gate for reading Claude Code / Codex credentials, switching
    /// accounts, and contacting provider OAuth endpoints. Off by default: the
    /// Claude Code status-line bridge is the only always-available source.
    public var aiAccountSwitchingEnabled: Bool
    /// Opt-in for IP-based geolocation (sends the machine's IP to ipwho.is).
    public var ipGeolocationEnabled: Bool
    /// Opt-in for third-party favicon services (sends every pinned host to them).
    public var faviconServiceEnabled: Bool
    public var dockIconSize: Double

    public init(
        placement: DockPlacement,
        materialStyle: DockMaterialStyle,
        shortcutBindings: [ShortcutBinding],
        clipboardRetention: ClipboardRetentionPolicy,
        clipboardExcludedBundleIdentifiers: Set<String>,
        selectedScreenIdentifier: String?,
        reduceMotion: Bool,
        language: AppLanguage,
        aiAccountSwitchingEnabled: Bool,
        ipGeolocationEnabled: Bool,
        faviconServiceEnabled: Bool,
        dockIconSize: Double
    ) {
        self.placement = placement
        self.materialStyle = materialStyle
        self.shortcutBindings = shortcutBindings
        self.clipboardRetention = clipboardRetention
        self.clipboardExcludedBundleIdentifiers = clipboardExcludedBundleIdentifiers
        self.selectedScreenIdentifier = selectedScreenIdentifier
        self.reduceMotion = reduceMotion
        self.language = language
        self.aiAccountSwitchingEnabled = aiAccountSwitchingEnabled
        self.ipGeolocationEnabled = ipGeolocationEnabled
        self.faviconServiceEnabled = faviconServiceEnabled
        self.dockIconSize = dockIconSize
    }

    private enum CodingKeys: String, CodingKey {
        case placement
        case materialStyle
        case shortcutBindings
        case clipboardRetention
        case clipboardExcludedBundleIdentifiers
        case selectedScreenIdentifier
        case reduceMotion
        case language
        case aiAccountSwitchingEnabled
        case ipGeolocationEnabled
        case faviconServiceEnabled
        case dockIconSize
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.placement = try container.decode(DockPlacement.self, forKey: .placement)
        self.materialStyle = try container.decode(DockMaterialStyle.self, forKey: .materialStyle)
        self.shortcutBindings = try container.decode([ShortcutBinding].self, forKey: .shortcutBindings)
        self.clipboardRetention = try container.decode(ClipboardRetentionPolicy.self, forKey: .clipboardRetention)
        self.clipboardExcludedBundleIdentifiers = try container.decode(Set<String>.self, forKey: .clipboardExcludedBundleIdentifiers)
        self.selectedScreenIdentifier = try container.decodeIfPresent(String.self, forKey: .selectedScreenIdentifier)
        self.reduceMotion = try container.decode(Bool.self, forKey: .reduceMotion)
        self.language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .english
        // Privacy gates default to off for existing configurations too.
        self.aiAccountSwitchingEnabled = try container.decodeIfPresent(Bool.self, forKey: .aiAccountSwitchingEnabled) ?? false
        self.ipGeolocationEnabled = try container.decodeIfPresent(Bool.self, forKey: .ipGeolocationEnabled) ?? false
        self.faviconServiceEnabled = try container.decodeIfPresent(Bool.self, forKey: .faviconServiceEnabled) ?? false
        self.dockIconSize = try container.decodeIfPresent(Double.self, forKey: .dockIconSize) ?? 46.0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(placement, forKey: .placement)
        try container.encode(materialStyle, forKey: .materialStyle)
        try container.encode(shortcutBindings, forKey: .shortcutBindings)
        try container.encode(clipboardRetention, forKey: .clipboardRetention)
        try container.encode(clipboardExcludedBundleIdentifiers, forKey: .clipboardExcludedBundleIdentifiers)
        try container.encodeIfPresent(selectedScreenIdentifier, forKey: .selectedScreenIdentifier)
        try container.encode(reduceMotion, forKey: .reduceMotion)
        try container.encode(language, forKey: .language)
        try container.encode(aiAccountSwitchingEnabled, forKey: .aiAccountSwitchingEnabled)
        try container.encode(ipGeolocationEnabled, forKey: .ipGeolocationEnabled)
        try container.encode(faviconServiceEnabled, forKey: .faviconServiceEnabled)
        try container.encode(dockIconSize, forKey: .dockIconSize)
    }
}
