import SwiftUI

// MARK: - StatusTrayIsland
//
// Downloads / trash / system-status cluster (quick controls). Extracted from
// TaskbarStripViews.swift in the Phase-1 island split (HYBRID_PLAN A1).

struct StatusTrayIsland: View {
    let tiles: TaskbarTiles

    var body: some View {
        tiles.trashCluster
    }
}
