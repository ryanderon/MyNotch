import AppKit
import OSLog

enum SpotifyScriptingError: Error {
    case notRunning
    case scriptFailed(String)
    case unexpectedResult
}

/// The only place MyNotch talks to Spotify with Apple Events. Scripts run on demand (a button press,
/// a gesture, once per track change for artwork, once at launch) and never on a schedule,
/// because every call wakes Spotify.
enum SpotifyScripting {
    static let bundleIdentifier = "com.spotify.client"

    static var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    }

    static func perform(_ command: MediaCommand) throws {
        let verb = switch command {
        case .playPause: "playpause"
        case .nextTrack: "next track"
        case .previousTrack: "previous track"
        }
        _ = try run("tell application \"Spotify\" to \(verb)")
    }

    static func artworkURL() throws -> URL? {
        guard isRunning else { throw SpotifyScriptingError.notRunning }
        let result = try run("tell application \"Spotify\" to artwork url of current track")
        return result.stringValue.flatMap(URL.init(string:))
    }

    /// Reads the same fields the playback notification carries, in the same units.
    static func currentPlayback(at date: Date) throws -> SpotifyPlaybackUpdate {
        guard isRunning else { throw SpotifyScriptingError.notRunning }
        let result = try run("""
            tell application "Spotify"
                set t to current track
                return {player state as string, id of t, name of t, artist of t, album of t, duration of t, player position}
            end tell
            """)
        guard result.numberOfItems == 7 else { throw SpotifyScriptingError.unexpectedResult }
        let state = result.atIndex(1)?.stringValue ?? "stopped"
        let userInfo: [AnyHashable: Any] = [
            "Player State": state.capitalized,
            "Track ID": result.atIndex(2)?.stringValue as Any,
            "Name": result.atIndex(3)?.stringValue as Any,
            "Artist": result.atIndex(4)?.stringValue as Any,
            "Album": result.atIndex(5)?.stringValue as Any,
            "Duration": NSNumber(value: result.atIndex(6)?.int32Value ?? 0),
            "Playback Position": NSNumber(value: result.atIndex(7)?.doubleValue ?? 0)
        ]
        return SpotifyPlaybackParser.update(from: userInfo, receivedAt: date)
    }

    /// NSAppleScript must be used on the main thread; the timeout keeps a hung Spotify from blocking the UI.
    private static func run(_ source: String) throws -> NSAppleEventDescriptor {
        let timedSource = "with timeout of 2 seconds\n\(source)\nend timeout"
        guard let script = NSAppleScript(source: timedSource) else {
            throw SpotifyScriptingError.scriptFailed("Could not compile script")
        }
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            throw SpotifyScriptingError.scriptFailed(errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown error")
        }
        return result
    }
}
