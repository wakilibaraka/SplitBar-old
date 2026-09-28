import AppKit
import Foundation
import SwiftUI

public struct DynamicWaveformBarView: View {
    public let isPlaying: Bool
    public let index: Int
    public let barCount: Int

    @State private var phase: Double = 0.0

    public init(
        isPlaying: Bool,
        index: Int,
        barCount: Int
    ) {
        self.isPlaying = isPlaying
        self.index = index
        self.barCount = barCount
    }

    public var body: some View {
        let normalized = Double(index) / Double(max(1, barCount - 1))
        let targetHeight: CGFloat = isPlaying
            ? CGFloat(8.0 + 26.0 * abs(sin(phase + normalized * .pi * 2.0)))
            : 5.0

        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        SplitBarPalette.violet,
                        SplitBarPalette.cyan
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 3.5, height: max(5.0, targetHeight))
            .shadow(color: isPlaying ? SplitBarPalette.violet.opacity(0.35) : Color.clear, radius: 2.5, x: 0.0, y: 1.0)
            .onAppear {
                if isPlaying {
                    withAnimation(
                        .easeInOut(duration: 0.35 + Double(index % 4) * 0.08)
                        .repeatForever(autoreverses: true)
                    ) {
                        phase = 2.5
                    }
                }
            }
            .onChange(of: isPlaying) { _, playing in
                if playing {
                    withAnimation(
                        .easeInOut(duration: 0.35 + Double(index % 4) * 0.08)
                        .repeatForever(autoreverses: true)
                    ) {
                        phase = 2.5
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        phase = 0.0
                    }
                }
            }
    }
}

public struct NowPlayingFlyoutView: View {
    public let state: NowPlayingState
    public let onTogglePlayPause: () -> Void
    public let onNextTrack: () -> Void
    public let onPreviousTrack: () -> Void
    public let onSeek: (Double) -> Void
    public let onRefresh: () -> Void

    @State private var isDraggingScrubber: Bool = false
    @State private var dragFraction: Double = 0.0

    public init(
        state: NowPlayingState,
        onTogglePlayPause: @escaping () -> Void,
        onNextTrack: @escaping () -> Void,
        onPreviousTrack: @escaping () -> Void,
        onSeek: @escaping (Double) -> Void,
        onRefresh: @escaping () -> Void
    ) {
        self.state = state
        self.onTogglePlayPause = onTogglePlayPause
        self.onNextTrack = onNextTrack
        self.onPreviousTrack = onPreviousTrack
        self.onSeek = onSeek
        self.onRefresh = onRefresh
    }

