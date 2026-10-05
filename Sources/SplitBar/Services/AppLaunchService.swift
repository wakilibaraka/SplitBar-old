import AppKit
import Foundation

@MainActor
public final class AppLaunchService {
    public init() {
    }

    public func launch(target: LaunchTarget) async -> LaunchResult {
        switch target {
        case .application(_, let url):
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            return await withCheckedContinuation { continuation in
                NSWorkspace.shared.openApplication(at: url, configuration: config) { application, error in
                    if let error {
                        continuation.resume(returning: .systemFailure(error.localizedDescription))
                    } else if application != nil {
                        continuation.resume(returning: .launched)
                    } else {
                        continuation.resume(returning: .systemFailure("The system did not return the launched application."))
                    }
                }
            }

        case .link(let url):
            if NSWorkspace.shared.open(url) {
                return .launched
            } else {
                return .systemFailure("Failed to open URL: \(url.absoluteString)")
            }
        }
    }
}
