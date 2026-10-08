import AppKit
import Foundation

/// Owns the set of displays that host SplitBar panels and reacts to display
/// configuration changes. Phase 1 targets the primary display only; enabling
/// more screens later is a policy change in `panelScreens()`, not a rewrite of
/// every panel controller.
@MainActor
public final class DisplayCoordinator {
    private let screenService = ScreenService()
    private var screenObserver: NSObjectProtocol?

    /// Called on the main actor whenever the screen set may have changed.
    public var onScreensChanged: (() -> Void)?

    public init() {}

    /// Screens that host SplitBar panels. Primary-only for now.
    public func panelScreens() -> [ScreenGeometry] {
        screenService.primaryScreen().map { [$0] } ?? []
    }

    public func primaryScreen() -> ScreenGeometry? {
        panelScreens().first
    }

    public func panelScreenWidth(fallback: CGFloat = 1440) -> CGFloat {
        primaryScreen()?.visibleFrame.width ?? fallback
    }

    public func startObserving() {
        guard screenObserver == nil else { return }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.onScreensChanged?()
            }
        }
    }

    public func stopObserving() {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
    }
}
