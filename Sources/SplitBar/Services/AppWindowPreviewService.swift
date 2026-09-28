import AppKit
import CoreGraphics
import Foundation
import OSLog
import ScreenCaptureKit

public final class AppWindowPreviewService: @unchecked Sendable {
    public init() {}

    public func windows(forBundleIdentifier bundleIdentifier: String, appName: String) -> [AppWindowInfo] {
        guard let windowInfoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }

        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        let targetPIDs = Set(runningApps.map { $0.processIdentifier })

        var result: [AppWindowInfo] = []

        for dict in windowInfoList {
            guard let windowNumber = dict[kCGWindowNumber as String] as? CGWindowID,
                  let ownerPID = dict[kCGWindowOwnerPID as String] as? pid_t,
                  let ownerName = dict[kCGWindowOwnerName as String] as? String,
                  let layer = dict[kCGWindowLayer as String] as? Int,
                  layer == 0 else {
                continue
            }

            let matchesPID = !targetPIDs.isEmpty && targetPIDs.contains(ownerPID)
            let matchesName = ownerName.caseInsensitiveCompare(appName) == .orderedSame

            guard matchesPID || matchesName else {
                continue
            }

            guard let boundsDict = dict[kCGWindowBounds as String] as? [String: Any],
                  let width = boundsDict["Width"] as? CGFloat,
                  let height = boundsDict["Height"] as? CGFloat,
                  let x = boundsDict["X"] as? CGFloat,
                  let y = boundsDict["Y"] as? CGFloat,
                  width > 80.0, height > 80.0 else {
                continue
            }

            let title = (dict[kCGWindowName as String] as? String) ?? appName
            let bounds = CGRect(x: x, y: y, width: width, height: height)

            let info = AppWindowInfo(
                id: windowNumber,
                title: title.isEmpty ? appName : title,
                bounds: bounds,
                ownerPID: ownerPID,
                ownerName: ownerName
            )
            result.append(info)
        }

        return result
    }

    public func captureThumbnail(forWindowID windowID: CGWindowID) async -> NSImage? {
        do {
            let content = try await SCShareableContent.current
            guard let window = content.windows.first(where: { $0.windowID == windowID }) else {
                return nil
            }
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let config = SCStreamConfiguration()
            config.width = 320
            config.height = 200
            config.showsCursor = false
            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            return NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
        } catch {
            return nil
        }
    }

    public func focusWindow(info: AppWindowInfo, bundleIdentifier: String) {
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            app.activate()
        } else if let appByPID = NSRunningApplication(processIdentifier: info.ownerPID) {
            appByPID.activate()
        }
    }
}
