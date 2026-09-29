import AppKit
import Observation
import OSLog

/// Now-playing state for Spotify, driven by Spotify's public distributed notification (no polling).
/// Artwork is fetched once per track change; only one track's artwork is ever kept.
@Observable
final class MediaService {
    private static let playbackNotification = Notification.Name("com.spotify.client.PlaybackStateChanged")

    private(set) var nowPlaying: NowPlaying?
    private(set) var artwork: ProcessedArtwork?

    @ObservationIgnored var playbackDidChange: ((SpotifyPlaybackUpdate) -> Void)?
    @ObservationIgnored var trackDidChange: (() -> Void)?

    @ObservationIgnored private var observer: NSObjectProtocol?
    @ObservationIgnored private var artworkTask: Task<Void, Never>?

    var isRunning: Bool { observer != nil }

    func start() {
        guard observer == nil else { return }
        observer = DistributedNotificationCenter.default().addObserver(
            forName: Self.playbackNotification, object: nil, queue: .main
        ) { [weak self] notification in
            let userInfo = notification.userInfo ?? [:]
            MainActor.assumeIsolated {
                self?.apply(SpotifyPlaybackParser.update(from: userInfo, receivedAt: Date()))
            }
        }
        loadInitialPlayback()
    }

    func stop() {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        observer = nil
        artworkTask?.cancel()
        artworkTask = nil
        nowPlaying = nil
        artwork = nil
    }

    func perform(_ command: MediaCommand) {
        do {
            try SpotifyScripting.perform(command)
        } catch {
            Logger.services.error("Spotify command failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// Also used by demo mode to show a sample track without Spotify.
    func apply(_ update: SpotifyPlaybackUpdate, artwork demoArtwork: ProcessedArtwork? = nil) {
        switch update {
        case .playing(let track), .paused(let track):
            let isNewTrack = track.trackID != nowPlaying?.trackID
            nowPlaying = track
            if isNewTrack {
                replaceArtwork(for: track, with: demoArtwork)
                trackDidChange?()
            }
        case .stopped:
            artworkTask?.cancel()
            nowPlaying = nil
            artwork = nil
        }
        playbackDidChange?(update)
    }

    /// Spotify only posts on changes, so a song already playing at launch is read once via Apple Events.
    private func loadInitialPlayback() {
        guard SpotifyScripting.isRunning else { return }
        do {
            apply(try SpotifyScripting.currentPlayback(at: Date()))
        } catch {
            Logger.services.info("No initial Spotify state: \(String(describing: error), privacy: .public)")
        }
    }

    private func replaceArtwork(for track: NowPlaying, with demoArtwork: ProcessedArtwork?) {
        artworkTask?.cancel()
        artwork = demoArtwork
        guard demoArtwork == nil else { return }
        let artworkURL: URL?
        do {
            artworkURL = try SpotifyScripting.artworkURL()
        } catch {
            Logger.services.error("Artwork URL unavailable: \(String(describing: error), privacy: .public)")
            return
        }
        guard let artworkURL else { return }
        artworkTask = Task { [weak self] in
            await self?.downloadArtwork(from: artworkURL, trackID: track.trackID)
        }
    }

    private func downloadArtwork(from url: URL, trackID: String) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let processed = try await Task.detached(priority: .utility) {
                try ArtworkProcessor.process(data)
            }.value
            guard !Task.isCancelled, nowPlaying?.trackID == trackID else { return }
            artwork = processed
        } catch {
            guard !Task.isCancelled else { return }
            Logger.services.error("Artwork download failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
