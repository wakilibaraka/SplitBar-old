import Testing

@testable import SplitBar
import CoreGraphics
import Foundation

/// Wave 4 (HYBRID_PLAN D1): `.maximize` reserves the taskbar band; other
/// tiling actions are untouched.
struct WindowTilingGeometryStrutTests {

    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let config = WindowTilingConfiguration(gap: 8, edgeMargin: 0)

    @Test func maximizeWithoutStrutIsUnchanged() {
        let frame = WindowTilingGeometry.calculateCocoaTargetFrame(
            action: .maximize,
            screenVisibleFrame: screen,
            configuration: config
        )
        #expect(frame == screen)
    }

    @Test func maximizeRespectsBottomStrut() {
        let frame = WindowTilingGeometry.calculateCocoaTargetFrame(
            action: .maximize,
            screenVisibleFrame: screen,
            configuration: config,
            bottomStrut: 40
        )
        // Cocoa y-up: the bottom edge rises by the strut, top/width unchanged.
        #expect(frame.minY == screen.minY + 40)
        #expect(frame.height == screen.height - 40)
        #expect(frame.maxY == screen.maxY)
        #expect(frame.minX == screen.minX)
        #expect(frame.width == screen.width)
    }

    @Test func otherTilingActionsIgnoreTheStrut() {
        for action: WindowTilingAction in [.leftHalf, .rightHalf, .topHalf, .bottomHalf, .almostMaximize] {
            let without = WindowTilingGeometry.calculateCocoaTargetFrame(
                action: action, screenVisibleFrame: screen, configuration: config
            )
            let withStrut = WindowTilingGeometry.calculateCocoaTargetFrame(
                action: action, screenVisibleFrame: screen, configuration: config, bottomStrut: 200
            )
            #expect(without == withStrut, "\(action) must not change with the strut")
        }
    }

    @Test func absurdStrutIsClampedToAUsableWindow() {
        let frame = WindowTilingGeometry.calculateCocoaTargetFrame(
            action: .maximize,
            screenVisibleFrame: screen,
            configuration: config,
            bottomStrut: 10_000
        )
        #expect(frame.height >= 100)
    }
}

/// Wave 4 (HYBRID_PLAN D2): zoom detection in AX global coords (top-left,
/// y down) — including the no-loop guarantee after an inset is applied.
struct ZoomAvoidanceTests {

    private let visibleAX = CGRect(x: 0, y: 25, width: 1440, height: 875)
    private let strut: CGFloat = 43

    @Test func exactZoomTriggersReinset() {
        #expect(ZoomAvoidance.shouldReinset(windowFrame: visibleAX, visibleAX: visibleAX, strut: strut))
    }

    @Test func subPixelJitterStillCountsAsZoom() {
        let jittered = CGRect(x: -2, y: 24, width: 1445, height: 878)
        #expect(ZoomAvoidance.shouldReinset(windowFrame: jittered, visibleAX: visibleAX, strut: strut))
    }

    @Test func smallerWindowDoesNotTrigger() {
        let half = CGRect(x: 0, y: 25, width: 720, height: 875)
        #expect(!ZoomAvoidance.shouldReinset(windowFrame: half, visibleAX: visibleAX, strut: strut))
    }

    @Test func disabledStrutNeverTriggers() {
        #expect(!ZoomAvoidance.shouldReinset(windowFrame: visibleAX, visibleAX: visibleAX, strut: 0))
    }

    @Test func insetRaisesOnlyTheBottomEdge() {
        let inset = ZoomAvoidance.insetFrame(visibleAX, strut: strut)
        #expect(inset.minX == visibleAX.minX)
        #expect(inset.minY == visibleAX.minY)
        #expect(inset.width == visibleAX.width)
        #expect(inset.maxY == visibleAX.maxY - strut)
    }

    @Test func appliedInsetStopsMatchingSoTheObserverCannotLoop() {
        let inset = ZoomAvoidance.insetFrame(visibleAX, strut: strut)
        #expect(!ZoomAvoidance.shouldReinset(windowFrame: inset, visibleAX: visibleAX, strut: strut))
    }

    @Test func cocoaVisibleFrameConvertsToAXGlobal() {
        // Cocoa (y-up): visible frame sits 25pt above the bottom of a
        // 900pt-tall primary display. AX (y-down): y = 900 - maxY = 25.
        let cocoa = CGRect(x: 0, y: 0, width: 1440, height: 875)
        let ax = ZoomAvoidance.visibleAX(fromCocoa: cocoa, primaryScreenHeight: 900)
        #expect(ax == CGRect(x: 0, y: 25, width: 1440, height: 875))
    }
}
