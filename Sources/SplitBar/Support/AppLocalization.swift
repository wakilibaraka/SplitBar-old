import Foundation

public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case english = "en"
    case turkish = "tr"

    public var displayName: String {
        switch self {
        case .english:
            return "English"
        case .turkish:
            return "Türkçe"
        }
    }
}

public enum LocalizedKey: String, Sendable {
    case dockShowWindows
    case dockKeepInDock
    case dockRemoveFromDock
    case dockPosition
    case dockPositionRight
    case dockPositionLeft
    case dockPositionTop
    case dockPositionBottom
    case dockTheme
    case dockAutoHide
    case dockAddAppOrLink
    case dockSettings
    case dockQuit
    case flyoutActiveWindows
    case flyoutActiveWindow
    case systemMonitorCPU
    case systemMonitorMemory
    case systemMonitorDisk
    case systemMonitorBattery
    case systemMonitorThermal
    case systemMonitorNetwork
    case weatherHumidity
    case weatherWind
    case quickNotesTitle
    case quickNotesPlaceholder
    case aiUsageTitle
    case aiUsageAgentSessions
    case aiUsageTokens
    case settingsGeneral
    case settingsAppearance
    case settingsShortcuts
    case settingsClipboard
    case settingsLanguage
}

public enum AppLocalization: Sendable {
    private static let englishStrings: [LocalizedKey: String] = [
        .dockShowWindows: "Show Windows",
        .dockKeepInDock: "Keep in Dock",
        .dockRemoveFromDock: "Remove from Dock",
        .dockPosition: "Position on Screen",
        .dockPositionRight: "Right Screen Edge",
        .dockPositionLeft: "Left Screen Edge",
        .dockPositionTop: "Top Screen Edge",
        .dockPositionBottom: "Bottom Screen Edge",
        .dockTheme: "Theme",
        .dockAutoHide: "Auto-Hide Dock",
        .dockAddAppOrLink: "Add App or Link...",
        .dockSettings: "Settings...",
        .dockQuit: "Quit SplitBar",
        .flyoutActiveWindows: "Active Windows",
        .flyoutActiveWindow: "Active Window",
        .systemMonitorCPU: "CPU",
        .systemMonitorMemory: "Memory",
        .systemMonitorDisk: "Disk",
        .systemMonitorBattery: "Battery",
        .systemMonitorThermal: "Thermal",
        .systemMonitorNetwork: "Network",
        .weatherHumidity: "Humidity",
        .weatherWind: "Wind",
        .quickNotesTitle: "Quick Notes",
        .quickNotesPlaceholder: "Type notes here...",
        .aiUsageTitle: "AI Usage & Agents",
        .aiUsageAgentSessions: "Agent Sessions",
        .aiUsageTokens: "Tokens Processed",
        .settingsGeneral: "General",
        .settingsAppearance: "Appearance",
        .settingsShortcuts: "Shortcuts",
        .settingsClipboard: "Clipboard",
        .settingsLanguage: "Language"
    ]

    private static let turkishStrings: [LocalizedKey: String] = [
        .dockShowWindows: "Pencereleri Göster",
        .dockKeepInDock: "Dock'ta Tut",
        .dockRemoveFromDock: "Dock'tan Kaldır",
        .dockPosition: "Ekrandaki Konum",
        .dockPositionRight: "Sağ Kenar",
        .dockPositionLeft: "Sol Kenar",
        .dockPositionTop: "Üst Kenar",
        .dockPositionBottom: "Alt Kenar",
        .dockTheme: "Tema",
        .dockAutoHide: "Dock'u Otomatik Gizle",
        .dockAddAppOrLink: "Uygulama veya Bağlantı Ekle...",
        .dockSettings: "Ayarlar...",
        .dockQuit: "SplitBar'ten Çık",
        .flyoutActiveWindows: "Aktif Pencere",
        .flyoutActiveWindow: "Aktif Pencere",
        .systemMonitorCPU: "İşlemci",
        .systemMonitorMemory: "Bellek",
        .systemMonitorDisk: "Disk",
        .systemMonitorBattery: "Pil",
        .systemMonitorThermal: "Sıcaklık",
        .systemMonitorNetwork: "Ağ",
        .weatherHumidity: "Nem",
        .weatherWind: "Rüzgâr",
        .quickNotesTitle: "Hızlı Notlar",
        .quickNotesPlaceholder: "Buraya not alabilirsiniz...",
        .aiUsageTitle: "Yapay Zeka & Ajanlar",
        .aiUsageAgentSessions: "Ajan Oturumları",
        .aiUsageTokens: "İşlenen Token",
        .settingsGeneral: "Genel",
        .settingsAppearance: "Görünüm",
        .settingsShortcuts: "Kısayollar",
        .settingsClipboard: "Pano",
        .settingsLanguage: "Dil"
    ]

    public static func string(for key: LocalizedKey, language: AppLanguage) -> String {
        switch language {
        case .english:
            return englishStrings[key] ?? key.rawValue
        case .turkish:
            return turkishStrings[key] ?? englishStrings[key] ?? key.rawValue
        }
    }
}
