import Testing

@testable import SplitBar

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
}
