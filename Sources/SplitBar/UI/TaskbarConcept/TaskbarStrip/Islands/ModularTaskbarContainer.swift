import SwiftUI

// MARK: - ModularTaskbarContainer
//
// Routes the bar's three layout modes (HYBRID_PLAN A2):
//
//   .docked   — edge-to-edge strip, one surface shell (windows / centered)
//   .floating — unified floating shell, islands separated by padding (macOS)
//   .split    — self-sizing islands in an HStack, one .taskbarSurface each
//
// The split path replaces the old `TaskbarSplitRow`, which positioned every
// island with hand-computed CGRects and `.offset(x: frame.minX, ...)`; the
// islands now size themselves and only the *capacity* math (how many app
// tiles fit, whether the overflow chevron shows) still consults
// `TaskbarStripMetrics`. Per-island panel *positions* for the live bar are
// AppKit geometry and stay with the panel request path.

struct ModularTaskbarContainer: View {
    enum Layout: Equatable {
        case docked
        case floating
        case split
    }

    @ObservedObject var model: TaskbarConceptState
    let height: CGFloat
    let onLaunchApplication: (String) -> Void
    let onTaskbarIconClick: (String) -> Void
    let onTaskbarTileAction: (TaskbarTileAction) -> Void
    var rendersSplitRow: Bool = true

    private var mode: TaskbarMode { model.taskbarMode }

    /// Pure mode → layout routing (unit-tested in ModularLayoutTests).
    static func layout(for mode: TaskbarMode) -> Layout {
        switch mode {
        case .split3, .split4: return .split
        case .macOS: return .floating
        case .windows, .centered: return .docked
        }
    }

    var layout: Layout { Self.layout(for: mode) }

    // MARK: Body

    var body: some View {
        switch layout {
        case .split:
            if rendersSplitRow {
                splitIslands
            } else {
                // Live bar: per-island panels are created by the panel host.
                Color.clear
            }
        case .docked, .floating:
            barShell
        }
    }

    // MARK: Split — self-sizing islands

