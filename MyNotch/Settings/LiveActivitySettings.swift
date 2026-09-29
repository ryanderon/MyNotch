import Foundation
import Observation

enum MediaEffect: String, CaseIterable, Identifiable {
    case spectrograph
    case waves
    case vibratingCircle
    case gif

    var id: Self { self }

    var title: String {
        switch self {
        case .spectrograph: "Audio Spectrograph"
        case .waves: "Waves"
        case .vibratingCircle: "Vibrating Circle"
        case .gif: "GIF"
        }
    }
}

@Observable
final class LiveActivitySettings {
    static let inactivityTimeoutRange = 3...60
    static let albumCornerRadiusRange = 0...12

    private enum Keys {
        static let isEnabled = SettingKey(name: "liveActivities.enabled", defaultValue: true)
        static let hideOnNonNotched = SettingKey(name: "liveActivities.hideOnNonNotched", defaultValue: false)
        static let inactivityTimeout = SettingKey(name: "liveActivities.inactivityTimeout", defaultValue: 10)
        static let isInteractive = SettingKey(name: "liveActivities.interactive", defaultValue: true)
        static let quickPeek = SettingKey(name: "liveActivities.quickPeek", defaultValue: true)
        static let unhideAutomatically = SettingKey(name: "liveActivities.unhideAutomatically", defaultValue: true)
        static let showSongChange = SettingKey(name: "liveActivities.showSongChange", defaultValue: false)
        static let visibleInFullscreen = SettingKey(
            name: "liveActivities.showInFullscreen",
            defaultValue: Set(LiveActivityKind.allCases)
        )
        static let enabledKinds = SettingKey(
            name: "liveActivities.enabledKinds",
            defaultValue: Set<LiveActivityKind>([.media, .filesTray, .newUpdate])
        )
        static let albumCornerRadius = SettingKey(name: "liveActivities.media.albumCornerRadius", defaultValue: 5)
        static let mediaEffect = SettingKey(name: "liveActivities.media.effectType", defaultValue: MediaEffect.spectrograph)
        static let coloredEffects = SettingKey(name: "liveActivities.media.coloredEffects", defaultValue: true)
        static let gifPath = SettingKey(name: "liveActivities.media.gifPath", defaultValue: "")
    }

    @ObservationIgnored private let defaults: UserDefaults

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, for: Keys.isEnabled) }
    }
    var hideOnNonNotched: Bool {
        didSet { defaults.set(hideOnNonNotched, for: Keys.hideOnNonNotched) }
    }
    var inactivityTimeout: Int {
        didSet { defaults.set(inactivityTimeout, for: Keys.inactivityTimeout) }
    }
    var isInteractive: Bool {
        didSet { defaults.set(isInteractive, for: Keys.isInteractive) }
    }
    var quickPeek: Bool {
        didSet { defaults.set(quickPeek, for: Keys.quickPeek) }
    }
    var unhideAutomatically: Bool {
        didSet { defaults.set(unhideAutomatically, for: Keys.unhideAutomatically) }
    }
    var showSongChange: Bool {
        didSet { defaults.set(showSongChange, for: Keys.showSongChange) }
    }
    var visibleInFullscreen: Set<LiveActivityKind> {
        didSet { defaults.setEncoded(visibleInFullscreen, for: Keys.visibleInFullscreen) }
    }
    var enabledKinds: Set<LiveActivityKind> {
        didSet { defaults.setEncoded(enabledKinds, for: Keys.enabledKinds) }
    }
    var albumCornerRadius: Int {
        didSet { defaults.set(albumCornerRadius, for: Keys.albumCornerRadius) }
    }
    var mediaEffect: MediaEffect {
        didSet { defaults.set(mediaEffect, for: Keys.mediaEffect) }
    }
    var coloredEffects: Bool {
        didSet { defaults.set(coloredEffects, for: Keys.coloredEffects) }
    }

    /// The GIF effect needs a user-chosen file; empty means none chosen yet.
    var gifPath: String {
        didSet { defaults.set(gifPath, for: Keys.gifPath) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        isEnabled = defaults.value(for: Keys.isEnabled)
        hideOnNonNotched = defaults.value(for: Keys.hideOnNonNotched)
        inactivityTimeout = defaults.value(for: Keys.inactivityTimeout)
        isInteractive = defaults.value(for: Keys.isInteractive)
        quickPeek = defaults.value(for: Keys.quickPeek)
        unhideAutomatically = defaults.value(for: Keys.unhideAutomatically)
        showSongChange = defaults.value(for: Keys.showSongChange)
        visibleInFullscreen = defaults.decodedValue(for: Keys.visibleInFullscreen)
        enabledKinds = defaults.decodedValue(for: Keys.enabledKinds)
        albumCornerRadius = defaults.value(for: Keys.albumCornerRadius)
        mediaEffect = defaults.value(for: Keys.mediaEffect)
        coloredEffects = defaults.value(for: Keys.coloredEffects)
        gifPath = defaults.value(for: Keys.gifPath)
    }

    func isKindEnabled(_ kind: LiveActivityKind) -> Bool {
        isEnabled && enabledKinds.contains(kind)
    }

    func resetToDefaults() {
        isEnabled = Keys.isEnabled.defaultValue
        hideOnNonNotched = Keys.hideOnNonNotched.defaultValue
        inactivityTimeout = Keys.inactivityTimeout.defaultValue
        isInteractive = Keys.isInteractive.defaultValue
        quickPeek = Keys.quickPeek.defaultValue
        unhideAutomatically = Keys.unhideAutomatically.defaultValue
        showSongChange = Keys.showSongChange.defaultValue
        visibleInFullscreen = Keys.visibleInFullscreen.defaultValue
        enabledKinds = Keys.enabledKinds.defaultValue
        albumCornerRadius = Keys.albumCornerRadius.defaultValue
        mediaEffect = Keys.mediaEffect.defaultValue
        coloredEffects = Keys.coloredEffects.defaultValue
        gifPath = Keys.gifPath.defaultValue
    }
}
