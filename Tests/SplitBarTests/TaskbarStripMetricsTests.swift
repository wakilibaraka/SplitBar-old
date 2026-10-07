import Foundation
import Testing

@testable import SplitBar

struct TaskbarStripMetricsTests {
    @Test func centeredBarFitsItsContent() {
        let barHeight: CGFloat = 46
        let stride = TaskbarStripMetrics.tileStride(barHeight: barHeight)
        for appCount in [5, 12, 19] {
            let width = TaskbarStripMetrics.centeredFrameWidth(userWidth: 720, barHeight: barHeight, appCount: appCount, availableWidth: 1710)
            let need: CGFloat = (196 + 18) + CGFloat(appCount) * stride + 16 + (stride * 2 + 96) + 32
            #expect(width >= need, "with \(appCount) apps the bar must be at least the content width")
            #expect(width <= 1710, "the bar is clipped to the screen")
        }
    }

    @Test func centeredBarNeverShrinksBelowUserChoice() {
        let width = TaskbarStripMetrics.centeredFrameWidth(userWidth: 1100, barHeight: 46, appCount: 3, availableWidth: 1710)
        #expect(width == 1100)
    }
}
