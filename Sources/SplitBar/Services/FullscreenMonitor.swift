import AppKit
import Foundation

@MainActor
public final class FullscreenMonitor {
    private let screenService = ScreenService()

    public init() {}

    public func isFullscreen(displayIdentifier: String) -> Bool {
        guard let screen = screenService.screen(withIdentifier: displayIdentifier) else {
            return false
        }
        return hasFullscreenWindow(on: screen)
    }

    public func fullscreenDisplayIdentifiers() -> Set<String> {
        Set(
            screenService.screens()
                .filter { hasFullscreenWindow(on: $0) }
                .map(\.identifier)
        )
    }

    nonisolated private func hasFullscreenWindow(on screen: ScreenGeometry) -> Bool {
        guard let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return false
        }
        let myPID = ProcessInfo.processInfo.processIdentifier
        for window in windows {
            guard let boundsDict = window[kCGWindowBounds as String] as? [String: Any],
                  let layer = window[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID != myPID,
                  let x = boundsDict["X"] as? CGFloat,
                  let y = boundsDict["Y"] as? CGFloat,
                  let width = boundsDict["Width"] as? CGFloat,
                  let height = boundsDict["Height"] as? CGFloat
            else {
                continue
            }
            let bounds = CGRect(x: x, y: y, width: width, height: height)
            let frame = screen.frame
            if abs(bounds.minX - frame.minX) < 2,
               abs(bounds.minY - frame.minY) < 2,
               abs(bounds.width - frame.width) < 2,
               abs(bounds.height - frame.height) < 2 {
                return true
            }
        }
        return false
    }
}
