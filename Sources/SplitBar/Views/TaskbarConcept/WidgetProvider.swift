import SwiftUI

/// Explicit lifecycle states for dashboard widgets. Phase 2 data work swaps
/// providers behind these states instead of redesigning the cards.
enum WidgetState: Equatable {
    case placeholder
    case loading
    case loaded
    case permissionNeeded(PermissionKind)
    case error(String)
}

enum PermissionKind: String {
    case location
    case screenRecording
    case bluetooth
    case accessibility

    var title: String {
        switch self {
        case .location: "Location"
        case .screenRecording: "Screen Recording"
        case .bluetooth: "Bluetooth"
        case .accessibility: "Accessibility"
        }
    }
}

/// Small state chrome rendered inside a widget card for non-loaded states.
struct WidgetStateBanner: View {
    let state: WidgetState

    var body: some View {
        switch state {
        case .placeholder, .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading…")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
        case .loaded:
            EmptyView()
        case .permissionNeeded(let kind):
            Label("\(kind.title) needed for live data", systemImage: "lock.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        }
    }
}


enum DashboardWidget: String, CaseIterable, Identifiable {
    case weather
    case systemResources
    case nowPlaying
    case photos
    case stickyNotes
    case watchlist
    case date
    case systemRings
    case network

    var id: String { rawValue }

    var defaultSize: WidgetSizePreset {
        switch self {
        case .weather: .large
        case .systemResources: .medium
        case .date, .systemRings, .network: .small
        case .nowPlaying, .photos, .stickyNotes, .watchlist: .small
        }
    }
}


enum WidgetSizePreset: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case extraLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .extraLarge: "Extra large"
        }
    }

    var spansBoard: Bool {
        self == .large || self == .extraLarge
    }

    var cardContentHeight: CGFloat {
        switch self {
        case .small: 78
        case .medium: 126
        case .large: 162
        case .extraLarge: 210
        }
    }

    var weatherContentHeight: CGFloat {
        switch self {
        case .small: 220
        case .medium: 285
        case .large: 350
        case .extraLarge: 405
        }
    }

    var estimatedHeight: CGFloat {
        cardContentHeight + 56
    }
}


enum WidgetBoardSection: Identifiable {
    case columns(id: Int, leading: [DashboardWidget], trailing: [DashboardWidget])
    case fullWidth(id: Int, widget: DashboardWidget)

    var id: Int {
        switch self {
        case let .columns(id, _, _), let .fullWidth(id, _): id
        }
    }
}
