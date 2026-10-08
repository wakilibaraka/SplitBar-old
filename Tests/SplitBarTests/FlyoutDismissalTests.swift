import Testing

@testable import SplitBar
import CoreGraphics
import Foundation

/// Wave 3 (HYBRID_PLAN C2): one shared dismissal rule for every flyout
/// monitor — outside clicks close, clicks on the flyout or the strip (which
/// owns its own toggles) do not.
struct FlyoutDismissalTests {

    private let flyout = CGRect(x: 100, y: 100, width: 400, height: 300)
    private let strip = CGRect(x: 0, y: 0, width: 1440, height: 40)

    @Test func clickOutsideDismisses() {
        let farAway = CGPoint(x: 1300, y: 700)
        #expect(FlyoutDismissal.shouldDismiss(location: farAway, protected: [flyout, strip]))
    }

    @Test func clickInsideFlyoutKeepsItOpen() {
        let inside = CGPoint(x: 300, y: 250)
        #expect(!FlyoutDismissal.shouldDismiss(location: inside, protected: [flyout, strip]))
    }

    @Test func clickOnStripKeepsFlyoutOpen() {
        // Strip buttons toggle panels themselves — the monitor must not race them.
        let onStrip = CGPoint(x: 720, y: 20)
        #expect(!FlyoutDismissal.shouldDismiss(location: onStrip, protected: [flyout, strip]))
    }

    @Test func edgeTouchingClicksMatchExactly() {
        // CGRect.contains is half-open: maxX/maxY edges count as outside.
        let topLeft = CGPoint(x: flyout.minX, y: flyout.minY)
        #expect(!FlyoutDismissal.shouldDismiss(location: topLeft, protected: [flyout]))
        let justOutside = CGPoint(x: flyout.minX - 1, y: flyout.minY)
        #expect(FlyoutDismissal.shouldDismiss(location: justOutside, protected: [flyout]))
    }

    @Test func hiddenFlyoutFrameIsNotProtected() {
        let frames = FlyoutDismissal.protectedFrames(
            flyoutFrame: flyout,
            flyoutVisible: false,
            stripFrame: strip
        )
        #expect(frames == [strip])
    }

    @Test func visibleFlyoutAndStripAreBothProtected() {
        let frames = FlyoutDismissal.protectedFrames(
            flyoutFrame: flyout,
            flyoutVisible: true,
            stripFrame: strip
        )
        #expect(frames == [flyout, strip])
        // A nil strip (panel not yet laid out) must not protect a zero rect —
        // a .zero rect would swallow clicks at the screen origin.
        let noStrip = FlyoutDismissal.protectedFrames(
            flyoutFrame: flyout,
            flyoutVisible: true,
            stripFrame: nil
        )
        #expect(noStrip == [flyout])
        let zeroStrip = FlyoutDismissal.protectedFrames(
            flyoutFrame: flyout,
            flyoutVisible: true,
            stripFrame: .zero
        )
        #expect(zeroStrip == [flyout])
    }
}
