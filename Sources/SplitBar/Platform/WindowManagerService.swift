import AppKit
import ApplicationServices
import Foundation
import OSLog

public final class WindowManagerService: @unchecked Sendable {
    public let configuration: WindowTilingConfiguration

    /// Receives the target screen's visible frame (Cocoa coords) and returns
    /// the bottom band that must stay clear — the taskbar strip's height over
    /// that screen, or 0 when the strip is elsewhere / avoidance is off
    /// (HYBRID_PLAN D1/D2). Set by the app layer; nil means no avoidance.
    public var bottomStrut: ((CGRect) -> CGFloat)?

    public init(configuration: WindowTilingConfiguration) {
        self.configuration = configuration
    }

    public func isAccessibilityGranted() -> Bool {
        return AXIsProcessTrusted()
    }

    public func promptAccessibilityPermission() {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: kCFBooleanTrue] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Focused window of the frontmost app, skipping SplitBar's own panels
    /// (shared lookup for the WindowTracking seam).
    private func frontmostFocusedWindowElement() -> AXUIElement? {
        guard AXIsProcessTrusted() else { return nil }
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return nil }
        if frontmostApp.bundleIdentifier == Bundle.main.bundleIdentifier { return nil }
        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        var focusedWindowValue: AnyObject?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindowValue
        ) == .success, let windowRef = focusedWindowValue else { return nil }
        return unsafeDowncast(windowRef, to: AXUIElement.self)
    }

    public func frontmostWindowFrame() -> CGRect? {
        guard let windowElement = frontmostFocusedWindowElement() else { return nil }
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        guard AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionRef = positionValue, let sizeRef = sizeValue
        else { return nil }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(unsafeDowncast(positionRef, to: AXValue.self), .cgPoint, &point),
              AXValueGetValue(unsafeDowncast(sizeRef, to: AXValue.self), .cgSize, &size)
        else { return nil }
        return CGRect(origin: point, size: size)
    }

    @discardableResult
    public func setFrontmostWindowFrame(_ frame: CGRect) -> Bool {
        guard let windowElement = frontmostFocusedWindowElement() else { return false }
        var origin = frame.origin
        var size = frame.size
        guard let positionAXValue = AXValueCreate(.cgPoint, &origin),
              let sizeAXValue = AXValueCreate(.cgSize, &size)
        else { return false }
        // Position → size → position: mirrors tileFrontmostWindow so size
        // constraints cannot drag the origin back.
        _ = AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, positionAXValue)
        _ = AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeAXValue)
        return AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, positionAXValue) == .success
    }

    @discardableResult
    public func raiseWindow(_ info: AppWindowInfo) -> Bool {
        guard AXIsProcessTrusted() else { return false }
        let appElement = AXUIElementCreateApplication(info.ownerPID)
        var windowsValue: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue) == .success,
              let windows = windowsValue as? [AXUIElement]
        else {
            return false
        }
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080.0
        for window in windows {
            var positionValue: AnyObject?
            var sizeValue: AnyObject?
            guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
                  AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
                  let positionRef = positionValue, let sizeRef = sizeValue
            else {
                continue
            }
            var position = CGPoint.zero
            var size = CGSize.zero
            guard AXValueGetValue(unsafeDowncast(positionRef, to: AXValue.self), .cgPoint, &position),
                  AXValueGetValue(unsafeDowncast(sizeRef, to: AXValue.self), .cgSize, &size)
            else {
                continue
            }
            let axFrame = CGRect(
                x: position.x,
                y: primaryHeight - position.y - size.height,
                width: size.width,
                height: size.height
            )
            guard abs(axFrame.minX - info.bounds.minX) < 3,
                  abs(axFrame.minY - info.bounds.minY) < 3,
                  abs(axFrame.width - info.bounds.width) < 3,
                  abs(axFrame.height - info.bounds.height) < 3
            else {
                continue
            }
            if AXUIElementPerformAction(window, kAXRaiseAction as CFString) == .success {
                return true
            }
        }
        return false
    }

    @discardableResult
    public func minimizeWindows(bundleIdentifier: String) -> Bool {
        guard AXIsProcessTrusted() else { return false }
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            return false
        }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowsValue: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue) == .success,
              let windows = windowsValue as? [AXUIElement], !windows.isEmpty
        else {
            return false
        }
        var minimizedAny = false
        for window in windows {
            if AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanTrue) == .success {
                minimizedAny = true
            }
        }
        if !minimizedAny {
            Logger.panels.warning("AX minimize affected no windows bundle=\(bundleIdentifier, privacy: .private)")
        }
        return minimizedAny
    }

    @discardableResult
    public func tileFrontmostWindow(action: WindowTilingAction) -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            Logger.panels.warning("No frontmost application found to tile")
            return false
        }

        // If SplitBar itself is frontmost, avoid resizing SplitBar panels
        if frontmostApp.bundleIdentifier == Bundle.main.bundleIdentifier {
            Logger.panels.info("Skipping tiling SplitBar itself")
            return false
        }

        let pid = frontmostApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var focusedWindowValue: AnyObject?
        let windowResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindowValue
        )

        guard windowResult == .success, let windowRef = focusedWindowValue else {
            Logger.panels.warning("Could not obtain focused window for application: \(frontmostApp.localizedName ?? "Unknown")")
            return false
        }

        let windowElement = unsafeDowncast(windowRef, to: AXUIElement.self)

        let primaryScreen = NSScreen.screens.first
        let primaryHeight = primaryScreen?.frame.height ?? 1080.0

        // Multi-monitor detection: Determine which screen currently hosts the target window
        var targetScreen: NSScreen = NSScreen.main ?? (primaryScreen ?? NSScreen())
        var currentPosVal: AnyObject?
        var currentSizeVal: AnyObject?
        if AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &currentPosVal) == .success,
           AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &currentSizeVal) == .success,
           let posVal = currentPosVal,
           let sizeVal = currentSizeVal {
            var pt = CGPoint.zero
            var sz = CGSize.zero
            if AXValueGetValue(unsafeDowncast(posVal, to: AXValue.self), .cgPoint, &pt),
               AXValueGetValue(unsafeDowncast(sizeVal, to: AXValue.self), .cgSize, &sz) {
                let midAX = CGPoint(x: pt.x + sz.width / 2.0, y: pt.y + sz.height / 2.0)
                let cocoaMidPoint = CGPoint(x: midAX.x, y: primaryHeight - midAX.y)
                if let matchedScreen = NSScreen.screens.first(where: { $0.frame.contains(cocoaMidPoint) }) {
                    targetScreen = matchedScreen
                }
            }
        }

        let screen = targetScreen
        let screenVisibleFrame = screen.visibleFrame

        let bottomStrutHeight = bottomStrut?(screenVisibleFrame) ?? 0
        let targetCocoaFrame = WindowTilingGeometry.calculateCocoaTargetFrame(
            action: action,
            screenVisibleFrame: screenVisibleFrame,
            configuration: configuration,
            bottomStrut: bottomStrutHeight
        )

        let targetAXFrame = WindowTilingGeometry.convertCocoaToAXFrame(
            cocoaRect: targetCocoaFrame,
            primaryScreenHeight: primaryHeight
        )

        var newOrigin = targetAXFrame.origin
        var newSize = targetAXFrame.size

        guard let posValue = AXValueCreate(.cgPoint, &newOrigin),
              let sizeValue = AXValueCreate(.cgSize, &newSize) else {
            Logger.panels.error("Failed to construct AXValue structures for position/size")
            return false
        }

        // Apply position first, then size, then position again (to counteract window constraints)
        _ = AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posValue)
        _ = AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeValue)
        let finalPosResult = AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posValue)

        if finalPosResult == .success {
            Logger.panels.info("Successfully tiled window to \(action.rawValue)")
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
            return true
        } else {
            Logger.panels.warning("Failed to tile window, AXError code: \(finalPosResult.rawValue)")
            return false
        }
    }
}

// MARK: - WindowTracking

extension WindowManagerService: WindowTracking {}