    public var body: some View {
        VStack(spacing: 16.0) {
            // Header / Source Badge
            HStack {
                HStack(spacing: 6.0) {
                    Circle()
                        .fill(state.isPlaying ? Color.green : Color.secondary)
                        .frame(width: 8.0, height: 8.0)
                        .shadow(color: state.isPlaying ? Color.green.opacity(0.6) : Color.clear, radius: 3.0)
                    Text(state.playerSource)
                        .font(.system(size: 11.0, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8.0)
                .padding(.vertical, 3.0)
                .liquidGlassPill(accentColor: nil)

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .accessibilityLabel("Refresh Now Playing")
                        .font(.system(size: 12.0))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }

            // Album Art with Liquid Glass Border & Waveform
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 18.0, style: .continuous)
                    // Kapak görseli yokken doygun renkli sahte kapak yerine sakin, temaya uyumlu bir cam karo
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.20, green: 0.18, blue: 0.34),
                                Color(red: 0.08, green: 0.09, blue: 0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RadialGradient(colors: [SplitBarPalette.violet.opacity(0.45), .clear], center: .topLeading, startRadius: 0, endRadius: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 18.0, style: .continuous))
                    )
                    .frame(width: 140.0, height: 140.0)
                    .shadow(color: Color.black.opacity(0.35), radius: 14.0, x: 0.0, y: 6.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18.0, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.60),
                                        Color.white.opacity(0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )

                Image(systemName: "music.note")
                    .font(.system(size: 54.0, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .frame(width: 140.0, height: 140.0)

                // Dynamic Liquid Waveform Overlay
                HStack(spacing: 3.0) {
                    ForEach(0..<9, id: \.self) { barIndex in
                        DynamicWaveformBarView(
                            isPlaying: state.isPlaying,
                            index: barIndex,
                            barCount: 9
                        )
                    }
                }
                .padding(.horizontal, 10.0)
                .padding(.vertical, 6.0)
                .liquidGlassPill(accentColor: nil)
                .offset(y: 12.0)
            }
            .padding(.top, 4.0)
            .padding(.bottom, 12.0)

            // Track Details
            VStack(spacing: 4.0) {
                Text(state.trackTitle)
                    .font(.system(size: 15.0, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(state.artist.isEmpty ? "Unknown Artist" : state.artist)
                    .font(.system(size: 13.0, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if !state.album.isEmpty {
                    Text(state.album)
                        .font(.system(size: 11.0))
                        .foregroundColor(.secondary.opacity(0.80))
                        .lineLimit(1)
                }
            }

            // Scrubber Bar
            VStack(spacing: 6.0) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 5.0)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        SplitBarPalette.violet,
                                        SplitBarPalette.cyan
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(0.0, min(geo.size.width, geo.size.width * CGFloat(isDraggingScrubber ? dragFraction : state.progressFraction))),
                                height: 5.0
                            )

                        Circle()
                            .fill(Color.white)
                            .frame(width: isDraggingScrubber ? 14.0 : 10.0, height: isDraggingScrubber ? 14.0 : 10.0)
                            .shadow(color: Color.black.opacity(0.35), radius: 3.0, x: 0.0, y: 1.0)
                            .offset(x: max(0.0, min(geo.size.width - 10.0, geo.size.width * CGFloat(isDraggingScrubber ? dragFraction : state.progressFraction) - 5.0)))
                    }
                    .frame(height: 14.0)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0.0)
                            .onChanged { val in
                                isDraggingScrubber = true
                                let fraction = max(0.0, min(1.0, Double(val.location.x / geo.size.width)))
                                dragFraction = fraction
                            }
                            .onEnded { val in
                                let fraction = max(0.0, min(1.0, Double(val.location.x / geo.size.width)))
                                isDraggingScrubber = false
                                if state.duration > 0.0 {
                                    onSeek(fraction * state.duration)
                                }
                            }
                    )
                }
                .frame(height: 14.0)

                HStack {
                    Text(isDraggingScrubber ? formatSeconds(seconds: dragFraction * state.duration) : state.formattedPosition)
                        .font(.system(size: 10.0, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(state.formattedDuration)
                        .font(.system(size: 10.0, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4.0)

            // Transport Controls
            HStack(spacing: 24.0) {
                Button(action: {
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                    onPreviousTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .accessibilityLabel("Previous Track")
                        .font(.system(size: 18.0))
                        .foregroundColor(.primary.opacity(0.85))
                }
                .buttonStyle(.plain)
                .pointingHandCursor()

                Button(action: {
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                    onTogglePlayPause()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        SplitBarPalette.violet,
                                        Color(red: 0.45, green: 0.40, blue: 0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46.0, height: 46.0)
                            .shadow(color: SplitBarPalette.violet.opacity(0.40), radius: 8.0, x: 0.0, y: 3.0)

                        Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                            .accessibilityLabel(state.isPlaying ? "Pause" : "Play")
                            .font(.system(size: 18.0, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: state.isPlaying ? 0.0 : 1.5)
                    }
                }
                .buttonStyle(.plain)
                .pointingHandCursor()

                Button(action: {
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                    onNextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .accessibilityLabel("Next Track")
                        .font(.system(size: 18.0))
                        .foregroundColor(.primary.opacity(0.85))
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
            .padding(.top, 4.0)

            Spacer()
        }
        .padding(16.0)
    }

    private func formatSeconds(seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0.0 else { return "00:00" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
