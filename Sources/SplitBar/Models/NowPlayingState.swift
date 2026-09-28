import Foundation

public struct NowPlayingState: Equatable, Sendable {
    public let trackTitle: String
    public let artist: String
    public let album: String
    public let isPlaying: Bool
    public let playbackPosition: Double
    public let duration: Double
    public let playerSource: String

    public init(
        trackTitle: String,
        artist: String,
        album: String,
        isPlaying: Bool,
        playbackPosition: Double,
        duration: Double,
        playerSource: String
    ) {
        self.trackTitle = trackTitle
        self.artist = artist
        self.album = album
        self.isPlaying = isPlaying
        self.playbackPosition = playbackPosition
        self.duration = duration
        self.playerSource = playerSource
    }

    public static func idle() -> NowPlayingState {
        NowPlayingState(
            trackTitle: "No Track Playing",
            artist: "Launch Music or Spotify",
            album: "",
            isPlaying: false,
            playbackPosition: 0.0,
            duration: 0.0,
            playerSource: "Ready"
        )
    }

    public var progressFraction: Double {
        guard duration > 0.0 else { return 0.0 }
        return min(1.0, max(0.0, playbackPosition / duration))
    }

    public var formattedPosition: String {
        formatSeconds(seconds: playbackPosition)
    }

    public var formattedDuration: String {
        formatSeconds(seconds: duration)
    }

    private func formatSeconds(seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0.0 else { return "00:00" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
