import AppKit
import CoreGraphics
import Foundation

public struct DockItemViewState: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let kind: DockItemKind
    public let isSelected: Bool
    public let isRunning: Bool
    public let badgeText: String?
    public let transform: DockItemVisualTransform

    public init(
        id: UUID,
        name: String,
        kind: DockItemKind,
        isSelected: Bool,
        isRunning: Bool,
        badgeText: String?,
        transform: DockItemVisualTransform
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.isSelected = isSelected
        self.isRunning = isRunning
        self.badgeText = badgeText
        self.transform = transform
    }
}

public struct DockViewState: Equatable, Sendable {
    public let items: [DockItemViewState]
    public let edge: DockEdge
    public let isRevealed: Bool
    public let selectedItemID: UUID?

    public init(
        items: [DockItemViewState],
        edge: DockEdge,
        isRevealed: Bool,
        selectedItemID: UUID?
    ) {
        self.items = items
        self.edge = edge
        self.isRevealed = isRevealed
        self.selectedItemID = selectedItemID
    }
}

public func makeDockViewState(
    state: AppState,
    pointer: CGPoint?,
    itemFrames: [DockItemGeometry],
    configuration: DockMagnificationConfiguration,
    weatherState: WeatherState?,
    aiUsageState: AIUsageState?,
    systemMetrics: SystemMetrics?,
    nowPlayingState: NowPlayingState?
) -> DockViewState {
    let transforms = magnificationTransforms(
        items: itemFrames,
        pointer: pointer,
        configuration: configuration
    )

    var itemViews: [DockItemViewState] = []
    for item in state.dockItems {
        let isSelected = (state.selectedItemID == item.id)
        let transform = transforms[item.id] ?? DockItemVisualTransform(
            scale: 1.0,
            translationY: 0.0,
            logicalFrame: itemFrames.first(where: { $0.id == item.id })?.logicalFrame ?? .zero
        )

        var isRunning = false
        var badgeText: String? = nil
        switch item.kind {
        case .application(let bundleID, _):
            isRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
        case .widget(let wid):
            if wid == "weather" {
                badgeText = weatherState?.formattedTemperature ?? "—°"
            } else if wid == "ai_usage" {
                if let ai = aiUsageState {
                    isRunning = ai.hasRunningAgent
                    // Gerçek plan limiti biliniyorsa en az kalan 5 saatlik kota gösterilir
                    if let percent = ai.lowestFiveHourRemainingPercent(now: Date()) {
                        badgeText = "\(Int(percent.rounded()))%"
                    } else {
                        badgeText = ai.hasRunningAgent ? "LIVE" : "AI"
                    }
                } else {
                    badgeText = "AI"
                }
            } else if wid == "system_monitor" {
                if let metrics = systemMetrics {
                    badgeText = "\(Int(round(metrics.cpu.usagePercent)))%"
                } else {
                    badgeText = "CPU"
                }
            } else if wid == "now_playing" {
                if let np = nowPlayingState, np.isPlaying {
                    isRunning = true
                    badgeText = "PLAY"
                } else {
                    isRunning = false
                    badgeText = "Music"
                }
            } else if wid == "bluetooth" {
                badgeText = "BT"
            } else if wid == "quick_notes" {
                badgeText = "Note"
            } else if wid == "clipboard" {
                badgeText = "Clip"
            }
        case .link:
            break
        }

        itemViews.append(
            DockItemViewState(
                id: item.id,
                name: item.name,
                kind: item.kind,
                isSelected: isSelected,
                isRunning: isRunning,
                badgeText: badgeText,
                transform: transform
            )
        )
    }

    return DockViewState(
        items: itemViews,
        edge: state.placement.edge,
        isRevealed: state.isDockRevealed,
        selectedItemID: state.selectedItemID
    )
}
