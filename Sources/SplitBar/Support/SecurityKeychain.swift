import Foundation

/// Compatibility shim over `SecretsStore`.
///
/// Historically this file shelled out to `/usr/bin/security` and passed secrets
/// to it as hex in `argv`, where any process of the same user could read them
/// from `ps`. Reads and deletes still work through the CLI (needed for items
/// owned by another application, whose access-control list trusts that tool),
/// but writes to foreign items are no longer possible, and SplitBar's own
/// secrets go through the Security framework directly.
public enum SecurityKeychainError: Error, CustomStringConvertible {
    case itemNotFound(service: String, account: String?)
    case writeNotSupported(service: String)
    case commandFailed(operation: String, service: String, status: Int32)
    case launchFailed(operation: String, underlying: Error)
    case invalidAttribute(operation: String, reason: String)

    public var description: String {
        switch self {
        case .itemNotFound(let service, let account):
            return "Keychain item not found service=\(service) account=\(account ?? "*")"
        case .writeNotSupported(let service):
            return "Writing to service=\(service) is not supported: secrets are never passed in process arguments."
        case .commandFailed(let operation, let service, let status):
            return "security \(operation) failed service=\(service) status=\(status)"
        case .launchFailed(let operation, let underlying):
            return "Could not launch /usr/bin/security for \(operation): \(underlying.localizedDescription)"
        case .invalidAttribute(let operation, let reason):
            return "security \(operation) rejected attribute: \(reason)"
        }
    }
}

private func map(_ error: Error, service: String, account: String?) -> SecurityKeychainError {
    if let storeError = error as? SecretsStoreError {
        switch storeError {
        case .itemNotFound:
            return .itemNotFound(service: service, account: account)
        case .writeNotSupported:
            return .writeNotSupported(service: service)
        case .status(let code, let operation):
            return .commandFailed(operation: operation, service: service, status: code)
        case .malformedSecret:
            return .invalidAttribute(operation: "read", reason: "stored value is not data")
        }
    }
    return .launchFailed(operation: "keychain", underlying: error)
}

/// Reads a generic password item. Items owned by other applications must be read
/// through the CLI store; SplitBar's own items should use `AppSecrets.store`.
public func readKeychainPassword(service: String, account: String?) throws -> Data {
    guard let account else {
        throw SecurityKeychainError.invalidAttribute(operation: "read", reason: "an account is required")
    }
    do {
        return try AppSecrets.foreignItemStore.read(service: service, account: account)
    } catch {
        throw map(error, service: service, account: account)
    }
}

/// Retained for call sites that want SplitBar's own native Keychain storage.
public func writeSplitBarKeychainPassword(service: String, account: String, password: Data) throws {
    do {
        try AppSecrets.store.write(password, service: service, account: account)
    } catch {
        throw map(error, service: service, account: account)
    }
}

/// Writing to an item owned by another application is refused: the only way to
/// do it through `/usr/bin/security` is to pass the secret in `argv`.
public func writeKeychainPassword(service: String, account: String, password: Data) throws {
    throw SecurityKeychainError.writeNotSupported(service: service)
}

public func deleteKeychainPassword(service: String, account: String) throws {
    do {
        try AppSecrets.foreignItemStore.delete(service: service, account: account)
    } catch {
        throw map(error, service: service, account: account)
    }
}

/// Removes a SplitBar-owned item.
public func deleteSplitBarKeychainPassword(service: String, account: String) throws {
    do {
        try AppSecrets.store.delete(service: service, account: account)
    } catch {
        throw map(error, service: service, account: account)
    }
}
