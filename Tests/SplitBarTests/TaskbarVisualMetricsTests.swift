import CoreGraphics
import Testing

@testable import SplitBar

struct TaskbarVisualMetricsTests {
    @Test func tileSideFitsTheBar() {
        #expect(LayoutTokens.tileSide(for: 46) == 42)
        #expect(LayoutTokens.tileSide(for: 32) == 28)
        for height in stride(from: CGFloat(32), through: CGFloat(56), by: 2) {
            #expect(LayoutTokens.tileSide(for: height) < height)
        }
    }

    @Test func glyphFitsInsideTheTile() {
        for height in stride(from: CGFloat(32), through: CGFloat(56), by: 2) {
            let side = LayoutTokens.tileSide(for: height)
            for size in TaskbarIconSize.allCases {
                let glyph = LayoutTokens.glyphSize(barHeight: height, iconSize: size)
                #expect(glyph > 0)
                #expect(glyph < side)
            }
        }
    }

    @Test func indicatorWidthsGrowWithState() {
        for style in [RunningIndicatorStyle.dot, .dash] {
            #expect(TaskbarIndicatorMetrics.height(for: style) == 3)
            for size in RunningIndicatorSize.allCases {
                let running = TaskbarIndicatorMetrics.width(for: style, size: size, state: .running)
                let multiple = TaskbarIndicatorMetrics.width(for: style, size: size, state: .multipleWindows)
                let frontmost = TaskbarIndicatorMetrics.width(for: style, size: size, state: .frontmost)
                #expect(running < multiple)
                #expect(multiple < frontmost)
            }
        }
    }

    @Test func highlightStyleHasNoCapsule() {
        #expect(TaskbarIndicatorMetrics.height(for: .highlight) == 0)
        #expect(TaskbarIndicatorMetrics.width(for: .highlight, size: .medium, state: .frontmost) == 0)
    }
}
