import AppKit
import Foundation

@MainActor
public final class NowPlayingService {
    public private(set) var currentState: NowPlayingState = NowPlayingState.idle()
    private var timer: Timer?

    public init() {}

    public func fetchCurrentState() -> NowPlayingState {
        if let musicState = queryMusicApp() {
            self.currentState = musicState
            return musicState
        }
        if let spotifyState = querySpotifyApp() {
            self.currentState = spotifyState
            return spotifyState
        }
        let idleState = NowPlayingState.idle()
        self.currentState = idleState
        return idleState
    }

    public func startMonitoring(
        interval: TimeInterval,
        onUpdate: @escaping @MainActor @Sendable (NowPlayingState) -> Void
    ) {
        stopMonitoring()
        onUpdate(fetchCurrentState())
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let state = self.fetchCurrentState()
                onUpdate(state)
            }
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    public func togglePlayPause() {
        if isAppRunning(bundleID: "com.apple.Music") {
            runScript(source: "tell application \"Music\" to playpause")
        } else if isAppRunning(bundleID: "com.spotify.client") {
            runScript(source: "tell application \"Spotify\" to playpause")
        }
    }

    public func nextTrack() {
        if isAppRunning(bundleID: "com.apple.Music") {
            runScript(source: "tell application \"Music\" to next track")
        } else if isAppRunning(bundleID: "com.spotify.client") {
            runScript(source: "tell application \"Spotify\" to next track")
        }
    }

    public func previousTrack() {
        if isAppRunning(bundleID: "com.apple.Music") {
            runScript(source: "tell application \"Music\" to previous track")
        } else if isAppRunning(bundleID: "com.spotify.client") {
            runScript(source: "tell application \"Spotify\" to previous track")
        }
    }

    public func seek(to position: Double) {
        if isAppRunning(bundleID: "com.apple.Music") {
            runScript(source: "tell application \"Music\" to set player position to \(position)")
        } else if isAppRunning(bundleID: "com.spotify.client") {
            runScript(source: "tell application \"Spotify\" to set player position to \(position)")
        }
    }

    private func isAppRunning(bundleID: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    private func queryMusicApp() -> NowPlayingState? {
        guard isAppRunning(bundleID: "com.apple.Music") else {
            return nil
        }
        let scriptSource = """
        tell application "Music"
            set playerState to (player state as string)
            if playerState is not "stopped" then
                set tName to name of current track
                set tArtist to artist of current track
                set tAlbum to album of current track
                set tPos to player position
                set tDur to duration of current track
                return playerState & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (tPos as string) & "|||" & (tDur as string)
            end if
        end tell
        """
        guard let output = runScript(source: scriptSource) else {
            return nil
        }
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 4 else {
            return nil
        }
        let isPlaying = parts[0].lowercased() == "playing"
        let title = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let album = parts[3].trimmingCharacters(in: .whitespacesAndNewlines)
        let position = parts.count > 4 ? (Double(parts[4]) ?? 0.0) : 0.0
        let duration = parts.count > 5 ? (Double(parts[5]) ?? 0.0) : 0.0
        return NowPlayingState(
            trackTitle: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            playbackPosition: position,
            duration: duration,
            playerSource: "Apple Music"
        )
    }

    private func querySpotifyApp() -> NowPlayingState? {
        guard isAppRunning(bundleID: "com.spotify.client") else {
            return nil
        }
        let scriptSource = """
        tell application "Spotify"
            set playerState to (player state as string)
            if playerState is not "stopped" then
                set tName to name of current track
                set tArtist to artist of current track
                set tAlbum to album of current track
                set tPos to player position
                set tDur to (duration of current track) / 1000.0
                return playerState & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (tPos as string) & "|||" & (tDur as string)
            end if
        end tell
        """
        guard let output = runScript(source: scriptSource) else {
            return nil
        }
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 4 else {
            return nil
        }
        let isPlaying = parts[0].lowercased() == "playing"
        let title = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let album = parts[3].trimmingCharacters(in: .whitespacesAndNewlines)
        let position = parts.count > 4 ? (Double(parts[4]) ?? 0.0) : 0.0
        let duration = parts.count > 5 ? (Double(parts[5]) ?? 0.0) : 0.0
        return NowPlayingState(
            trackTitle: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            playbackPosition: position,
            duration: duration,
            playerSource: "Spotify"
        )
    }

    @discardableResult
    private func runScript(source: String) -> String? {
        guard let script = NSAppleScript(source: source) else {
            return nil
        }
        var errorDict: NSDictionary?
        let descriptor = script.executeAndReturnError(&errorDict)
        if errorDict != nil {
            return nil
        }
        return descriptor.stringValue
    }
}
