import Foundation

public enum ProviderDataParsingError: Error, CustomStringConvertible {
    case invalidJSON(source: String, underlying: Error)
    case missingField(source: String, field: String)
    case invalidJWT(source: String)

    public var description: String {
        switch self {
        case .invalidJSON(let source, let underlying):
            return "\(source) is not valid JSON: \(underlying.localizedDescription)"
        case .missingField(let source, let field):
            return "\(source) is missing required field '\(field)'"
        case .invalidJWT(let source):
            return "\(source) does not contain a decodable JWT payload"
        }
    }
}

private let isoFractionalStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
private let isoPlainStyle = Date.ISO8601FormatStyle()

/// Kesirli saniyeli ("…06.831Z") ve kesirsiz ISO 8601 zaman damgalarını çözer.
private func parseISODate(_ text: String) -> Date? {
    if let date = try? isoFractionalStyle.parse(text) {
        return date
    }
    return try? isoPlainStyle.parse(text)
}

// MARK: - Codex

private struct CodexRateLimitWindowDTO: Decodable {
    let used_percent: Double
    let window_minutes: Int
    let resets_at: Double?
}

private struct CodexRateLimitsDTO: Decodable {
    let primary: CodexRateLimitWindowDTO?
    let secondary: CodexRateLimitWindowDTO?
}

private struct CodexTokenCountPayloadDTO: Decodable {
    let type: String
    let rate_limits: CodexRateLimitsDTO?
}

private struct CodexEventLineDTO: Decodable {
    let timestamp: String
    let payload: CodexTokenCountPayloadDTO
}

private struct CodexSessionMetaPayloadDTO: Decodable {
    let creator_account_id: String?
}

private struct CodexSessionMetaLineDTO: Decodable {
    let type: String
    let payload: CodexSessionMetaPayloadDTO
}

private func codexWindow(_ dto: CodexRateLimitWindowDTO?) -> UsageWindow? {
    guard let dto else { return nil }
    return UsageWindow(
        usedPercent: dto.used_percent,
        windowMinutes: dto.window_minutes,
        resetsAt: dto.resets_at.map { Date(timeIntervalSince1970: $0) }
    )
}

/// Codex oturum kaydındaki bir `token_count` olay satırından plan limitlerini çıkarır.
/// Satır limit içermiyorsa `nil` döner (her olay limit taşımaz).
public func parseCodexRateLimitLine(_ line: Substring, accountID: String?) -> ProviderLimitSnapshot? {
    guard line.contains("\"rate_limits\""), line.contains("\"token_count\"") else {
        return nil
    }
    guard let event = try? JSONDecoder().decode(CodexEventLineDTO.self, from: Data(line.utf8)),
          event.payload.type == "token_count",
          let limits = event.payload.rate_limits,
          let capturedAt = parseISODate(event.timestamp) else {
        return nil
    }
    let fiveHour = codexWindow(limits.primary)
    let weekly = codexWindow(limits.secondary)
    guard fiveHour != nil || weekly != nil else {
        return nil
    }
    return ProviderLimitSnapshot(
        provider: .codex,
        accountID: accountID,
        fiveHour: fiveHour,
        weekly: weekly,
        capturedAt: capturedAt
    )
}

/// Codex oturum kaydının ilk satırındaki `session_meta` olayından oturumu açan hesabın kimliğini okur.
public func parseCodexSessionAccountID(firstLine: Substring) -> String? {
    guard let meta = try? JSONDecoder().decode(CodexSessionMetaLineDTO.self, from: Data(firstLine.utf8)),
          meta.type == "session_meta" else {
        return nil
    }
    return meta.payload.creator_account_id
}

private struct CodexAuthTokensDTO: Decodable {
    let id_token: String
    let account_id: String?
}

private struct CodexAuthFileDTO: Decodable {
    let tokens: CodexAuthTokensDTO?
}

private struct CodexOpenAIAuthClaimsDTO: Decodable {
    let chatgpt_plan_type: String?
    let chatgpt_account_id: String?
}

