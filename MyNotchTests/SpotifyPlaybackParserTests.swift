import Foundation
import Testing
@testable import MyNotch

@MainActor
struct SpotifyPlaybackParserTests {
    private let receivedAt = Date(timeIntervalSince1970: 1_000_000)

    private func userInfo(state: String) -> [AnyHashable: Any] {
        [
            "Player State": state,
            "Track ID": "spotify:track:123",
            "Name": "Song",
            "Artist": "Artist",
            "Album": "Album",
            "Duration": NSNumber(value: 215_000),
            "Playback Position": NSNumber(value: 12.5)
        ]
    }

    @Test func playingNotificationBecomesNowPlaying() {
        let update = SpotifyPlaybackParser.update(from: userInfo(state: "Playing"), receivedAt: receivedAt)

        guard case .playing(let track) = update else {
            Issue.record("Expected playing, got \(update)")
            return
        }
        #expect(track.trackID == "spotify:track:123")
        #expect(track.title == "Song")
        #expect(track.duration == 215)
        #expect(track.position == 12.5)
    }

    @Test func pausedNotificationKeepsTrack() {
        let update = SpotifyPlaybackParser.update(from: userInfo(state: "Paused"), receivedAt: receivedAt)
        guard case .paused(let track) = update else {
            Issue.record("Expected paused, got \(update)")
            return
        }
        #expect(!track.isPlaying)
    }

    @Test func stoppedOrIncompleteNotificationIsStopped() {
        #expect(SpotifyPlaybackParser.update(from: userInfo(state: "Stopped"), receivedAt: receivedAt) == .stopped)
        #expect(SpotifyPlaybackParser.update(from: ["Player State": "Playing"], receivedAt: receivedAt) == .stopped)
    }

    @Test func elapsedTimeAdvancesOnlyWhilePlaying() throws {
        let update = SpotifyPlaybackParser.update(from: userInfo(state: "Playing"), receivedAt: receivedAt)
        guard case .playing(let track) = update else {
            Issue.record("Expected playing")
            return
        }
        #expect(track.elapsed(at: receivedAt.addingTimeInterval(10)) == 22.5)
        #expect(track.elapsed(at: receivedAt.addingTimeInterval(1000)) == 215)
    }
}
