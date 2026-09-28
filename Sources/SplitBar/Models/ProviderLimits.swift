import Foundation

/// Hesap ve plan limiti takip edilen AI sağlayıcıları.
public enum AIAccountProvider: String, Codable, CaseIterable, Sendable {
    case claude
    case codex

    public var displayName: String {
        switch self {
        case .claude:
            return "Claude Code"
        case .codex:
            return "OpenAI Codex"
        }
    }

    public var agentType: AIAgentType {
        switch self {
        case .claude:
            return .claude
        case .codex:
            return .codex
        }
    }
}

/// Sağlayıcının bildirdiği tek bir plan limiti penceresi (ör. 5 saatlik veya haftalık).
public struct UsageWindow: Codable, Equatable, Sendable {
    public let usedPercent: Double
    public let windowMinutes: Int
    public let resetsAt: Date?

    public init(usedPercent: Double, windowMinutes: Int, resetsAt: Date?) {
        self.usedPercent = usedPercent
        self.windowMinutes = windowMinutes
        self.resetsAt = resetsAt
    }
}

/// Bir hesabın belirli bir andaki gerçek plan limiti durumu.
public struct ProviderLimitSnapshot: Codable, Equatable, Sendable {
    public let provider: AIAccountProvider
    /// Codex oturum kayıtlarındaki hesap kimliği; Claude status line verisi hesap kimliği taşımaz.
    public let accountID: String?
    public let fiveHour: UsageWindow?
    public let weekly: UsageWindow?
    public let capturedAt: Date

    public init(
        provider: AIAccountProvider,
        accountID: String?,
        fiveHour: UsageWindow?,
        weekly: UsageWindow?,
        capturedAt: Date
    ) {
        self.provider = provider
        self.accountID = accountID
        self.fiveHour = fiveHour
        self.weekly = weekly
        self.capturedAt = capturedAt
    }
}

/// SplitBar'e kaydedilmiş bir Claude Code veya Codex hesabı. Kimlik bilgileri burada değil, Keychain'de tutulur.
public struct AIAccount: Codable, Equatable, Sendable, Identifiable {
    public let provider: AIAccountProvider
    public let accountID: String
    public let email: String
    public let planName: String?
    public let organizationName: String?

    public var id: String { "\(provider.rawValue):\(accountID)" }

    public init(
        provider: AIAccountProvider,
        accountID: String,
        email: String,
        planName: String?,
        organizationName: String?
    ) {
        self.provider = provider
        self.accountID = accountID
        self.email = email
        self.planName = planName
        self.organizationName = organizationName
    }
}

/// AI Usage "Limits" sekmesindeki bir sağlayıcı kartının görüntüleme modeli.
public struct ProviderLimitCard: Equatable, Sendable, Identifiable {
    public let provider: AIAccountProvider
    public let activeAccount: AIAccount?
    public let savedAccounts: [AIAccount]
    public let limits: ProviderLimitSnapshot?
    /// Kayıtlı her hesabın (`AIAccount.id`) son bilinen limitleri; hangi hesaba geçileceğini seçmeye yardımcı olur.
    public let savedAccountLimits: [String: ProviderLimitSnapshot]
    /// Yalnızca Claude için anlamlıdır: resmi limit verisini sağlayan status line köprüsü kurulu mu.
    public let isLimitSourceConnected: Bool
    public let isProviderRunning: Bool
    /// Aktif girişle ilgili kullanıcıya gösterilecek sorun (iptal edilmiş giriş, profil/giriş uyuşmazlığı).
    public let loginIssue: String?
    /// Kayıtlı girişi kullanılamaz olduğu için yeniden giriş gerektiren hesaplar (`AIAccount.id`).
    public let accountsNeedingLogin: Set<String>

    public var id: String { provider.rawValue }

    public init(
        provider: AIAccountProvider,
        activeAccount: AIAccount?,
        savedAccounts: [AIAccount],
        limits: ProviderLimitSnapshot?,
        savedAccountLimits: [String: ProviderLimitSnapshot],
        isLimitSourceConnected: Bool,
        isProviderRunning: Bool,
        loginIssue: String?,
        accountsNeedingLogin: Set<String>
    ) {
        self.provider = provider
        self.activeAccount = activeAccount
        self.savedAccounts = savedAccounts
        self.limits = limits
        self.savedAccountLimits = savedAccountLimits
        self.isLimitSourceConnected = isLimitSourceConnected
        self.isProviderRunning = isProviderRunning
        self.loginIssue = loginIssue
        self.accountsNeedingLogin = accountsNeedingLogin
    }
}

/// Yerel oturum kayıtlarından hesaplanan günlük token tüketimi.
public struct DailyTokenUsage: Equatable, Sendable, Identifiable {
    public let day: Date
    public let provider: AIAccountProvider
    public let tokens: Int

    public var id: String { "\(provider.rawValue)-\(day.timeIntervalSince1970)" }

    public init(day: Date, provider: AIAccountProvider, tokens: Int) {
        self.day = day
        self.provider = provider
        self.tokens = tokens
    }
}

/// Ollama'da şu an belleğe yüklü bir model.
public struct OllamaLoadedModel: Equatable, Sendable, Identifiable {
    public let name: String
    public let sizeBytes: Int64
    public let vramBytes: Int64
    public let expiresAt: Date?

    public var id: String { name }

    public init(name: String, sizeBytes: Int64, vramBytes: Int64, expiresAt: Date?) {
        self.name = name
        self.sizeBytes = sizeBytes
        self.vramBytes = vramBytes
        self.expiresAt = expiresAt
    }
}

/// Pencere sıfırlanma zamanı geçtiyse gerçek kullanım sıfırdır; kayıtlı eski yüzde gösterilmez.
public func effectiveUsedPercent(window: UsageWindow, now: Date) -> Double {
    if let resetsAt = window.resetsAt, resetsAt <= now {
        return 0.0
    }
    return min(max(window.usedPercent, 0.0), 100.0)
}
