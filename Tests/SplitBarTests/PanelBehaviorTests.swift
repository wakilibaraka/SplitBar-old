import Testing

@testable import SplitBar
import AppKit
import Foundation

/// Wave 3 (HYBRID_PLAN C1): the strip and edge panels must share the same
/// Spaces/full-screen persistence flags — a missing `.fullScreenAuxiliary`
/// made the strip vanish over full-screen apps while edge panels stayed.
struct PanelBehaviorTests {

    @Test func stripAndEdgePanelsShareCollectionBehavior() {
        #expect(taskbarStripCollectionBehavior() == edgePanelCollectionBehavior())
    }

    @Test func shellPanelsPersistAcrossSpacesAndFullScreen() {
        let behavior = taskbarStripCollectionBehavior()
        #expect(behavior.contains(.canJoinAllSpaces))
        #expect(behavior.contains(.fullScreenAuxiliary))
        #expect(behavior.contains(.stationary))
        #expect(behavior.contains(.ignoresCycle))
    }
}
