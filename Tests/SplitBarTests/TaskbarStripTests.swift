import Testing

@testable import SplitBar
import CoreGraphics

struct TaskbarStripTests {
    @Test func pinsBeforeRunning() {
        let items = TaskbarStrip.compose(
            pins: ["com.apple.Safari"],
            runningOrder: ["com.apple.Music", "com.apple.Safari"],
            dividers: []
        )
        #expect(items == [.app("com.apple.Safari"), .app("com.apple.Music")])
    }

    @Test func dividerSitsAfterItsAnchor() {
        let divider = TaskbarDivider(anchorBundleID: "a")
        let items = TaskbarStrip.compose(
            pins: ["a", "b"],
            runningOrder: [],
            dividers: [divider]
        )
        #expect(items == [.app("a"), .divider(divider.id), .app("b")])
    }

    @Test func leadingTrailingAndDoubledDividersArePruned() {
        let first = TaskbarDivider(anchorBundleID: nil)
        let second = TaskbarDivider(anchorBundleID: nil)
        let items = TaskbarStrip.pruned([.divider(first.id), .app("a"), .divider(first.id), .divider(second.id), .app("b"), .divider(second.id)])
        #expect(items == [.app("a"), .divider(first.id), .app("b")])
    }

    @Test func unmatchedAnchorsSurviveInStore() {
        let divider = TaskbarDivider(anchorBundleID: "missing.app")
        let items = TaskbarStrip.compose(pins: ["a"], runningOrder: [], dividers: [divider])
        #expect(!items.contains(.divider(divider.id)))
    }

    @Test func splitModesExposeExpectedIslands() {
        #expect(TaskbarSection.islands(for: .windows).count == 1)
        #expect(TaskbarSection.islands(for: .split3).count == 3)
        #expect(TaskbarSection.islands(for: .split4).count == 4)
        #expect(TaskbarSection.islands(for: .split4).flatMap { $0 }.count == 4)
    }

    @Test func everySectionLivesInSomeIsland() {
        for mode in TaskbarMode.allCases {
            let covered = Set(TaskbarSection.islands(for: mode).flatMap { $0 })
            #expect(covered == Set(TaskbarSection.allCases))
        }
    }

    private func split3Layout(appCount: Int, screenWidth: CGFloat = 1728) -> TaskbarStrip.IslandLayout {
        TaskbarStrip.layoutIslands(
            screenWidth: screenWidth,
            mode: .split3,
            tileStride: 46,
            appCount: appCount,
            weatherWidth: 200,
            trayWidth: 150,
            clockWidth: 100,
            clusterWidth: 140,
            gap: 10,
            margin: 12,
            barHeight: 46,
            bottomMargin: 8
        )
    }

    @Test func splitIslandsStayInsideTheScreen() {
        let layout = split3Layout(appCount: 9)
        #expect(layout.islands.count == 3)
        #expect(!layout.showsOverflow)
        #expect(layout.visibleAppTiles == 9)
        for island in layout.islands {
            #expect(island.frame.minX >= 0)
            #expect(island.frame.maxX <= 1728)
            #expect(island.frame.minY == 8)
        }
        let ordered = layout.islands.sorted { $0.frame.minX < $1.frame.minX }
        #expect(ordered[0].sections == [.weather])
        #expect(ordered[1].sections == [.apps])
        #expect(ordered[2].sections == [.tray, .clock])
    }

    @Test func crowdedAppsShrinkWithOverflowFlag() {
        let layout = split3Layout(appCount: 40, screenWidth: 1200)
        #expect(layout.showsOverflow)
        #expect(layout.visibleAppTiles < 40)
        #expect(layout.visibleAppTiles >= 1)
        for island in layout.islands {
            #expect(island.frame.maxX <= 1200)
        }
    }

    @Test func statusIconPresetCases() {
        #expect(StatusIconPreset.allCases.count == 4)
        #expect(StatusIconPreset.batteryOnly.rawValue == "batteryOnly")
    }

    @Test func iconSizePresetsScaleUp() {
        #expect(TaskbarIconSize.allCases.count == 5)
        let fractions = TaskbarIconSize.allCases.map(\.glyphFraction)
        #expect(fractions == [0.42, 0.50, 0.60, 0.72, 0.84])
        #expect(TaskbarIconSize.allCases.map(\.title) == ["XS", "S", "M", "L", "XL"])
    }

    @Test func iconShapeCases() {
        #expect(IconShape.allCases.count == 3)
    }

    @Test func singleIslandModesProduceNoIslands() {
        let layout = TaskbarStrip.layoutIslands(
            screenWidth: 1728,
            mode: .windows,
            tileStride: 46,
            appCount: 9,
            weatherWidth: 200,
            trayWidth: 150,
            clockWidth: 100,
            clusterWidth: 140,
            gap: 10,
            margin: 12,
            barHeight: 46,
            bottomMargin: 8
        )
        #expect(layout.islands.isEmpty)
        #expect(!layout.showsOverflow)
    }
}
