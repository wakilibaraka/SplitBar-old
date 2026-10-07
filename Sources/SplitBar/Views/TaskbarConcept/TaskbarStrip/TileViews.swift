import AppKit
import SwiftUI

struct DownloadsTile: View {
    let tileSide: CGFloat
    let glyphSize: CGFloat

    private var downloadsURL: URL? {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    }

    var body: some View {
        Button {
            if let url = downloadsURL {
                NSWorkspace.shared.open(url)
            }
        } label: {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: glyphSize, weight: .medium))
                .foregroundStyle(.teal)
                .frame(width: tileSide, height: tileSide)
                .taskbarTile()
        }
        .buttonStyle(.plain)
        .help("Open Downloads")
        .disabled(downloadsURL == nil)
    }
}


struct SystemStatusIcon: View {
    let snapshot: SystemStatusSnapshot
    let glyphSize: CGFloat
    var preset = StatusIconPreset.batteryOnly
    var customSymbol = "battery.75percent"

    private var ringDiameter: CGFloat { glyphSize * 0.92 }

    private var batteryColor: Color {
        if snapshot.batteryLevel <= 15 { return .red }
        if snapshot.batteryLevel <= 30 { return .orange }
        return .green
    }

    var body: some View {
        Group {
            switch preset {
            case .batteryOnly:
                batteryRing
            case .batteryVolume:
                batteryRingWithVolumeArc(showNetworkDot: false)
            case .batteryVolumeNet:
                batteryRingWithVolumeArc(showNetworkDot: true)
            case .customSFSymbol:
                Image(systemName: customSymbol.isEmpty ? "battery.75percent" : customSymbol)
                    .font(.system(size: glyphSize * 0.72, weight: .medium))
                    .foregroundStyle(.primary)
            }
        }
        .accessibilityHidden(true)
    }

    private var batteryRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.18), lineWidth: max(2, glyphSize * 0.09))
                .frame(width: ringDiameter, height: ringDiameter)
            Circle()
                .trim(from: 0, to: CGFloat(snapshot.batteryLevel) / 100)
                .stroke(batteryColor, style: StrokeStyle(lineWidth: max(2, glyphSize * 0.09), lineCap: .round))
                .frame(width: ringDiameter, height: ringDiameter)
                .rotationEffect(.degrees(-90))
            if snapshot.isCharging {
                Image(systemName: "bolt.fill")
                    .font(.system(size: ringDiameter * 0.44, weight: .bold))
                    .foregroundStyle(.yellow)
            } else {
                Text("\(snapshot.batteryLevel)")
                    .font(.system(size: ringDiameter * 0.30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    private func batteryRingWithVolumeArc(showNetworkDot: Bool) -> some View {
        let outerDiameter = ringDiameter + max(4, glyphSize * 0.16)
        return ZStack(alignment: .bottomTrailing) {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: max(1.5, glyphSize * 0.055))
                .frame(width: outerDiameter, height: outerDiameter)
            Circle()
                .trim(from: 0, to: CGFloat(min(1, max(0, snapshot.isMuted ? 0 : snapshot.volumeLevel))))
                .stroke(.blue, style: StrokeStyle(lineWidth: max(1.5, glyphSize * 0.055), lineCap: .round))
                .frame(width: outerDiameter, height: outerDiameter)
                .rotationEffect(.degrees(-90))
            batteryRing
            if showNetworkDot {
                Circle()
                    .fill(snapshot.wifiOn ? Color.green : Color.secondary)
                    .frame(width: max(5, glyphSize * 0.18), height: max(5, glyphSize * 0.18))
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.85), lineWidth: 1)
                    }
                    .offset(x: 1, y: 1)
            }
        }
    }
}


struct TrashTile: View {
    let tileSide: CGFloat
    let glyphSize: CGFloat
    let darkMode: Bool
    @ObservedObject private var store = TrashStore.shared

