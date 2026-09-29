import SwiftUI

struct MediaPlayerWidget: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let track = model.media.nowPlaying {
            NowPlayingView(track: track)
        } else {
            WidgetMessage(
                systemImage: "music.note",
                message: "Nothing playing in Spotify",
                actionTitle: "Open Spotify",
                action: openSpotify
            )
        }
    }

    private func openSpotify() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: SpotifyScripting.bundleIdentifier) else {
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}

private struct NowPlayingView: View {
    @Environment(AppModel.self) private var model
    let track: NowPlaying

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                MediaArtworkThumbnail(size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(track.artist)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            PlaybackProgress(track: track)
            TransportControls(isPlaying: track.isPlaying)
        }
        .frame(maxHeight: .infinity)
    }
}

/// Redraws once per second, and only while playing and visible; paused, it draws once and stops.
private struct PlaybackProgress: View {
    let track: NowPlaying

    var body: some View {
        TimelineView(.periodic(from: .now, by: track.isPlaying ? 1 : 3600)) { context in
            let elapsed = track.elapsed(at: track.isPlaying ? context.date : track.positionDate)
            VStack(spacing: 2) {
                ProgressView(value: elapsed, total: max(track.duration, 1))
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .controlSize(.mini)
                HStack {
                    Text(Duration.seconds(elapsed).formatted(.time(pattern: .minuteSecond)))
                    Spacer()
                    Text(Duration.seconds(track.duration).formatted(.time(pattern: .minuteSecond)))
                }
                .font(.system(size: 9).monospacedDigit())
                .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

private struct TransportControls: View {
    @Environment(AppModel.self) private var model
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 14) {
            Button { model.perform(.previousTrack) } label: { Image(systemName: "backward.fill") }
            Button { model.perform(.playPause) } label: { Image(systemName: isPlaying ? "pause.fill" : "play.fill") }
                .buttonStyle(NotchIconButtonStyle(size: 30))
            Button { model.perform(.nextTrack) } label: { Image(systemName: "forward.fill") }
        }
        .buttonStyle(NotchIconButtonStyle(size: 24))
    }
}
