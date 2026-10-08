import AppKit
import ApplicationServices
import Foundation
import OSLog

// MARK: - ZoomAvoidanceObserver
//
// HYBRID_PLAN D2: watches the frontmost app's windows and re-insets any
// window that a maximize (green button / ⌘-zoom / external "Maximize")
// lays across the taskbar strip.
//
// Lifecycle rules:
//   - `attach(to:)` runs on app *activation*, never at launch.
//   - Without the Accessibility permission it stays silently dormant; the
//     prompt fires only when the user turns the toggle on (lazy, first use).
//   - After an inset the window no longer matches the visible frame, so
//     `ZoomAvoidance.shouldReinset` returns false — no re-inset loop.
@MainActor
final class ZoomAvoidanceObserver {
    /// Owner supplies current context: `nil` means "do not act" (toggle off,
    /// strip hidden, strip's screen changed). Frames are AX global coords.
    var context: (() -> (visibleAX: CGRect, strut: CGFloat)?)?
    /// Applies the inset through `WindowTracking.setFrontmostWindowFrame`.
    var applyInset: ((CGRect) -> Bool)?

    private var observer: AXObserver?
    private var observedPID: pid_t = 0

    /// Attach to an app (idempotent per pid; detaches any previous app).
    func attach(to pid: pid_t) {
        guard pid != observedPID else { return }
        detach()
        guard let currentContext = context?(), currentContext.strut > 0 else { return }
        guard AXIsProcessTrusted() else { return }

        var created: AXObserver?
        let createResult = AXObserverCreate(pid, { _, element, notification, refcon in
            guard let refcon else { return }
            let zoom = Unmanaged<ZoomAvoidanceObserver>.fromOpaque(refcon).takeUnretainedValue()
            let name = notification as String
            Task { @MainActor in
                zoom.handle(notification: name, element: element)
            }
        }, &created)
        guard createResult == .success, let created else {
            Logger.panels.warning("ZoomAvoidance: AXObserverCreate failed code=\(createResult.rawValue)")
            return
        }

        observer = created
        observedPID = pid
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(created), .commonModes)

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        let appElement = AXUIElementCreateApplication(pid)
        // App-level: learn about newly created windows.
        AXObserverAddNotification(created, appElement, kAXWindowCreatedNotification as CFString, refcon)
        // Existing windows.
        var windowsValue: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue) == .success,
           let windows = windowsValue as? [AXUIElement] {
            for window in windows { observe(window: window, observer: created, refcon: refcon) }
        }
    }

    func detach() {
        if let observer {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        }
        observer = nil
        observedPID = 0
    }

    private func observe(window: AXUIElement, observer: AXObserver, refcon: UnsafeMutableRawPointer) {
        AXObserverAddNotification(observer, window, kAXWindowResizedNotification as CFString, refcon)
        AXObserverAddNotification(observer, window, kAXWindowMovedNotification as CFString, refcon)
    }

    private func handle(notification: String, element: AXUIElement) {
        guard let observer else { return }
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        if notification == kAXWindowCreatedNotification as String {
            observe(window: element, observer: observer, refcon: refcon)
            evaluate(window: element)
            return
        }
        guard notification == kAXWindowResizedNotification as String
            || notification == kAXWindowMovedNotification as String
        else { return }
        evaluate(window: element)
    }

    private func evaluate(window: AXUIElement) {
        guard let currentContext = context?(), currentContext.strut > 0 else { return }
        guard let frame = Self.frame(of: window) else { return }
        guard ZoomAvoidance.shouldReinset(
            windowFrame: frame,
            visibleAX: currentContext.visibleAX,
            strut: currentContext.strut
        ) else { return }
        let inset = ZoomAvoidance.insetFrame(frame, strut: currentContext.strut)
        _ = applyInset?(inset)
        Logger.panels.info(
            "ZoomAvoidance: re-inset maximized window above the taskbar strut height=\(currentContext.strut)"
        )
    }

    /// Reads the window's frame in AX global coordinates (top-left, y down).
    static func frame(of window: AXUIElement) -> CGRect? {
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionRef = positionValue, let sizeRef = sizeValue
        else { return nil }
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(unsafeDowncast(positionRef, to: AXValue.self), .cgPoint, &point),
              AXValueGetValue(unsafeDowncast(sizeRef, to: AXValue.self), .cgSize, &size)
        else { return nil }
        return CGRect(origin: point, size: size)
    }
}
