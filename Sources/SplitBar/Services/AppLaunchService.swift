import AppKit
import Foundation

@MainActor
public final class AppLaunchService {
    public init() {
    }

    public func launch(target: LaunchTarget) -> LaunchResult {
        switch target {
        case .application(_, let url):
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            nonisolated(unsafe) var launchError: Error?
            let semaphore = DispatchSemaphore(value: 0)

            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
                launchError = error
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 2.0)

            if let error = launchError {
                return .systemFailure(error.localizedDescription)
            }
            return .launched

        case .link(let url):
            if NSWorkspace.shared.open(url) {
                return .launched
            } else {
                return .systemFailure("Failed to open URL: \(url.absoluteString)")
            }
        }
    }
}
