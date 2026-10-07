import Foundation
import Security

/// Storage abstraction for secrets. Implementations must never place secret
/// material in process arguments, logs, or error text.
public protocol SecretsStore: Sendable {
    func read(service: String, account: String) throws -> Data
    func write(_ secret: Data, service: String, account: String) throws
    func delete(service: String, account: String) throws
}

public enum SecretsStoreError: Error, Equatable, Sendable {
    case itemNotFound(service: String, account: String)
    case writeNotSupported(service: String)
    case status(OSStatus, operation: String)
    case malformedSecret

    public var errorDescription: String? {
        switch self {
        case .itemNotFound: "No stored secret for this account."
        case .writeNotSupported: "This store is read-only."
        case .status(let code, let operation): "Keychain \(operation) failed (OSStatus \(code))."
        case .malformedSecret: "The stored secret could not be decoded."
        }
    }
}

/// Native Keychain implementation for items SplitBar owns.
///
/// Items are created `WhenUnlockedThisDeviceOnly`, so they never sync to iCloud
/// Keychain and are not restored onto a different Mac. This path uses the
/// Security framework directly, so no secret is ever visible in `ps`.
public struct SystemKeychainSecretsStore: SecretsStore {
    private let accessGroup: String?

    public init(accessGroup: String? = nil) {
        self.accessGroup = accessGroup
    }

    private func baseQuery(service: String, account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }

    public func read(service: String, account: String) throws -> Data {
        var query = baseQuery(service: service, account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else {
                throw SecretsStoreError.malformedSecret
            }
            return data
        case errSecItemNotFound:
            throw SecretsStoreError.itemNotFound(service: service, account: account)
        default:
            throw SecretsStoreError.status(status, operation: "read")
        }
    }

    public func write(_ secret: Data, service: String, account: String) throws {
        let query = baseQuery(service: service, account: account)
        let attributes: [String: Any] = [
            kSecValueData as String: secret,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw SecretsStoreError.status(updateStatus, operation: "update")
        }

        var insert = query
        insert.merge(attributes) { _, new in new }
        let addStatus = SecItemAdd(insert as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw SecretsStoreError.status(addStatus, operation: "add")
        }
    }

    public func delete(service: String, account: String) throws {
        let status = SecItemDelete(baseQuery(service: service, account: account) as CFDictionary)
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            throw SecretsStoreError.itemNotFound(service: service, account: account)
        default:
            throw SecretsStoreError.status(status, operation: "delete")
        }
    }
}

/// Read/delete access to another application's Keychain item through
/// `/usr/bin/security`, which is what that application's access-control list
/// trusts.
///
/// Reads never put the secret in `argv` (`security ... -w` prints to stdout), so
/// this store is safe to use. **Writes are unsupported on purpose:** the CLI can
/// only accept a new secret as an argument, which would expose it to every
/// process of the same user. Rather than accept that exposure, callers must not
/// write to items they do not own.
public struct SecurityCLISecretsStore: SecretsStore {
    private let securityPath = "/usr/bin/security"
    private let itemNotFoundStatus: Int32 = 44

    public init() {}

    public func read(service: String, account: String) throws -> Data {
        let result: ProcessRunner.Result
        do {
            result = try ProcessRunner.run(
                executablePath: securityPath,
                arguments: ["find-generic-password", "-s", service, "-a", account, "-w"],
                timeout: 10
            )
        } catch {
            throw SecretsStoreError.status(errSecParam, operation: "launch")
        }
        if result.status == itemNotFoundStatus {
            throw SecretsStoreError.itemNotFound(service: service, account: account)
        }
        guard result.succeeded else {
            throw SecretsStoreError.status(Int32(result.status), operation: "read")
        }
        var data = Data(result.standardOutput.utf8)
        // `-w` appends a trailing newline that is not part of the secret.
        if data.last == UInt8(ascii: "\n") {
            data.removeLast()
        }
        return data
    }

    public func write(_ secret: Data, service: String, account: String) throws {
        throw SecretsStoreError.writeNotSupported(service: service)
    }

    public func delete(service: String, account: String) throws {
        let result: ProcessRunner.Result
        do {
            result = try ProcessRunner.run(
                executablePath: securityPath,
                arguments: ["delete-generic-password", "-s", service, "-a", account],
                timeout: 10
            )
        } catch {
            throw SecretsStoreError.status(errSecParam, operation: "launch")
        }
        if result.status == itemNotFoundStatus {
            throw SecretsStoreError.itemNotFound(service: service, account: account)
        }
        guard result.succeeded else {
            throw SecretsStoreError.status(Int32(result.status), operation: "delete")
        }
    }
}

/// In-memory store used by tests and by runs where persistence is unwanted.
public final class InMemorySecretsStore: SecretsStore, @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]

    public init() {}

    private func key(_ service: String, _ account: String) -> String { "\(service)|\(account)" }

    public func read(service: String, account: String) throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        guard let data = items[key(service, account)] else {
            throw SecretsStoreError.itemNotFound(service: service, account: account)
        }
        return data
    }

    public func write(_ secret: Data, service: String, account: String) throws {
        lock.lock()
        defer { lock.unlock() }
        items[key(service, account)] = secret
    }

    public func delete(service: String, account: String) throws {
        lock.lock()
        defer { lock.unlock() }
        guard items.removeValue(forKey: key(service, account)) != nil else {
            throw SecretsStoreError.itemNotFound(service: service, account: account)
        }
    }

    /// Test helper: does a secret exist for this service/account?
    public func contains(service: String, account: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return items[key(service, account)] != nil
    }
}

/// The store SplitBar uses for its own secrets.
public enum AppSecrets {
    public static var store: SecretsStore = SystemKeychainSecretsStore()
    public static var foreignItemStore: SecretsStore = SecurityCLISecretsStore()
}