private struct CodexIDTokenClaimsDTO: Decodable {
    let email: String?
    let openAIAuth: CodexOpenAIAuthClaimsDTO?

    enum CodingKeys: String, CodingKey {
        case email
        case openAIAuth = "https://api.openai.com/auth"
    }
}

/// JWT'nin imzasını doğrulamadan yalnızca gösterim amaçlı payload kısmını çözer.
private func decodeJWTPayload(_ token: String, source: String) throws -> Data {
    let segments = token.split(separator: ".")
    guard segments.count >= 2 else {
        throw ProviderDataParsingError.invalidJWT(source: source)
    }
    var base64 = String(segments[1])
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
    guard let data = Data(base64Encoded: base64) else {
        throw ProviderDataParsingError.invalidJWT(source: source)
    }
    return data
}

/// `~/.codex/auth.json` içeriğinden aktif Codex hesabını çıkarır.
public func parseCodexAccount(authJSON: Data) throws -> AIAccount {
    let source = "~/.codex/auth.json"
    let auth: CodexAuthFileDTO
    do {
        auth = try JSONDecoder().decode(CodexAuthFileDTO.self, from: authJSON)
    } catch {
        throw ProviderDataParsingError.invalidJSON(source: source, underlying: error)
    }
    guard let tokens = auth.tokens else {
        throw ProviderDataParsingError.missingField(source: source, field: "tokens")
    }
    let claimsData = try decodeJWTPayload(tokens.id_token, source: "\(source) id_token")
    let claims: CodexIDTokenClaimsDTO
    do {
        claims = try JSONDecoder().decode(CodexIDTokenClaimsDTO.self, from: claimsData)
    } catch {
        throw ProviderDataParsingError.invalidJSON(source: "\(source) id_token", underlying: error)
    }
    guard let accountID = tokens.account_id ?? claims.openAIAuth?.chatgpt_account_id else {
        throw ProviderDataParsingError.missingField(source: source, field: "tokens.account_id")
    }
    return AIAccount(
        provider: .codex,
        accountID: accountID,
        email: claims.email ?? accountID,
        planName: claims.openAIAuth?.chatgpt_plan_type?.capitalized,
        organizationName: nil
    )
}

// MARK: - Claude

/// Claude Code sürümüne göre `resets_at` epoch saniye (sayı) veya ISO 8601 metin olabilir.
private struct ClaudeResetTimeDTO: Decodable {
    let date: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let seconds = try? container.decode(Double.self) {
            self.date = Date(timeIntervalSince1970: seconds)
            return
        }
        let text = try container.decode(String.self)
        guard let date = parseISODate(text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized resets_at: \(text)")
        }
        self.date = date
    }
}

private struct ClaudeStatusLineWindowDTO: Decodable {
    let used_percentage: Double?
    let resets_at: ClaudeResetTimeDTO?
}

private struct ClaudeStatusLineRateLimitsDTO: Decodable {
    let five_hour: ClaudeStatusLineWindowDTO?
    let seven_day: ClaudeStatusLineWindowDTO?
}

private struct ClaudeStatusLineDTO: Decodable {
    let rate_limits: ClaudeStatusLineRateLimitsDTO?
}

private func claudeWindow(_ dto: ClaudeStatusLineWindowDTO?, windowMinutes: Int) -> UsageWindow? {
    guard let dto, let used = dto.used_percentage else { return nil }
    return UsageWindow(usedPercent: used, windowMinutes: windowMinutes, resetsAt: dto.resets_at?.date)
}