    private var splitIslands: some View {
        let appCount = model.pinnedAppBundleIDs.count
            + model.runningAppOrder.filter { !model.pinnedAppBundleIDs.contains($0) }.count
        return GeometryReader { geometry in
            // Capacity only — no frames, no offsets.
            let capacity = TaskbarStripMetrics.layout(
                screenWidth: geometry.size.width,
                mode: mode,
                barHeight: model.taskbarHeight,
                gap: model.islandGap,
                appCount: appCount
            )
            HStack(alignment: .center, spacing: model.islandGap) {
                ForEach(
                    Array(TaskbarSection.islands(for: mode).enumerated()),
                    id: \.offset
                ) { _, sections in
                    islandShell(
                        sections: sections,
                        maxAppTiles: capacity.visibleAppTiles,
                        showsOverflow: capacity.showsOverflow
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func islandShell(
        sections: [TaskbarSection],
        maxAppTiles: Int,
        showsOverflow: Bool
    ) -> some View {
        let radius = model.shellRadius(for: .taskbar)
        return TaskbarIslandContent(
            sections: sections,
            model: model,
            onLaunchApplication: onLaunchApplication,
            onTaskbarIconClick: onTaskbarIconClick,
            onTaskbarTileAction: onTaskbarTileAction,
            maxAppTiles: maxAppTiles,
            showOverflowChevron: showsOverflow
        )
        .padding(.horizontal, LayoutTokens.islandInnerPadding)
        .frame(height: model.taskbarHeight)
        .taskbarSurface(
            style: model.surfaceStyle,
            darkMode: model.isDarkMode,
            transparency: model.interfaceTransparency,
            cornerRadius: radius
        )
    }

    // MARK: Docked / floating — one shell (moved verbatim from `Taskbar`)

    private var glyphSize: CGFloat { height * model.taskbarIconSize.glyphFraction }
    private var tileSide: CGFloat { max(28, height - 4) }
    private var isFloating: Bool { mode == .macOS }
    private var isConstrained: Bool { isFloating || mode == .centered }
    private var showsDividers: Bool { !isFloating }
    private var appTileCount: Int {
        model.pinnedAppBundleIDs.count + model.runningAppOrder.filter { !model.pinnedAppBundleIDs.contains($0) }.count
    }

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
            tileSide: tileSide,
            glyphSize: glyphSize,
            previewsEnabled: model.showWindowPreviews,
            previewBundleID: $model.previewBundleID,
            clusterOrder: model.clusterOrder,
            dividers: model.userDividers,
            onTaskbarIconClick: onTaskbarIconClick,
            onTaskbarTileAction: onTaskbarTileAction,
            onToggleControls: { toggle(.controls) },
            onHoverChanged: model.handleTaskbarTileHover,
            onMovePinned: model.movePinned,
            reduceMotion: model.reduceMotion
        )
    }

    private var barShell: some View {
        GeometryReader { geometry in
            ZStack {
                barBackground
                HStack(spacing: 0) {
                    WidgetIsland(model: model)
                        .padding(.leading, LayoutTokens.barOuterPadding)
                    if showsDividers, !model.userDividers.isEmpty {
                        TaskbarDividerView()
                            .padding(.vertical, 6)
                            .padding(.leading, LayoutTokens.dividerGutter)
                    }
                    Spacer(minLength: 0)
                    trailingTrayCluster
                        .layoutPriority(1)
                }
                .padding(.horizontal, isFloating ? LayoutTokens.barOuterPadding : LayoutTokens.dockedBarPadding)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .frame(width: isConstrained ? (mode == .centered ? TaskbarStripMetrics.centeredFrameWidth(userWidth: model.centeredBarWidth, barHeight: height, appCount: appTileCount, availableWidth: geometry.size.width) : min(geometry.size.width, model.centeredBarWidth)) : nil)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .center) {
                TaskbarIslandContent(
                    sections: [.apps],
                    model: model,
                    onLaunchApplication: onLaunchApplication,
                    onTaskbarIconClick: onTaskbarIconClick,
                    onTaskbarTileAction: onTaskbarTileAction
                )
            }
        }
    }

    @ViewBuilder
    private var barBackground: some View {
        let radius = model.shellRadius(for: .taskbar)
        if isFloating {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
                }
                .padding(.vertical, 3)
        } else if model.usesTaskbarGradient {
            Rectangle()
                .fill(LinearGradient(colors: [model.taskbarGradientStart, model.taskbarGradientEnd], startPoint: .leading, endPoint: .trailing))
        } else if model.surfaceStyle == .windowsAero {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    LinearGradient(
                        colors: [
                            Color(red: 0.44, green: 0.74, blue: 0.96).opacity(model.isDarkMode ? 0.22 : 0.45),
                            Color.white.opacity(model.isDarkMode ? 0.03 : 0.16),
                            Color(red: 0.18, green: 0.43, blue: 0.71).opacity(model.isDarkMode ? 0.18 : 0.30)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        } else {
            let fill: AnyShapeStyle = {
                switch model.surfaceStyle {
                case .windowsXP:
                    return AnyShapeStyle(LinearGradient(
                        colors: [Color(red: 0.15, green: 0.44, blue: 0.88), Color(red: 0.04, green: 0.22, blue: 0.61)],
                        startPoint: .top, endPoint: .bottom
                    ))
                case .aqua:
                    return AnyShapeStyle(LinearGradient(
                        colors: [Color(red: 0.30, green: 0.65, blue: 0.96), Color(red: 0.10, green: 0.40, blue: 0.88)],
                        startPoint: .top, endPoint: .bottom
                    ))
                case .frutigerAero:
                    return AnyShapeStyle(LinearGradient(
                        colors: [Color(red: 0.42, green: 0.78, blue: 0.96), Color(red: 0.18, green: 0.62, blue: 0.82)],
                        startPoint: .top, endPoint: .bottom
                    ))
                case .y2k:
                    return AnyShapeStyle(LinearGradient(
                        colors: [Color(red: 0.72, green: 0.82, blue: 1.0), Color(red: 0.44, green: 0.60, blue: 0.96)],
                        startPoint: .top, endPoint: .bottom
                    ))
                default:
                    return AnyShapeStyle(model.surfaceStyle.taskbarFill(darkMode: model.isDarkMode))
                }
            }()
            Rectangle()
                .fill(fill)
                .overlay(alignment: .top) {
                    if model.surfaceStyle == .neobrutalism {
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: 3)
                    } else {
                        Rectangle()
                            .fill(Color.white.opacity(0.42))
                            .frame(height: 1)
                    }
                }
        }
    }

    private var trailingTrayCluster: some View {
        HStack(spacing: model.trashPlacement(for: mode) == .beforeClock ? 4 : 8) {
            if model.trashPlacement(for: mode) == .beforeTray {
                tiles.trashCluster
            }
            if model.trashPlacement(for: mode) == .beforeClock {
                tiles.trashCluster
            }
            ClockIsland(model: model)
            if model.trashPlacement(for: mode) == .farRight {
                tiles.trashCluster
            }
        }
        .padding(.trailing, LayoutTokens.trailingTrayPadding)
    }

    private func toggle(_ panel: OpenPanel) {
        model.openPanel = model.openPanel == panel ? nil : panel
    }
}
