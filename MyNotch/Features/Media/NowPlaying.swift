import Foundation

struct NowPlaying: Equatable {
    let trackID: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let isPlaying: Bool

    /// Spotify reports the position only when something changes; elapsed time is derived from it on demand.
    let position: TimeInterval
    let positionDate: Date

    func elapsed(at date: Date) -> TimeInterval {
        guard isPlaying else { return position }
        return min(position + date.timeIntervalSince(positionDate), duration)
    }
}

enum SpotifyPlaybackUpdate: Equatable {
    case playing(NowPlaying)
    case paused(NowPlaying)
    case stopped
}

/// Parses the userInfo of Spotify's public `com.spotify.client.PlaybackStateChanged` distributed notification.
enum SpotifyPlaybackParser {
    static func update(from userInfo: [AnyHashable: Any], receivedAt date: Date) -> SpotifyPlaybackUpdate {
        guard let state = userInfo["Player State"] as? String, state != "Stopped",
              let trackID = userInfo["Track ID"] as? String else {
            return .stopped
        }
        let isPlaying = state == "Playing"
        let nowPlaying = NowPlaying(
            trackID: trackID,
            title: userInfo["Name"] as? String ?? "",
            artist: userInfo["Artist"] as? String ?? "",
            album: userInfo["Album"] as? String ?? "",
            // Spotify reports the duration in milliseconds but the position in seconds.
            duration: number(userInfo["Duration"]) / 1000,
            isPlaying: isPlaying,
            position: number(userInfo["Playback Position"]),
            positionDate: date
        )
        return isPlaying ? .playing(nowPlaying) : .paused(nowPlaying)
    }

    private static func number(_ value: Any?) -> Double {
        (value as? NSNumber)?.doubleValue ?? 0
    }
}