/// Claude Code'un status line komutuna gönderdiği JSON'dan resmi plan limitlerini çıkarır.
/// API anahtarı ile kullanımda Claude `rate_limits` göndermez; bu durumda `nil` döner.
public func parseClaudeStatusLine(_ data: Data, capturedAt: Date) throws -> ProviderLimitSnapshot? {
    let dto: ClaudeStatusLineDTO
    do {
        dto = try JSONDecoder().decode(ClaudeStatusLineDTO.self, from: data)
    } catch {
        throw ProviderDataParsingError.invalidJSON(source: "Claude status line capture", underlying: error)
    }
    let fiveHour = claudeWindow(dto.rate_limits?.five_hour, windowMinutes: 300)
    let weekly = claudeWindow(dto.rate_limits?.seven_day, windowMinutes: 10_080)
    guard fiveHour != nil || weekly != nil else {
        return nil
    }
    return ProviderLimitSnapshot(
        provider: .claude,
        accountID: nil,
        fiveHour: fiveHour,
        weekly: weekly,
        capturedAt: capturedAt
    )
}

private struct T3ClaudeCacheDTO: Decodable {
    struct Auth: Decodable {
        let status: String?
        let email: String?
    }
    struct Window: Decodable {
        let id: String
        let kind: String?
        let windowDurationMins: Int
        let usedPercent: Double
        let resetsAt: String?
    }
    struct UsageLimits: Decodable {
        let checkedAt: String
        let windows: [Window]
    }
    let auth: Auth?
    let usageLimits: UsageLimits?
}

public struct EmailScopedLimits: Equatable, Sendable {
    public let email: String
    public let snapshot: ProviderLimitSnapshot
}

/// T3 Code'un sağlayıcı önbelleğinden (`~/.t3/caches/claudeAgent*.json`, `codex.json`) resmi kullanım
/// limitlerini okur. T3 bu değerleri sağlayıcıların kendi kullanım uç noktalarından birkaç dakikada bir alır
/// ve hesabın e-postasıyla saklar; böylece limitler status line gerektirmeden ve doğru hesaba bağlanarak okunur.
public func parseT3UsageCache(_ data: Data, provider: AIAccountProvider, source: String) throws -> EmailScopedLimits? {
    let dto: T3ClaudeCacheDTO
    do {
        dto = try JSONDecoder().decode(T3ClaudeCacheDTO.self, from: data)
    } catch {
        throw ProviderDataParsingError.invalidJSON(source: source, underlying: error)
    }
    guard let email = dto.auth?.email, dto.auth?.status == "authenticated",
          let limits = dto.usageLimits,
          let checkedAt = parseISODate(limits.checkedAt) else {
        return nil
    }
    // İlk "session" ve ilk "weekly" pencere genel limittir; sonrakiler model bazlı ek pencerelerdir
    func window(kind: String) -> UsageWindow? {
        guard let match = limits.windows.first(where: { $0.kind == kind }) else { return nil }
        return UsageWindow(
            usedPercent: match.usedPercent,
            windowMinutes: match.windowDurationMins,
            resetsAt: match.resetsAt.flatMap(parseISODate)
        )
    }
    let fiveHour = window(kind: "session")
    let weekly = window(kind: "weekly")
    guard fiveHour != nil || weekly != nil else {
        return nil
    }
    return EmailScopedLimits(
        email: email,
        snapshot: ProviderLimitSnapshot(provider: provider, accountID: nil, fiveHour: fiveHour, weekly: weekly, capturedAt: checkedAt)
    )
}

private struct ClaudeOAuthAccountDTO: Decodable {
    let accountUuid: String
    let emailAddress: String?
    let organizationName: String?
    let billingType: String?
    let organizationRateLimitTier: String?
}

/// `~/.claude.json` içindeki `oauthAccount` nesnesinden aktif Claude hesabını çıkarır.
public func parseClaudeAccount(oauthAccountJSON: Data) throws -> AIAccount {
    let dto: ClaudeOAuthAccountDTO
    do {
        dto = try JSONDecoder().decode(ClaudeOAuthAccountDTO.self, from: oauthAccountJSON)
    } catch {
        throw ProviderDataParsingError.invalidJSON(source: "~/.claude.json oauthAccount", underlying: error)
    }
    return AIAccount(
        provider: .claude,
        accountID: dto.accountUuid,
        email: dto.emailAddress ?? dto.accountUuid,
        planName: dto.organizationRateLimitTier.map { claudePlanDisplayName(tier: $0) } ?? dto.billingType,
        organizationName: dto.organizationName
    )
}

