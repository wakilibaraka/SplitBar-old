import AppKit
import Foundation

@MainActor
public final class NowPlayingService {
    public private(set) var currentState: NowPlayingState = NowPlayingState.idle()
    private var timer: Timer?
    private let queryQueue = DispatchQueue(label: "com.baraka.splitbar.nowplaying", qos: .utility)
    private var queryInFlight = false

    public init() {}

    public func fetchCurrentState() -> NowPlayingState {
        let state = Self.queryStateSynchronously()
        self.currentState = state
        return state
    }

    public func startMonitoring(
        interval: TimeInterval,
        onUpdate: @escaping @MainActor @Sendable (NowPlayingState) -> Void
    ) {
        stopMonitoring()
        onUpdate(fetchCurrentState())
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.refreshInBackground(onUpdate: onUpdate)
            }
        }
    }

    private func refreshInBackground(
        onUpdate: @escaping @MainActor @Sendable (NowPlayingState) -> Void
    ) {
        guard !queryInFlight else { return }
        guard Self.hasRunningPlayer else { return }
        queryInFlight = true
        queryQueue.async { [weak self] in
            let state = Self.queryStateSynchronously()
            Task { @MainActor in
                guard let self else { return }
                self.queryInFlight = false
                self.currentState = state
                onUpdate(state)
            }
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    nonisolated private static var hasRunningPlayer: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty
            || !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty
    }

    nonisolated private static func queryStateSynchronously() -> NowPlayingState {
        if let musicState = queryMusicApp() {
            return musicState
        }
        if let spotifyState = querySpotifyApp() {
            return spotifyState
        }
        return NowPlayingState.idle()
    }

    public func togglePlayPause() {
        runTransportScript(
            music: "tell application \"Music\" to playpause",
            spotify: "tell application \"Spotify\" to playpause"
        )
    }

    public func nextTrack() {
        runTransportScript(
            music: "tell application \"Music\" to next track",
            spotify: "tell application \"Spotify\" to next track"
        )
    }

    public func previousTrack() {
        runTransportScript(
            music: "tell application \"Music\" to previous track",
            spotify: "tell application \"Spotify\" to previous track"
        )
    }

    public func seek(to position: Double) {
        runTransportScript(
            music: "tell application \"Music\" to set player position to \(position)",
            spotify: "tell application \"Spotify\" to set player position to \(position)"
        )
    }

    private func runTransportScript(music: String, spotify: String) {
        queryQueue.async {
            if Self.isAppRunning(bundleID: "com.apple.Music") {
                _ = Self.runScript(source: music)
            } else if Self.isAppRunning(bundleID: "com.spotify.client") {
                _ = Self.runScript(source: spotify)
            }
        }
    }

    nonisolated private static func isAppRunning(bundleID: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    nonisolated private static func queryMusicApp() -> NowPlayingState? {
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

    nonisolated private static func querySpotifyApp() -> NowPlayingState? {
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
    nonisolated private static func runScript(source: String) -> String? {
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
