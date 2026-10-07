import Foundation
import OSLog

public enum AIAccountStoreError: Error, CustomStringConvertible {
    case cannotRemoveActiveAccount(account: AIAccount)
    case corruptSavedSecret(account: AIAccount, reason: String)
    case fileOperationFailed(path: String, operation: String, underlying: Error)
    case providerSessionsRunning(provider: AIAccountProvider, count: Int)
    case savedLoginInvalid(account: AIAccount, reason: String)

    public var description: String {
        switch self {
        case .providerSessionsRunning(let provider, let count):
            return "\(count) \(provider.displayName) session(s) are running (Terminal, IDE extensions, T3 Code or the \(provider.displayName) app). Running sessions keep refreshing the current login and would overwrite or revoke the switched one. Quit them, then switch again."
        case .savedLoginInvalid(let account, let reason):
            return "The saved \(account.provider.displayName) login for \(account.email) can no longer be used (\(reason)). Choose “Log In to Another Account…” and sign in as \(account.email) again."
        case .cannotRemoveActiveAccount(let account):
            return "\(account.email) is the active \(account.provider.displayName) account. Switch to another account before removing it."
        case .corruptSavedSecret(let account, let reason):
            return "Saved credentials for \(account.email) are unreadable: \(reason)"
        case .fileOperationFailed(let path, let operation, let underlying):
            return "\(operation) failed for \(path): \(underlying.localizedDescription)"
        }
    }
}

/// Diskte tutulan hassas olmayan hesap kaydı. Kimlik bilgileri Keychain'dedir.
public struct AIAccountRegistry: Codable, Equatable, Sendable {
    public var accounts: [AIAccount]
    /// Sağlayıcı başına SplitBar'in son hesap geçişi; bundan eski limit verisi önceki hesaba aittir.
    public var switchedAt: [String: Date]
    /// Hesap kimliği (`AIAccount.id`) başına son bilinen gerçek limitler.
    public var lastKnownLimits: [String: ProviderLimitSnapshot]
    /// Kayıtlı girişi iptal edilmiş, yeniden giriş gerektiren hesaplar (`AIAccount.id`).
    public var accountsNeedingLogin: Set<String>

    public static let empty = AIAccountRegistry(accounts: [], switchedAt: [:], lastKnownLimits: [:], accountsNeedingLogin: [])

    public init(
        accounts: [AIAccount],
        switchedAt: [String: Date],
        lastKnownLimits: [String: ProviderLimitSnapshot],
        accountsNeedingLogin: Set<String>
    ) {
        self.accounts = accounts
        self.switchedAt = switchedAt
        self.lastKnownLimits = lastKnownLimits
        self.accountsNeedingLogin = accountsNeedingLogin
    }

    private enum CodingKeys: String, CodingKey {
        case accounts, switchedAt, lastKnownLimits, accountsNeedingLogin
    }

    /// Önceki sürümlerin kayıtlarında `accountsNeedingLogin` yoktur; bu durumda hiçbir hesap işaretli değildir.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accounts = try container.decode([AIAccount].self, forKey: .accounts)
        self.switchedAt = try container.decode([String: Date].self, forKey: .switchedAt)
        self.lastKnownLimits = try container.decode([String: ProviderLimitSnapshot].self, forKey: .lastKnownLimits)
        self.accountsNeedingLogin = try container.decodeIfPresent(Set<String>.self, forKey: .accountsNeedingLogin) ?? []
    }
}

/// Hesap deposunun anlık görünümü.
public struct AIAccountsSnapshot: Equatable, Sendable {
    public let activeAccounts: [AIAccountProvider: AIAccount]
    public let registry: AIAccountRegistry
    /// Aktif Claude girişiyle ilgili kullanıcıya gösterilmesi gereken sorun (iptal, profil/giriş uyuşmazlığı).
    public let claudeLoginIssue: String?
}