/// "default_claude_max_20x" gibi katman kimliklerini "Max 20x" gibi okunur ada çevirir.
public func claudePlanDisplayName(tier: String) -> String {
    let lowered = tier.lowercased()
    if lowered.contains("max_20x") { return "Max 20x" }
    if lowered.contains("max_5x") { return "Max 5x" }
    if lowered.contains("max") { return "Max" }
    if lowered.contains("pro") || lowered == "default_claude_ai" { return "Pro" }
    if lowered.contains("team") { return "Team" }
    if lowered.contains("enterprise") { return "Enterprise" }
    return tier
}

// MARK: - Token history

private struct ClaudeUsageDTO: Decodable {
    let input_tokens: Int?
    let output_tokens: Int?
    let cache_creation_input_tokens: Int?
    let cache_read_input_tokens: Int?
}

private struct ClaudeMessageDTO: Decodable {
    let id: String?
    let usage: ClaudeUsageDTO?
}

private struct ClaudeTranscriptLineDTO: Decodable {
    let type: String?
    let timestamp: String?
    let requestId: String?
    let message: ClaudeMessageDTO?
}

public struct TranscriptTokenUsage: Equatable, Sendable {
    public let dedupeKey: String
    public let timestamp: Date
    public let tokens: Int
}

/// Claude transkript satırından (asistan mesajı) önbellek dahil token kullanımını çıkarır.
/// Aynı yanıt birden çok satıra bölündüğü için `dedupeKey` ile tekilleştirilmelidir.
public func parseClaudeTranscriptUsage(line: Substring) -> TranscriptTokenUsage? {
    guard line.contains("\"usage\""), line.contains("\"assistant\"") else {
        return nil
    }
    guard let dto = try? JSONDecoder().decode(ClaudeTranscriptLineDTO.self, from: Data(line.utf8)),
          dto.type == "assistant",
          let usage = dto.message?.usage,
          let timestampText = dto.timestamp,
          let timestamp = parseISODate(timestampText) else {
        return nil
    }
    let tokens = (usage.input_tokens ?? 0)
        + (usage.output_tokens ?? 0)
        + (usage.cache_creation_input_tokens ?? 0)
        + (usage.cache_read_input_tokens ?? 0)
    return TranscriptTokenUsage(
        dedupeKey: "\(dto.message?.id ?? timestampText)|\(dto.requestId ?? "")",
        timestamp: timestamp,
        tokens: tokens
    )
}

private struct CodexLastTokenUsageDTO: Decodable {
    let total_tokens: Int
}

private struct CodexTokenInfoDTO: Decodable {
    let last_token_usage: CodexLastTokenUsageDTO?
}

private struct CodexTokenUsagePayloadDTO: Decodable {
    let type: String
    let info: CodexTokenInfoDTO?
}

private struct CodexTokenUsageLineDTO: Decodable {
    let timestamp: String
    let payload: CodexTokenUsagePayloadDTO
}

/// Codex `token_count` olayından o tura ait token tüketimini çıkarır.
public func parseCodexTokenUsage(line: Substring) -> TranscriptTokenUsage? {
    guard line.contains("\"token_count\""), line.contains("\"last_token_usage\"") else {
        return nil
    }
    guard let dto = try? JSONDecoder().decode(CodexTokenUsageLineDTO.self, from: Data(line.utf8)),
          dto.payload.type == "token_count",
          let tokens = dto.payload.info?.last_token_usage?.total_tokens,
          let timestamp = parseISODate(dto.timestamp) else {
        return nil
    }
    return TranscriptTokenUsage(dedupeKey: dto.timestamp, timestamp: timestamp, tokens: tokens)
}
