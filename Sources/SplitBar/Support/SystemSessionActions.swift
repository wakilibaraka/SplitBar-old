import Darwin
import Foundation

public enum SystemSessionActionError: Error, CustomStringConvertible {
    case lockFrameworkUnavailable(path: String, reason: String)
    case lockSymbolMissing(symbol: String)
    case lockFailed(status: Int32)
    case processLaunchFailed(executable: String, underlying: Error)
    case processExitedWithFailure(executable: String, arguments: [String], status: Int32)

    public var description: String {
        switch self {
        case .lockFrameworkUnavailable(let path, let reason):
            return "Cannot load lock framework at \(path): \(reason)"
        case .lockSymbolMissing(let symbol):
            return "Lock framework does not export \(symbol)"
        case .lockFailed(let status):
            return "SACLockScreenImmediate returned status \(status)"
        case .processLaunchFailed(let executable, let underlying):
            return "Failed to launch \(executable): \(underlying.localizedDescription)"
        case .processExitedWithFailure(let executable, let arguments, let status):
            return "\(executable) \(arguments.joined(separator: " ")) exited with status \(status)"
        }
    }
}

/// Ekranı anında kilitler. macOS 11+ sürümlerinde kaldırılan `CGSession -suspend` yerine
/// sistemin kendi Control+Command+Q kısayolunun kullandığı `login.framework` çağrısını kullanır.
public func lockScreenImmediately() throws {
    let frameworkPath = "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"
    guard let handle = dlopen(frameworkPath, RTLD_LAZY) else {
        let reason = dlerror().map { String(cString: $0) } ?? "unknown dlopen error"
        throw SystemSessionActionError.lockFrameworkUnavailable(path: frameworkPath, reason: reason)
    }
    defer { dlclose(handle) }

    let symbolName = "SACLockScreenImmediate"
    guard let symbol = dlsym(handle, symbolName) else {
        throw SystemSessionActionError.lockSymbolMissing(symbol: symbolName)
    }

    typealias LockScreenFunction = @convention(c) () -> Int32
    let lockScreen = unsafeBitCast(symbol, to: LockScreenFunction.self)
    let status = lockScreen()
    guard status == 0 else {
        throw SystemSessionActionError.lockFailed(status: status)
    }
}

/// Ekranları uykuya alır; `pmset` çıkış kodu başarısızsa hata fırlatır.
public func sleepDisplays() throws {
    let executable = "/usr/bin/pmset"
    let arguments = ["displaysleepnow"]
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    do {
        try process.run()
    } catch {
        throw SystemSessionActionError.processLaunchFailed(executable: executable, underlying: error)
    }
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw SystemSessionActionError.processExitedWithFailure(
            executable: executable,
            arguments: arguments,
            status: process.terminationStatus
        )
    }
}