/// Bir Claude kimlik bilgisinin doğrulama sonucu.
private enum ClaudeVerification {
    case verified(owner: ClaudeTokenOwner)
    case rejected(error: ClaudeTokenOwnerError)
}

/// Claude Code'un Keychain kimlik bilgisi ile `~/.claude.json` içindeki hesap profilinin birlikte saklanan kopyası.
private struct ClaudeAccountSecret: Codable {
    let credentials: String
    let oauthAccountJSON: String
}

/// Birden fazla Claude Code ve Codex hesabını saklar ve aralarında geçiş yapar.
/// Geçiş, CLI'ların kendi okuduğu kimlik bilgisi konumlarını (Claude: Keychain + `~/.claude.json`,
/// Codex: `~/.codex/auth.json`) değiştirir; böylece terminaldeki `claude`/`codex` da yeni hesabı kullanır.
public actor AIAccountStore {
    private static let claudeCredentialService = "Claude Code-credentials"

    /// Claude Code öğeyi `security … -a "$USER" -s "Claude Code-credentials"` ile okur/yazar
    /// (USER yoksa sistem kullanıcı adı). Aynı servis adıyla başka eski öğeler de bulunabildiğinden
    /// hesap adı her zaman açıkça verilir; aksi halde ilk bulunan (kullanılmayan) öğe okunur.
    private static var claudeCredentialAccount: String {
        ProcessInfo.processInfo.environment["USER"] ?? NSUserName()
    }
    private static let savedSecretServicePrefix = "com.baraka.splitbar.account."

    private let registryURL: URL
    private let claudeConfigURL: URL
    private let codexAuthURL: URL
    /// Aynı kimlik bilgisini her yenilemede Keychain'e yeniden yazmamak için son yazılan içerik.
    private var syncedSecrets: [String: Data] = [:]
    /// Aynı Claude kimlik bilgisi her yenilemede (20 sn) Anthropic'e yeniden sorulmaz.
    private var lastClaudeVerification: (credentials: Data, result: ClaudeVerification)?
    private var didRepairClaudeBackups = false

    public init(registryURL: URL, homeDirectory: URL) {
        self.registryURL = registryURL
        self.claudeConfigURL = homeDirectory.appendingPathComponent(".claude.json")
        self.codexAuthURL = homeDirectory.appendingPathComponent(".codex/auth.json")
    }

    // MARK: - Public API

    /// Aktif hesapları okur; kayıtlı değilse otomatik kaydeder, kayıtlıysa yenilenmiş token'larını günceller.
    /// Sağlayıcılar birbirinden bağımsız işlenir: birindeki hata loglanır ve diğerinin güncellenmesini engellemez.
    /// Claude token'ları, sahibi Anthropic'ten doğrulanmadan hiçbir hesap adına kaydedilmez.
    public func synchronize() async throws -> AIAccountsSnapshot {
        var registry = try loadRegistry()
        if !didRepairClaudeBackups {
            registry = await repairClaudeBackups(registry: registry)
            didRepairClaudeBackups = true
        }
        var active: [AIAccountProvider: AIAccount] = [:]
        var claudeIssue: String?

        do {
            if let codex = try readActiveCodex() {
                active[.codex] = codex.account
                try saveSecretIfChanged(account: codex.account, secret: codex.secret)
                registry = upserting(account: codex.account, into: registry)
                registry.accountsNeedingLogin.remove(codex.account.id)
            }
        } catch {
            Logger.general.error("AI account sync skipped provider=codex error=\(String(describing: error), privacy: .private)")
        }

        do {
            let result = try await synchronizeClaude(registry: registry)
            registry = result.registry
            active[.claude] = result.profileAccount
            claudeIssue = result.issue
        } catch {
            Logger.general.error("AI account sync skipped provider=claude error=\(String(describing: error), privacy: .private)")
        }

        try saveRegistry(registry)
        return AIAccountsSnapshot(activeAccounts: active, registry: registry, claudeLoginIssue: claudeIssue)
    }

    /// Hedef hesaba geçer. Sağlayıcının açık oturumu varsa reddedilir: açık oturumlar mevcut girişi yenileyip
    /// geri yazarak geçişi bozar ve kayıtlı kopyaları iptal ettirir. Önce mevcut hesap doğrulanarak yedeklenir.
    public func switchAccount(to target: AIAccount, runningSessionCount: Int) async throws -> AIAccountsSnapshot {
        guard runningSessionCount == 0 else {
            throw AIAccountStoreError.providerSessionsRunning(provider: target.provider, count: runningSessionCount)
        }
        _ = try await synchronize()
        let secret = try loadSavedSecret(for: target)

        switch target.provider {
        case .claude:
            try await verifySavedClaudeLogin(target: target, savedSecret: secret)
            try activateClaude(target: target, savedSecret: secret)
            lastClaudeVerification = nil
        case .codex:
            try activateCodex(target: target, savedSecret: secret)
        }

        var registry = try loadRegistry()
        registry.switchedAt[target.provider.rawValue] = Date()
        try saveRegistry(registry)
        Logger.general.info("Switched AI account provider=\(target.provider.rawValue, privacy: .public) account=\(target.accountID, privacy: .private)")
        return try await synchronize()
    }

    public func removeAccount(_ account: AIAccount) async throws -> AIAccountsSnapshot {
        let snapshot = try await synchronize()
        if snapshot.activeAccounts[account.provider]?.accountID == account.accountID {
            throw AIAccountStoreError.cannotRemoveActiveAccount(account: account)
        }
        do {
            try deleteKeychainPassword(service: savedSecretService(account.provider), account: account.accountID)
        } catch SecurityKeychainError.itemNotFound {
            Logger.general.notice("Saved credentials already absent account=\(account.accountID, privacy: .private)")
        }
        var registry = snapshot.registry
        registry.accounts.removeAll { $0.id == account.id }
        registry.lastKnownLimits[account.id] = nil
        registry.accountsNeedingLogin.remove(account.id)
        try saveRegistry(registry)
        syncedSecrets[account.id] = nil
        return AIAccountsSnapshot(activeAccounts: snapshot.activeAccounts, registry: registry, claudeLoginIssue: snapshot.claudeLoginIssue)
    }

    /// Hesaba ait gerçek limitleri kaydeder; daha yeni bir kayıt varsa eskisiyle ezilmez.
    public func recordLimits(_ limits: ProviderLimitSnapshot, for account: AIAccount) throws -> AIAccountRegistry {
        var registry = try loadRegistry()
        if let existing = registry.lastKnownLimits[account.id], existing.capturedAt >= limits.capturedAt {
            return registry
        }
        registry.lastKnownLimits[account.id] = limits
        try saveRegistry(registry)
        return registry
    }

    // MARK: - Claude

    private struct ActiveAccount {
        let account: AIAccount
        let secret: Data
    }

    private struct ClaudeSyncResult {
        let registry: AIAccountRegistry
        let profileAccount: AIAccount?
        let issue: String?
    }

    /// `~/.claude.json` profilini gösterim için okur; kimlik bilgisini ise gerçek sahibine göre yedekler.
    /// Profil başka çalışan oturumlarca yeniden yazılabildiğinden eşleştirme profile değil, token sahibine dayanır.
    private func synchronizeClaude(registry: AIAccountRegistry) async throws -> ClaudeSyncResult {
        guard let profile = try readClaudeProfile() else {
            return ClaudeSyncResult(registry: registry, profileAccount: nil, issue: nil)
        }
        var updated = upserting(account: profile.account, into: registry)
        let credentials: Data
        do {
            credentials = try readKeychainPassword(service: Self.claudeCredentialService, account: Self.claudeCredentialAccount)
        } catch SecurityKeychainError.itemNotFound {
            return ClaudeSyncResult(registry: updated, profileAccount: profile.account, issue: "Claude Code is logged out. Log in to use \(profile.account.email).")
        }

        let verification: ClaudeVerification
        if let cached = lastClaudeVerification, cached.credentials == credentials {
            verification = cached.result
        } else {
            do {
                verification = try await verifyClaudeCredentials(credentials)
            } catch {
                // Ağ hatası: doğrulanamayan kimlik bilgisi kaydedilmez, bir sonraki yenilemede tekrar denenir
                Logger.general.warning("Claude login verification unavailable error=\(String(describing: error), privacy: .private)")
                return ClaudeSyncResult(registry: updated, profileAccount: profile.account, issue: nil)
            }
            lastClaudeVerification = (credentials: credentials, result: verification)
        }

        switch verification {
        case .verified(let owner) where owner.accountUUID == profile.account.accountID:
            let secret = try encodeClaudeSecret(credentials: credentials, oauthAccountJSON: profile.oauthAccountJSON)
            try saveSecretIfChanged(account: profile.account, secret: secret)
            updated.accountsNeedingLogin.remove(profile.account.id)
            return ClaudeSyncResult(registry: updated, profileAccount: profile.account, issue: nil)

        case .verified(let owner):
            // Başka bir oturum profili değiştirmiş: token gerçek sahibinin yedeğine yazılır, profil hesabına değil
            if let ownerAccount = updated.accounts.first(where: { $0.provider == .claude && $0.accountID == owner.accountUUID }),
               let ownerProfileJSON = try? savedClaudeProfileJSON(for: ownerAccount) {
                let secret = try encodeClaudeSecret(credentials: credentials, oauthAccountJSON: ownerProfileJSON)
                try saveSecretIfChanged(account: ownerAccount, secret: secret)
                updated.accountsNeedingLogin.remove(ownerAccount.id)
            }
            return ClaudeSyncResult(
                registry: updated,
                profileAccount: profile.account,
                issue: "Claude Code shows \(profile.account.email), but the active login belongs to \(owner.email). A running session changed it. Quit all Claude sessions and switch again."
            )

        case .rejected(let error) where error.isExpiredButRefreshable:
            // Süresi dolmuş token Claude Code'un bir sonraki isteğinde yenilenir; yenilenen token doğrulanıp kaydedilir
            return ClaudeSyncResult(registry: updated, profileAccount: profile.account, issue: nil)

        case .rejected(let error):
            updated.accountsNeedingLogin.insert(profile.account.id)
            Logger.general.error("Active Claude login rejected account=\(profile.account.accountID, privacy: .private) error=\(String(describing: error), privacy: .private)")
            return ClaudeSyncResult(
                registry: updated,
                profileAccount: profile.account,
                issue: "The active Claude login was revoked (another session refreshed it). Log in again as \(profile.account.email)."
            )
        }
    }

    private struct ClaudeProfile {
        let account: AIAccount
        let oauthAccountJSON: String
    }

    private func readClaudeProfile() throws -> ClaudeProfile? {
        guard FileManager.default.fileExists(atPath: claudeConfigURL.path) else {
            return nil
        }
        let config = try readJSONObject(at: claudeConfigURL)
        guard let oauthAccount = config["oauthAccount"] as? [String: Any] else {
            return nil
        }
        let oauthData = try serializeJSON(oauthAccount, path: claudeConfigURL.path)
        return ClaudeProfile(
            account: try parseClaudeAccount(oauthAccountJSON: oauthData),
            oauthAccountJSON: String(decoding: oauthData, as: UTF8.self)
        )
    }

    private func verifyClaudeCredentials(_ credentials: Data) async throws -> ClaudeVerification {
        let token = try claudeAccessToken(fromCredentials: credentials)
        do {
            return .verified(owner: try await fetchClaudeTokenOwner(accessToken: token))
        } catch let error as ClaudeTokenOwnerError {
            if case .tokenRejected = error {
                return .rejected(error: error)
            }
            throw error
        }
    }

    /// Geçişten önce hedef yedeğin gerçekten o hesaba ait ve hâlâ geçerli olduğunu doğrular.
    private func verifySavedClaudeLogin(target: AIAccount, savedSecret: Data) async throws {
        let secret = try decodeClaudeSecret(savedSecret, account: target)
        switch try await verifyClaudeCredentials(Data(secret.credentials.utf8)) {
        case .verified(let owner) where owner.accountUUID == target.accountID:
            return
        case .verified(let owner):
            throw AIAccountStoreError.savedLoginInvalid(account: target, reason: "it belongs to \(owner.email)")
        case .rejected(let error) where error.isExpiredButRefreshable:
            return
        case .rejected(let error):
            var registry = try loadRegistry()
            registry.accountsNeedingLogin.insert(target.id)
            try saveRegistry(registry)
            throw AIAccountStoreError.savedLoginInvalid(account: target, reason: String(describing: error))
        }
    }

    /// Açılışta bir kez: her Claude yedeğinin sahibini doğrular. Yanlış etikete kaydedilmiş geçerli bir giriş,
    /// gerçek sahibinin yedeği kullanılamaz durumdaysa oraya taşınır; iptal edilmiş yedekler işaretlenir.
    private func repairClaudeBackups(registry: AIAccountRegistry) async -> AIAccountRegistry {
        var updated = registry
        let claudeAccounts = registry.accounts.filter { $0.provider == .claude }
        var results: [String: (secret: ClaudeAccountSecret, verification: ClaudeVerification)] = [:]
        var repairedOwners: Set<String> = []
        for account in claudeAccounts {
            do {
                let secret = try decodeClaudeSecret(try loadSavedSecret(for: account), account: account)
                results[account.id] = (secret, try await verifyClaudeCredentials(Data(secret.credentials.utf8)))
            } catch SecurityKeychainError.itemNotFound {
                continue
            } catch {
                Logger.general.warning("Claude backup check skipped account=\(account.accountID, privacy: .private) error=\(String(describing: error), privacy: .private)")
            }
        }

        for account in claudeAccounts {
            guard let result = results[account.id] else { continue }
            switch result.verification {
            case .verified(let owner) where owner.accountUUID == account.accountID:
                updated.accountsNeedingLogin.remove(account.id)
            case .verified(let owner):
                // Etiket yanlış: bu yedek başka hesaba ait. Sahibinin kendi yedeği geçerliyse ona dokunulmaz.
                if let ownerAccount = claudeAccounts.first(where: { $0.accountID == owner.accountUUID }) {
                    let ownerIsHealthy: Bool
                    if case .verified(let ownerOwner)? = results[ownerAccount.id]?.verification {
                        ownerIsHealthy = ownerOwner.accountUUID == ownerAccount.accountID
                    } else {
                        ownerIsHealthy = false
                    }
                    if !ownerIsHealthy, let ownerSecret = results[ownerAccount.id]?.secret {
                        do {
                            let moved = try encodeClaudeSecret(credentials: Data(result.secret.credentials.utf8), oauthAccountJSON: ownerSecret.oauthAccountJSON)
                            try writeSavedSecret(account: ownerAccount, secret: moved)
                            repairedOwners.insert(ownerAccount.id)
                            Logger.general.notice("Moved mislabeled Claude backup to its owner account=\(ownerAccount.accountID, privacy: .private)")
                        } catch {
                            Logger.general.error("Moving mislabeled Claude backup failed error=\(String(describing: error), privacy: .private)")
                        }
                    }
                }
                // Bu etiketteki kopya başka hesaba ait; yanlış hesaba geçişe yol açmasın diye silinir
                do {
                    try deleteKeychainPassword(service: savedSecretService(account.provider), account: account.accountID)
                    syncedSecrets[account.id] = nil
                } catch {
                    Logger.general.error("Deleting mislabeled Claude backup failed error=\(String(describing: error), privacy: .private)")
                }
                updated.accountsNeedingLogin.insert(account.id)
            case .rejected(let error) where error.isExpiredButRefreshable:
                continue
            case .rejected:
                updated.accountsNeedingLogin.insert(account.id)
            }
        }
        // Geçerli bir giriş taşınan hesaplar, sıralamadan bağımsız olarak kullanılabilir sayılır
        updated.accountsNeedingLogin.subtract(repairedOwners)
        do {
            try saveRegistry(updated)
        } catch {
            Logger.general.error("Saving repaired account registry failed error=\(String(describing: error), privacy: .private)")
        }
        return updated
    }

    private func encodeClaudeSecret(credentials: Data, oauthAccountJSON: String) throws -> Data {
        let secret = ClaudeAccountSecret(credentials: String(decoding: credentials, as: UTF8.self), oauthAccountJSON: oauthAccountJSON)
        do {
            return try JSONEncoder().encode(secret)
        } catch {
            throw AIAccountStoreError.fileOperationFailed(path: "keychain", operation: "Encode Claude backup", underlying: error)
        }
    }

    private func decodeClaudeSecret(_ data: Data, account: AIAccount) throws -> ClaudeAccountSecret {
        do {
            return try JSONDecoder().decode(ClaudeAccountSecret.self, from: data)
        } catch {
            throw AIAccountStoreError.corruptSavedSecret(account: account, reason: error.localizedDescription)
        }
    }

    private func savedClaudeProfileJSON(for account: AIAccount) throws -> String {
        try decodeClaudeSecret(try loadSavedSecret(for: account), account: account).oauthAccountJSON
    }

    private func activateClaude(target: AIAccount, savedSecret: Data) throws {
        let secret = try decodeClaudeSecret(savedSecret, account: target)
        guard let oauthObject = try? JSONSerialization.jsonObject(with: Data(secret.oauthAccountJSON.utf8)) as? [String: Any] else {
            throw AIAccountStoreError.corruptSavedSecret(account: target, reason: "oauthAccount is not a JSON object")
        }

        let keychainAccount = Self.claudeCredentialAccount
        // ~/.claude.json'ın geri kalanı Claude Code'a aittir; yalnızca oauthAccount değiştirilir.
        // Yazımlardan önce hazırlanır ki serileştirme hatası hiçbir şeyi değiştirmeden dursun.
        var config = try readJSONObject(at: claudeConfigURL)
        config["oauthAccount"] = oauthObject
        let configData = try serializeJSON(config, path: claudeConfigURL.path)
        let previousCredentials: Data?
        do {
            previousCredentials = try readKeychainPassword(service: Self.claudeCredentialService, account: keychainAccount)
        } catch SecurityKeychainError.itemNotFound {
            previousCredentials = nil
        }

        try writeKeychainPassword(
            service: Self.claudeCredentialService,
            account: keychainAccount,
            password: Data(secret.credentials.utf8)
        )
        do {
            try writeAtomically(configData, to: claudeConfigURL, permissions: nil)
        } catch {
            // Kimlik bilgisi ile profil uyuşmaz kalmasın: Keychain önceki hesaba geri alınır
            if let previousCredentials {
                try writeKeychainPassword(
                    service: Self.claudeCredentialService,
                    account: keychainAccount,
                    password: previousCredentials
                )
            }
            throw error
        }
    }

    // MARK: - Codex

    private func readActiveCodex() throws -> ActiveAccount? {
        guard FileManager.default.fileExists(atPath: codexAuthURL.path) else {
            return nil
        }
        let authData: Data
        do {
            authData = try Data(contentsOf: codexAuthURL)
        } catch {
            throw AIAccountStoreError.fileOperationFailed(path: codexAuthURL.path, operation: "Read", underlying: error)
        }
        let account = try parseCodexAccount(authJSON: authData)
        return ActiveAccount(account: account, secret: authData)
    }

    private func activateCodex(target: AIAccount, savedSecret: Data) throws {
        let account: AIAccount
        do {
            account = try parseCodexAccount(authJSON: savedSecret)
        } catch {
            throw AIAccountStoreError.corruptSavedSecret(account: target, reason: String(describing: error))
        }
        guard account.accountID == target.accountID else {
            throw AIAccountStoreError.corruptSavedSecret(account: target, reason: "saved auth.json belongs to \(account.accountID)")
        }
        try writeAtomically(savedSecret, to: codexAuthURL, permissions: 0o600)
    }

    // MARK: - Storage helpers

    private func savedSecretService(_ provider: AIAccountProvider) -> String {
        Self.savedSecretServicePrefix + provider.rawValue
    }

    /// Kayıtlı kopyalar ikili içerik taşıyabildiği için Keychain'de base64 metin olarak tutulur.
    private func loadSavedSecret(for account: AIAccount) throws -> Data {
        let stored = try readKeychainPassword(service: savedSecretService(account.provider), account: account.accountID)
        guard let decoded = Data(base64Encoded: stored) else {
            throw AIAccountStoreError.corruptSavedSecret(account: account, reason: "stored value is not base64")
        }
        return decoded
    }

    private func saveSecretIfChanged(account: AIAccount, secret: Data) throws {
        guard syncedSecrets[account.id] != secret else {
            return
        }
        try writeSavedSecret(account: account, secret: secret)
    }

    private func writeSavedSecret(account: AIAccount, secret: Data) throws {
        try writeKeychainPassword(
            service: savedSecretService(account.provider),
            account: account.accountID,
            password: Data(secret.base64EncodedString().utf8)
        )
        syncedSecrets[account.id] = secret
    }

    private func upserting(account: AIAccount, into registry: AIAccountRegistry) -> AIAccountRegistry {
        var updated = registry
        if let index = updated.accounts.firstIndex(where: { $0.id == account.id }) {
            updated.accounts[index] = account
        } else {
            updated.accounts.append(account)
            Logger.general.info("Saved new AI account provider=\(account.provider.rawValue, privacy: .public) account=\(account.accountID, privacy: .private)")
        }
        return updated
    }

    private func loadRegistry() throws -> AIAccountRegistry {
        guard FileManager.default.fileExists(atPath: registryURL.path) else {
            return .empty
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(AIAccountRegistry.self, from: Data(contentsOf: registryURL))
        } catch {
            throw AIAccountStoreError.fileOperationFailed(path: registryURL.path, operation: "Decode account registry", underlying: error)
        }
    }

    private func saveRegistry(_ registry: AIAccountRegistry) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data: Data
        do {
            data = try encoder.encode(registry)
        } catch {
            throw AIAccountStoreError.fileOperationFailed(path: registryURL.path, operation: "Encode account registry", underlying: error)
        }
        try writeAtomically(data, to: registryURL, permissions: nil)
    }

    /// Yabancı şemalı JSON (Claude Code yapılandırması) olduğu gibi korunmalı; bu yüzden tipsiz sözlük kullanılır.
    private func readJSONObject(at url: URL) throws -> [String: Any] {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        } catch {
            throw AIAccountStoreError.fileOperationFailed(path: url.path, operation: "Read JSON", underlying: error)
        }
        guard let dictionary = object as? [String: Any] else {
            throw ProviderDataParsingError.missingField(source: url.path, field: "<root object>")
        }
        return dictionary
    }

    private func serializeJSON(_ object: [String: Any], path: String) throws -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .withoutEscapingSlashes])
        } catch {
            throw AIAccountStoreError.fileOperationFailed(path: path, operation: "Serialize JSON", underlying: error)
        }
    }

    private func writeAtomically(_ data: Data, to url: URL, permissions: Int?) throws {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            if let permissions {
                try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path)
            }
        } catch {
            throw AIAccountStoreError.fileOperationFailed(path: url.path, operation: "Write", underlying: error)
        }
    }
}
