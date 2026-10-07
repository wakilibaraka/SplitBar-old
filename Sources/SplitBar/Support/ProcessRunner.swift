import Foundation

/// Single entry point for launching child processes.
///
/// Guarantees for every call site:
/// - an absolute executable path (never resolved through `PATH`)
/// - an argument array (no shell, no string interpolation into a command line)
/// - a hard timeout, so a wedged helper cannot hang a UI thread
/// - an output size cap, so a runaway process cannot exhaust memory
///
/// Secrets must never be passed in `arguments`; use `standardInput` instead.
public enum ProcessRunner {
    public struct Result: Equatable, Sendable {
        public let status: Int32
        public let standardOutput: String
        public let standardError: String
        public let timedOut: Bool
        public let outputTruncated: Bool

        public var succeeded: Bool { status == 0 && !timedOut }
    }

    public enum Failure: LocalizedError, Equatable, Sendable {
        case executableMissing(String)
        case launchFailed(String, underlying: String)
        case timedOut(TimeInterval)

        public var errorDescription: String? {
            switch self {
            case .executableMissing(let path): "Executable not found: \(path)"
            case .launchFailed(let path, let underlying): "Failed to launch \(path): \(underlying)"
            case .timedOut(let seconds): "Process timed out after \(seconds)s"
            }
        }
    }

    /// Runs `executablePath` and waits up to `timeout` seconds.
    ///
    /// - Parameters:
    ///   - standardInput: optional bytes written to the child's stdin, then closed.
    ///     This is the only safe channel for secrets.
    ///   - maximumOutputBytes: cap on captured stdout/stderr each.
    public static func run(
        executablePath: String,
        arguments: [String] = [],
        timeout: TimeInterval = 10,
        maximumOutputBytes: Int = 256 * 1024,
        standardInput: Data? = nil,
        environment: [String: String]? = nil
    ) throws -> Result {
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            throw Failure.executableMissing(executablePath)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        if let environment {
            process.environment = environment
        }

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        let inPipe = Pipe()
        if standardInput != nil {
            process.standardInput = inPipe
        }

        do {
            try process.run()
        } catch {
            throw Failure.launchFailed(executablePath, underlying: error.localizedDescription)
        }

        if let standardInput {
            inPipe.fileHandleForWriting.write(standardInput)
            try? inPipe.fileHandleForWriting.close()
        }

        // Drain both pipes concurrently so neither can fill its buffer and
        // deadlock the child while we wait.
        let collector = OutputCollector(cap: maximumOutputBytes)
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.baraka.splitbar.processrunner", attributes: .concurrent)

        queue.async(group: group) {
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            collector.appendStandardOutput(data)
        }
        queue.async(group: group) {
            let data = errPipe.fileHandleForReading.readDataToEndOfFile()
            collector.appendStandardError(data)
        }

        let deadline = DispatchTime.now() + timeout
        let timedOut = DispatchQueue(label: "com.baraka.splitbar.processrunner.wait")
            .sync { () -> Bool in
                while process.isRunning {
                    if DispatchTime.now() >= deadline {
                        process.terminate()
                        // Give it a moment to die before returning.
                        Thread.sleep(forTimeInterval: 0.1)
                        if process.isRunning {
                            kill(process.processIdentifier, SIGKILL)
                        }
                        return true
                    }
                    Thread.sleep(forTimeInterval: 0.02)
                }
                return false
            }

        _ = group.wait(timeout: .now() + 1.0)

        let status: Int32 = process.isRunning ? -1 : process.terminationStatus
        let output = collector.result()
        return Result(
            status: status,
            standardOutput: output.standardOutput,
            standardError: output.standardError,
            timedOut: timedOut,
            outputTruncated: output.truncated
        )
    }

    /// Runs without waiting; for fire-and-forget helpers such as `killall Dock`.
    public static func launch(executablePath: String, arguments: [String] = []) throws {
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            throw Failure.executableMissing(executablePath)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        try process.run()
    }

    /// Test seam: trims a captured buffer to `cap` bytes.
    static func capped(_ data: Data, cap: Int) -> (String, Bool) {
        if data.count <= cap {
            return (String(decoding: data, as: UTF8.self), false)
        }
        return (String(decoding: data.prefix(cap), as: UTF8.self), true)
    }
}

/// Thread-safe accumulator for the two output streams.
private final class OutputCollector: @unchecked Sendable {
    private let cap: Int
    private let lock = NSLock()
    private var out = Data()
    private var err = Data()
    private var truncated = false

    init(cap: Int) {
        self.cap = max(1024, cap)
    }

    func appendStandardOutput(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        appendLocked(data, to: &out)
    }

    func appendStandardError(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        appendLocked(data, to: &err)
    }

    private func appendLocked(_ data: Data, to buffer: inout Data) {
        let remaining = cap - buffer.count
        guard remaining > 0 else {
            if !data.isEmpty { truncated = true }
            return
        }
        if data.count > remaining {
            buffer.append(data.prefix(remaining))
            truncated = true
        } else {
            buffer.append(data)
        }
    }

    func result() -> (standardOutput: String, standardError: String, truncated: Bool) {
        lock.lock()
        defer { lock.unlock() }
        return (String(decoding: out, as: UTF8.self), String(decoding: err, as: UTF8.self), truncated)
    }
}
