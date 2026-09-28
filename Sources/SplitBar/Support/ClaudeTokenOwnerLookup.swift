import Foundation
import OSLog

/// Bir Claude Code erişim token'ının gerçek sahibi.
public struct ClaudeTokenOwner: Equatable, Sendable {
    public let accountUUID: String
    public let email: String
}

public enum ClaudeTokenOwnerError: Error, CustomStringConvertible {
    case malformedCredentials(reason: String)
    /// 401/403: token iptal edilmiş (başka bir oturum yeniledi) veya süresi dolmuş.
    case tokenRejected(status: Int, message: String)
    case unexpectedResponse(status: Int, body: String)
    case network(underlying: Error)

    public var description: String {
        switch self {
        case .malformedCredentials(let reason):
            return "Claude credentials are malformed: \(reason)"
        case .tokenRejected(let status, let message):
            return "Anthropic rejected the Claude login (HTTP \(status)): \(message)"
        case .unexpectedResponse(let status, let body):
            return "Unexpected response from Anthropic profile endpoint (HTTP \(status)): \(body)"
        case .network(let underlying):
            return "Could not reach Anthropic to verify the Claude login: \(underlying.localizedDescription)"
        }
    }

    /// Süresi dolmuş token Claude Code tarafından yenilenebilir; iptal edilmiş token yenilenemez.
    public var isExpiredButRefreshable: Bool {
        if case .tokenRejected(_, let message) = self {
            return message.lowercased().contains("expired")
        }
        return false
    }
}

private struct ClaudeCredentialsDTO: Decodable {
    struct OAuth: Decodable {
        let accessToken: String
    }
    let claudeAiOauth: OAuth
}

private struct ClaudeProfileDTO: Decodable {
    struct Account: Decodable {
        let uuid: String
        let email: String
    }
    let account: Account
}

private struct AnthropicErrorDTO: Decodable {
    struct Detail: Decodable {
        let message: String
    }
    let error: Detail
}

public func claudeAccessToken(fromCredentials credentials: Data) throws -> String {
    do {
        return try JSONDecoder().decode(ClaudeCredentialsDTO.self, from: credentials).claudeAiOauth.accessToken
    } catch {
        throw ClaudeTokenOwnerError.malformedCredentials(reason: error.localizedDescription)
    }
}

/// Token'ın hangi hesaba ait olduğunu Claude Code'un kendi kullandığı `/api/oauth/profile` uç noktasından sorar.
/// `~/.claude.json` başka çalışan oturumlarca yeniden yazılabildiği için kimliğin tek güvenilir kaynağı budur.
/// Ağ hatalarında uyarı loglanarak iki kez yeniden denenir; HTTP hataları yeniden denenmez.
public func fetchClaudeTokenOwner(accessToken: String) async throws -> ClaudeTokenOwner {
    guard let url = URL(string: "https://api.anthropic.com/api/oauth/profile") else {
        throw ClaudeTokenOwnerError.unexpectedResponse(status: -1, body: "invalid profile URL")
    }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 10.0

    var lastNetworkError: Error = URLError(.unknown)
    for attempt in 1...3 {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            lastNetworkError = error
            Logger.general.warning("Claude profile lookup network error attempt=\(attempt, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            try await Task.sleep(for: .milliseconds(400 * attempt))
            continue
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        switch status {
        case 200:
            do {
                let profile = try JSONDecoder().decode(ClaudeProfileDTO.self, from: data)
                return ClaudeTokenOwner(accountUUID: profile.account.uuid, email: profile.account.email)
            } catch {
                throw ClaudeTokenOwnerError.unexpectedResponse(status: status, body: "undecodable profile: \(error.localizedDescription)")
            }
        case 401, 403:
            let message = (try? JSONDecoder().decode(AnthropicErrorDTO.self, from: data))?.error.message
                ?? String(decoding: data.prefix(300), as: UTF8.self)
            throw ClaudeTokenOwnerError.tokenRejected(status: status, message: message)
        default:
            throw ClaudeTokenOwnerError.unexpectedResponse(status: status, body: String(decoding: data.prefix(300), as: UTF8.self))
        }
    }
    throw ClaudeTokenOwnerError.network(underlying: lastNetworkError)
}
