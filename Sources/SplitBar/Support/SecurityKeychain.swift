import Foundation

/// Keychain erişimi `/usr/bin/security` üzerinden yapılır. Claude Code kendi kimlik bilgisini bu araçla
/// yazdığı için öğeye izin penceresi çıkmadan erişilebilir; ayrıca imzasız geliştirme derlemeleri her
/// yeniden derlemede Keychain izni istemez.
public enum SecurityKeychainError: Error, CustomStringConvertible {
    case itemNotFound(service: String, account: String?)
    case commandFailed(operation: String, service: String, status: Int32, stderr: String)
    case launchFailed(operation: String, underlying: Error)
    case invalidAttribute(operation: String, reason: String)

    public var description: String {
        switch self {
        case .itemNotFound(let service, let account):
            return "Keychain item not found service=\(service) account=\(account ?? "*")"
        case .commandFailed(let operation, let service, let status, let stderr):
            return "security \(operation) failed service=\(service) status=\(status): \(stderr)"
        case .launchFailed(let operation, let underlying):
            return "Could not launch /usr/bin/security for \(operation): \(underlying.localizedDescription)"
        case .invalidAttribute(let operation, let reason):
            return "security \(operation) rejected attribute: \(reason)"
        }
    }
}

private struct SecurityCommandOutput {
    let status: Int32
    let stdout: Data
    let stderr: String
}

/// Arka plan okumasının sonucunu taşır; `DispatchGroup.wait()` ile senkronize edildiği için yarış yoktur.
private final class StderrBox: @unchecked Sendable {
    var data = Data()
}

/// `security` aracının "öğe bulunamadı" çıkış kodu.
private let securityItemNotFoundStatus: Int32 = 44

private func runSecurityCommand(operation: String, arguments: [String], stdin: Data?) throws -> SecurityCommandOutput {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
    process.arguments = arguments
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    let stdinPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    process.standardInput = stdinPipe
    do {
        try process.run()
    } catch {
        throw SecurityKeychainError.launchFailed(operation: operation, underlying: error)
    }
    if let stdin {
        stdinPipe.fileHandleForWriting.write(stdin)
    }
    do {
        try stdinPipe.fileHandleForWriting.close()
    } catch {
        throw SecurityKeychainError.launchFailed(operation: operation, underlying: error)
    }
    // İki boru eşzamanlı boşaltılır; biri dolarsa süreç ve çağıran karşılıklı beklemede kilitlenmez
    let stderrCollector = DispatchGroup()
    let stderrBox = StderrBox()
    stderrCollector.enter()
    DispatchQueue.global(qos: .utility).async {
        stderrBox.data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        stderrCollector.leave()
    }
    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    stderrCollector.wait()
    let stderrData = stderrBox.data
    process.waitUntilExit()
    return SecurityCommandOutput(
        status: process.terminationStatus,
        stdout: stdoutData,
        stderr: redactedSecrets(String(decoding: stderrData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
    )
}

/// `security` hata çıktısı kimlik bilgisi verisini yankılayabilir; hatalar loglanmadan önce uzun
/// onaltılık/base64 dizileri maskelenir.
private func redactedSecrets(_ text: String) -> String {
    text.replacingOccurrences(
        of: "[A-Za-z0-9+/=_-]{24,}",
        with: "<redacted>",
        options: .regularExpression
    )
}

private func requireSuccess(_ output: SecurityCommandOutput, operation: String, service: String, account: String?) throws {
    if output.status == securityItemNotFoundStatus {
        throw SecurityKeychainError.itemNotFound(service: service, account: account)
    }
    guard output.status == 0 else {
        throw SecurityKeychainError.commandFailed(operation: operation, service: service, status: output.status, stderr: output.stderr)
    }
}

/// Genel parola öğesinin değerini okur. `account` nil ise servisteki ilk öğe okunur.
public func readKeychainPassword(service: String, account: String?) throws -> Data {
    let operation = "find-generic-password"
    var arguments = [operation, "-s", service]
    if let account {
        arguments += ["-a", account]
    }
    arguments.append("-w")
    let output = try runSecurityCommand(operation: operation, arguments: arguments, stdin: nil)
    try requireSuccess(output, operation: operation, service: service, account: account)
    // `-w` çıktısının sonuna eklenen tek satır sonu parolaya ait değildir
    var data = output.stdout
    if data.last == UInt8(ascii: "\n") {
        data.removeLast()
    }
    return data
}

/// Öğeyi oluşturur veya günceller. Değer, Claude Code'un kendi yazımıyla aynı biçimde `-X` ile onaltılık
/// argüman olarak aktarılır: `security -i` girdisi uzun satırları böldüğü için kimlik bilgileri orada bozulur.
/// Argümanlar kısa ömürlü süreç boyunca yalnızca aynı kullanıcının süreçlerince görülebilir; bu öğelerin
/// erişim listesi `/usr/bin/security`'ye güvendiği için aynı kullanıcının süreçleri değeri zaten
/// `security find-generic-password -w` ile okuyabilir, yani ek bir erişim yüzeyi oluşmaz.
public func writeKeychainPassword(service: String, account: String, password: Data) throws {
    let operation = "add-generic-password"
    let hex = password.map { String(format: "%02x", $0) }.joined()
    let output = try runSecurityCommand(
        operation: operation,
        arguments: [operation, "-U", "-a", account, "-s", service, "-X", hex],
        stdin: nil
    )
    try requireSuccess(output, operation: operation, service: service, account: account)
}

public func deleteKeychainPassword(service: String, account: String) throws {
    let operation = "delete-generic-password"
    let output = try runSecurityCommand(
        operation: operation,
        arguments: [operation, "-s", service, "-a", account],
        stdin: nil
    )
    try requireSuccess(output, operation: operation, service: service, account: account)
}
