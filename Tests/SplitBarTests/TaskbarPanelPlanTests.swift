import Foundation
import Testing

@testable import SplitBar

struct TaskbarPanelPlanTests {
    /// A strip layout is replaced when the user switches to islands: the strip
    /// panel must be removed, the islands created. This is the exact bug where
    /// panels survived the switch and ghosted the old layout on screen.
    @Test func stripToIslandsCreatesIslandsAndRemovesStrip() {
        let plan = PanelPlan.transition(wanted: ["d#0", "d#1", "d#2"], existing: ["d#strip"])
        #expect(plan.create == ["d#0", "d#1", "d#2"])
        #expect(plan.update.isEmpty)
        #expect(plan.remove == ["d#strip"])
    }

    /// Switching back from islands to the strip must tear down every island.
    @Test func islandsToStripRemoveIslandsAndCreatesStrip() {
        let plan = PanelPlan.transition(wanted: ["d#strip"], existing: ["d#0", "d#1"])
        #expect(plan.create == ["d#strip"])
        #expect(plan.update.isEmpty)
        #expect(plan.remove == ["d#0", "d#1"])
    }

    /// When a display leaves, its panels go with it.
    @Test func displayRemovalRemovesAllItsPanels() {
        let plan = PanelPlan.transition(wanted: [], existing: ["d#0", "e#strip"])
        #expect(plan.create.isEmpty)
        #expect(plan.update.isEmpty)
        #expect(plan.remove == ["d#0", "e#strip"])
    }

    /// Redrawing the same layout asks for no change: panels may be updated, never
    /// removed.
    @Test func sameLayoutRequestsUpdateOnly() {
        let plan = PanelPlan.transition(wanted: ["d#strip"], existing: ["d#strip"])
        #expect(plan.create.isEmpty)
        #expect(plan.remove.isEmpty)
        #expect(plan.update == ["d#strip"])
    }

    /// Every wanted key is accounted for exactly once across the three buckets.
    @Test func bucketsAreDisjoint() {
        let plan = PanelPlan.transition(wanted: ["d#strip", "e#0"], existing: ["d#strip", "e#1"])
        #expect(plan.create == ["e#0"])
        #expect(plan.remove == ["e#1"])
        #expect(plan.update == ["d#strip"])
    }
}
