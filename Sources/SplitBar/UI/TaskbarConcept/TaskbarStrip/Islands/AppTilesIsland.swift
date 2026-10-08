import SwiftUI

// MARK: - AppTilesIsland
//
// Pinned + running app tiles, dividers, and the overflow chevron. Extracted
// from TaskbarStripViews.swift in the Phase-1 island split (HYBRID_PLAN A1);
// the strip composition / visibility / focus logic moved here with it.

struct AppTilesIsland: View {
    @ObservedObject var model: TaskbarConceptState
    let tiles: TaskbarTiles
    var maxAppTiles: Int? = nil
    var showOverflowChevron: Bool = false
    @FocusState private var focusedTile: String?

    private var focusableAppIDs: [String] {
        visibleItems.compactMap {
            if case .app(let bundleID) = $0 { bundleID } else { nil }
        }
    }

    private var stripItems: [StripItem] {
        let running = model.runningAppOrder.filter({ !model.pinnedAppBundleIDs.contains($0) })
        let dividers = model.taskbarMode == .macOS ? [] : model.userDividers
        return TaskbarStrip.compose(
            pins: model.pinnedAppBundleIDs,
            runningOrder: running,
            dividers: dividers
        )
    }

    private var visibleItems: [StripItem] {
        guard let maxAppTiles else { return stripItems }
        var appsSeen = 0
        var result: [StripItem] = []
        for item in stripItems {
            if case .app = item {
                appsSeen += 1
                if appsSeen > maxAppTiles {
                    continue
                }
            }
            result.append(item)
        }
        return TaskbarStrip.pruned(result)
    }

    private var isClipped: Bool {
        guard maxAppTiles != nil else { return false }
        return visibleItems.count < stripItems.count
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(visibleItems, id: \.self) { item in
                switch item {
                case .app(let bundleID):
                    tiles.taskbarAppTile(bundleID)
                        .focused($focusedTile, equals: bundleID)
                case .divider(let id):
                    TaskbarDividerView()
                        .padding(.vertical, 6)
                        .contextMenu {
                            Button("Remove divider", role: .destructive) {
                                model.removeDivider(id)
                            }
                        }
                }
            }

            if showOverflowChevron, isClipped {
                Button {
                    model.openPanel = .start
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: max(28, model.taskbarHeight - 4))
                }
                .buttonStyle(.plain)
                .help("More apps in the launcher")
            }
        }
        .onMoveCommand { direction in
            let ids = focusableAppIDs
            guard !ids.isEmpty else { return }
            switch direction {
            case .left, .up:
                if let current = focusedTile, let index = ids.firstIndex(of: current) {
                    focusedTile = ids[max(index - 1, 0)]
                } else {
                    focusedTile = ids.last
                }
            case .right, .down:
                if let current = focusedTile, let index = ids.firstIndex(of: current) {
                    focusedTile = ids[min(index + 1, ids.count - 1)]
                } else {
                    focusedTile = ids.first
                }
            @unknown default:
                break
            }
        }
    }
}