    var body: some View {
        Button {
            store.openTrash()
        } label: {
            Image(systemName: store.isEmpty ? "trash" : "trash.fill")
                .font(.system(size: glyphSize, weight: .medium))
                .foregroundStyle(darkMode ? Color(red: 0.72, green: 0.78, blue: 0.88) : .secondary)
                .frame(width: tileSide, height: tileSide)
                .taskbarTile()
        }
        .buttonStyle(.plain)
        .help(store.isEmpty ? "Open Trash (empty)" : "Open Trash")
        .contextMenu {
            Button("Open Trash") { store.openTrash() }
            Button("Empty Trash") { store.emptyTrash() }
                .disabled(store.isEmpty)
        }
        .onAppear { store.refresh() }
    }
}


struct TaskbarDividerView: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.14))
            .frame(width: 1)
    }
}


struct TilePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: configuration.isPressed)
    }
}


struct AppTile<Icon: View, Indicator: View>: View {
    let title: String
    let icon: Icon
    let indicator: Indicator
    let onActivate: () -> Void
    let menu: AnyView
    let onHoverChanged: (Bool) -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: onActivate) {
            ZStack {
                icon
                VStack {
                    Spacer(minLength: 0)
                    indicator
                }
            }
            .offset(y: isHovering ? -2 : 0)
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: isHovering)
        }
        .buttonStyle(TilePressButtonStyle())
        .help(title)
        .contextMenu { menu }
        .onHover { hovering in
            isHovering = hovering
            onHoverChanged(hovering)
        }
    }
}


struct TaskbarTileStyle: ViewModifier {
    var highlighted = false
    var highlightFill = IndicatorFill.solid(.blue)
    @Environment(\.surfaceStyle) private var surfaceStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.iconBackground) private var iconBackground

    func body(content: Content) -> some View {
        Group {
            if iconBackground.isVisible {
                content
                    .background { tileBackground }
                    .contentShape(tileShape)
            } else {
                content
                    .contentShape(Rectangle())
            }
        }
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private var tileFill: AnyShapeStyle {
        if highlighted {
            return highlightFill.style(opacity: 0.22)
        }
        return AnyShapeStyle(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.10))
    }

    private var tileStroke: AnyShapeStyle {
        if highlighted {
            return highlightFill.style(opacity: 0.55)
        }
        return AnyShapeStyle(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.5))
    }

    private var tileBackground: some View {
        tileShape
            .fill(tileFill)
            .overlay {
                tileShape.stroke(tileStroke, lineWidth: 1)
            }
    }

    private var tileShape: AnyShape {
        switch iconBackground.shape {
        case .circle:
            AnyShape(Circle())
        case .roundedRect:
            AnyShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        case .roundedRectLarge:
            AnyShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}


extension View {
    func taskbarTile(highlighted: Bool = false, highlightFill: IndicatorFill = .solid(.blue)) -> some View {
        modifier(TaskbarTileStyle(highlighted: highlighted, highlightFill: highlightFill))
    }
}


struct MacOSAppIcon: View {
    let bundleIdentifier: String
    let fallbackSymbol: String
    let fallbackColor: Color
    let size: CGFloat
    @ObservedObject private var store = AppIconStore.shared
    @Environment(\.iconBackground) private var iconBackground

    private var fallbackClip: AnyShape {
        switch iconBackground.shape {
        case .circle:
            AnyShape(Circle())
        case .roundedRect:
            AnyShape(RoundedRectangle(cornerRadius: max(6, size * 0.24), style: .continuous))
        case .roundedRectLarge:
            AnyShape(RoundedRectangle(cornerRadius: max(8, size * 0.36), style: .continuous))
        }
    }

    var body: some View {
        Group {
            if let icon = store.icons[bundleIdentifier] {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    Image(systemName: fallbackSymbol)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(fallbackColor)
                        .padding(size * 0.14)
                }
                .clipShape(fallbackClip)
                .task(id: bundleIdentifier) {
                    _ = store.icon(for: bundleIdentifier)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
