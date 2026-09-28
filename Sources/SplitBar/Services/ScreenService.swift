import AppKit
import Foundation

public final class ScreenService: @unchecked Sendable {
    public init() {
    }

    public func screens() -> [ScreenGeometry] {
        return NSScreen.screens.map { screen in
            let id: String
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                id = String(screenNumber)
            } else {
                id = screen.localizedName
            }
            return ScreenGeometry(
                identifier: id,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame
            )
        }
    }

    public func primaryScreen() -> ScreenGeometry? {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return nil
        }
        let id: String
        if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
            id = String(screenNumber)
        } else {
            id = screen.localizedName
        }
        return ScreenGeometry(
            identifier: id,
            frame: screen.frame,
            visibleFrame: screen.visibleFrame
        )
    }

    public func screenContainingCursor() -> ScreenGeometry? {
        let mouseLocation = NSEvent.mouseLocation
        let matched = NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main ?? NSScreen.screens.first

        guard let screen = matched else { return nil }
        let id: String
        if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
            id = String(screenNumber)
        } else {
            id = screen.localizedName
        }
        return ScreenGeometry(
            identifier: id,
            frame: screen.frame,
            visibleFrame: screen.visibleFrame
        )
    }

    public func screen(withIdentifier identifier: String) -> ScreenGeometry? {
        return screens().first { $0.identifier == identifier }
    }
}
