import Foundation
import OSLog
import ServiceManagement

@MainActor
public final class LaunchAtLoginService {
    public init() {}

    public var isEnabled: Bool {
        return SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enable: Bool) -> Result<Void, Error> {
        do {
            if enable {
                if SMAppService.mainApp.status == .enabled {
                    return .success(())
                }
                try SMAppService.mainApp.register()
                Logger.lifecycle.info("Successfully registered SplitBar for launch at login")
            } else {
                if SMAppService.mainApp.status != .enabled {
                    return .success(())
                }
                try SMAppService.mainApp.unregister()
                Logger.lifecycle.info("Successfully unregistered SplitBar from launch at login")
            }
            return .success(())
        } catch {
            Logger.lifecycle.error("Failed to update launch at login status: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
