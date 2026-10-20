import SwiftUI

// MARK: - TaskbarIslandContent
//
// Thin section dispatcher for the five islands (HYBRID_PLAN A1). The island
// implementations live in TaskbarStrip/Islands/; this type only routes
// sections and builds the shared TaskbarTiles factory.

struct TaskbarIslandContent: View {
    let sections: [TaskbarSection]
    @ObservedObject var model: TaskbarConceptState
    let onLaunchApplication: (String) -> Void
    let onTaskbarIconClick: (String) -> Void
    let onTaskbarTileAction: (TaskbarTileAction) -> Void
    var maxAppTiles: Int? = nil
    var showOverflowChevron: Bool = false

    private var tiles: TaskbarTiles {
        TaskbarTiles(
            pinnedBundleIDs: model.pinnedAppBundleIDs,
            runningBundleIDs: model.runningBundleIDs,
            frontmostBundleID: model.frontmostBundleID,
            indicatorStyle: model.runningIndicatorStyle,
            indicatorSize: model.runningIndicatorSize,
            indicatorFill: model.resolvedIndicatorFill,
            menuStyle: model.contextMenuStyle,
            isDarkMode: model.isDarkMode,
            systemStatus: model.systemStatus,
            statusIconPreset: model.statusIconPreset,
            statusIconCustomSymbol: model.statusIconCustomSymbol,
            tileSide: LayoutTokens.tileSide(for: model.taskbarHeight),
            glyphSize: LayoutTokens.glyphSize(barHeight: model.taskbarHeight, iconSize: model.taskbarIconSize),
            previewsEnabled: model.showWindowPreviews,
            previewBundleID: $model.previewBundleID,
            clusterOrder: model.clusterOrder,
            dividers: model.userDividers,
            onTaskbarIconClick: onTaskbarIconClick,
            onTaskbarTileAction: onTaskbarTileAction,
            onToggleControls: { model.openPanel = model.openPanel == .controls ? nil : .controls },
            onHoverChanged: model.handleTaskbarTileHover,
            onMovePinned: model.movePinned,
            reduceMotion: model.reduceMotion
        )
    }

    var body: some View {
        HStack(spacing: LayoutTokens.tileGap) {
            ForEach(sections, id: \.self) { section in
                switch section {
                case .weather:
                    WidgetIsland(model: model)
                case .apps:
                    HStack(spacing: LayoutTokens.tileGap) {
                        StartIsland(model: model)
                        AppTilesIsland(
                            model: model,
                            tiles: tiles,
                            maxAppTiles: maxAppTiles,
                            showOverflowChevron: showOverflowChevron
                        )
                    }
                case .tray:
                    StatusTrayIsland(tiles: tiles)
                case .clock:
                    ClockIsland(model: model, tiles: tiles)
                }
            }
        }
    }
}


struct Taskbar: View {
    @ObservedObject var model: TaskbarConceptState
    @Binding var height: CGFloat
    let onLaunchApplication: (String) -> Void
    let onTaskbarIconClick: (String) -> Void
    let onTaskbarTileAction: (TaskbarTileAction) -> Void
    var rendersSplitRow: Bool = true

    private var isFloating: Bool { model.taskbarMode == .macOS }

    var body: some View {
        ModularTaskbarContainer(
            model: model,
            height: height,
            onLaunchApplication: onLaunchApplication,
            onTaskbarIconClick: onTaskbarIconClick,
            onTaskbarTileAction: onTaskbarTileAction,
            rendersSplitRow: rendersSplitRow
        )
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .environment(\.surfaceTransparency, model.interfaceTransparency)
        .overlay(alignment: .top) {
            if !isFloating, model.surfaceStyle == .classic98 {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(height: 1)
                    .offset(y: -1)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                model.openPanel = .settings
            } label: {
                Label("Customise taskbar", systemImage: "slider.horizontal.3")
            }

            Toggle("Maximize keeps taskbar visible", isOn: $model.maximizeAvoidsTaskbar)

            Divider()

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label("Quit Taskbar", systemImage: "power")
            }
        }
    }

}
