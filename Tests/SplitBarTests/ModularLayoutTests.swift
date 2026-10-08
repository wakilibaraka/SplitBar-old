import Testing

@testable import SplitBar
import CoreGraphics
import Foundation

/// Wave 1 (HYBRID_PLAN A4): the mode matrix — routing, island composition,
/// and the spacing tokens every mode derives its rhythm from.
struct ModularLayoutTests {

    @Test func modeRouting() {
        #expect(ModularTaskbarContainer.layout(for: .windows) == .docked)
        #expect(ModularTaskbarContainer.layout(for: .centered) == .docked)
        #expect(ModularTaskbarContainer.layout(for: .macOS) == .floating)
        #expect(ModularTaskbarContainer.layout(for: .split3) == .split)
        #expect(ModularTaskbarContainer.layout(for: .split4) == .split)
    }

    @Test func islandCompositionPerMode() {
        #expect(TaskbarSection.islands(for: .windows) == [[.weather, .apps, .tray, .clock]])
        #expect(TaskbarSection.islands(for: .macOS) == [[.weather, .apps, .tray, .clock]])
        #expect(TaskbarSection.islands(for: .centered) == [[.weather, .apps, .tray, .clock]])
        #expect(TaskbarSection.islands(for: .split3) == [[.weather], [.apps], [.tray, .clock]])
        #expect(TaskbarSection.islands(for: .split4) == [[.weather], [.apps], [.tray], [.clock]])
    }

    /// The five-island vocabulary: Widget(.weather) + Start/AppTiles(.apps,
    /// rendered as two islands inside the section) + StatusTray(.tray) +
    /// Clock(.clock). Every section must exist so the dispatcher can route it.
    @Test func everySectionIsRoutable() {
        let all: Set<TaskbarSection> = [.weather, .apps, .tray, .clock]
        for mode: TaskbarMode in [.windows, .macOS, .centered, .split3, .split4] {
            let routed = TaskbarSection.islands(for: mode).flatMap { $0 }
            #expect(Set(routed) == all, "mode \(mode) must route every island section")
        }
    }

    @Test func splitIslandCounts() {
        #expect(TaskbarSection.islands(for: .split3).count == 3)
        #expect(TaskbarSection.islands(for: .split4).count == 4)
    }

    /// A3: paddings snap to half-beats of the 8pt grid and are all positive.
    @Test func layoutTokensSnapToGrid() {
        #expect(LayoutTokens.grid == 8)
        let paddings = [
            LayoutTokens.islandInnerPadding,
            LayoutTokens.barOuterPadding,
            LayoutTokens.dockedBarPadding,
            LayoutTokens.trailingTrayPadding,
            LayoutTokens.dividerGutter,
        ]
        for value in paddings {
            #expect(value > 0)
            #expect(value.truncatingRemainder(dividingBy: 4) == 0)
        }
        #expect(LayoutTokens.islandInnerPadding <= LayoutTokens.barOuterPadding)
    }
}
