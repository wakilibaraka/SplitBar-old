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
