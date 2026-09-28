import Foundation

public enum LinkValidationError: Error, Equatable, Sendable {
    case empty
    case invalidURL
    case unsupportedScheme(String)
}

public func normalizedLink(raw: String) -> Result<URL, LinkValidationError> {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
        return .failure(.empty)
    }

    let urlString: String
    if trimmed.contains("://") {
        urlString = trimmed
    } else {
        urlString = "https://" + trimmed
    }

    guard let url = URL(string: urlString) else {
        return .failure(.invalidURL)
    }

    guard let scheme = url.scheme?.lowercased() else {
        return .failure(.invalidURL)
    }

    if scheme != "http" && scheme != "https" {
        return .failure(.unsupportedScheme(scheme))
    }

    return .success(url)
}
