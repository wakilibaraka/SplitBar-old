import Testing

@testable import SplitBar
import Foundation

struct ProcessRunnerTests {
    @Test func runsAndCapturesOutput() throws {
        let result = try ProcessRunner.run(executablePath: "/bin/echo", arguments: ["hello"])
        #expect(result.succeeded)
        #expect(result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines) == "hello")
        #expect(!result.timedOut)
    }

    @Test func nonZeroExitIsReported() throws {
        let result = try ProcessRunner.run(executablePath: "/bin/sh", arguments: ["-c", "exit 3"])
        #expect(result.status == 3)
        #expect(!result.succeeded)
    }

    @Test func timeoutTerminatesChild() throws {
        let start = Date()
        let result = try ProcessRunner.run(executablePath: "/bin/sleep", arguments: ["30"], timeout: 0.5)
        let elapsed = Date().timeIntervalSince(start)
        #expect(result.timedOut)
        #expect(!result.succeeded)
        // Must not have waited for the full 30 seconds.
        #expect(elapsed < 5)
    }

    @Test func outputIsCapped() throws {
        // 100k of 'x' should be truncated at the requested cap.
        let result = try ProcessRunner.run(
            executablePath: "/bin/sh",
            arguments: ["-c", "printf 'x%.0s' {1..100000}"],
            maximumOutputBytes: 4096
        )
        #expect(result.outputTruncated)
        #expect(result.standardOutput.count <= 4096)
    }

    @Test func missingExecutableThrows() {
        #expect(throws: ProcessRunner.Failure.executableMissing("/definitely/not/here")) {
            try ProcessRunner.run(executablePath: "/definitely/not/here")
        }
    }

    @Test func cappingHelperTrimsAndFlags() {
        let data = Data(repeating: 0x61, count: 10_000)
        let (text, truncated) = ProcessRunner.capped(data, cap: 100)
        #expect(truncated)
        #expect(text.count == 100)
        let small = Data(repeating: 0x62, count: 10)
        let (text2, truncated2) = ProcessRunner.capped(small, cap: 100)
        #expect(!truncated2)
        #expect(text2.count == 10)
    }

    @Test func standardInputIsAccepted() throws {
        let result = try ProcessRunner.run(
            executablePath: "/bin/cat",
            timeout: 10,
            standardInput: Data("piped".utf8)
        )
        #expect(result.standardOutput == "piped")
    }
}
