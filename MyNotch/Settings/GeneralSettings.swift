import CoreGraphics
import Foundation
import Observation

enum FullscreenVisibility: String, CaseIterable, Identifiable {
    case notchedScreens
    case allScreens
    case never

    var id: Self { self }

    var title: String {
        switch self {
        case .notchedScreens: "On notched screens"
        case .allScreens: "On all screens"
        case .never: "Never"
        }
    }
}

enum MediaSource: String, CaseIterable, Identifiable {
    case spotify

    var id: Self { self }
    var title: String { "Spotify" }
}

@Observable
final class GeneralSettings {
    static let contentPaddingRange = 0...24
    static let notchFineTuneWidthRange = -40...40
    static let notchFineTuneHeightRange = -10...10
    static let handlerWidthRange = 80...400
    static let handlerHeightRange = 4...24

    private enum Keys {
        static let showInFullscreen = SettingKey(name: "general.showInFullscreen", defaultValue: FullscreenVisibility.notchedScreens)
        static let mediaSource = SettingKey(name: "general.mediaSource", defaultValue: MediaSource.spotify)
        static let preferRoundButtons = SettingKey(name: "general.preferRoundButtons", defaultValue: true)
        static let translucentBackground = SettingKey(name: "general.translucentBackground", defaultValue: false)
        static let alwaysOpenOnHover = SettingKey(name: "general.alwaysOpenOnHover", defaultValue: false)
        static let disableHaptics = SettingKey(name: "general.disableHaptics", defaultValue: true)
        static let preventCloseWhileTyping = SettingKey(name: "general.preventCloseWhileTyping", defaultValue: false)
        static let lockWhileTyping = SettingKey(name: "general.lockWhileTyping", defaultValue: false)
        static let contentPadding = SettingKey(name: "general.contentPadding", defaultValue: 12)
        static let notchFineTuneWidth = SettingKey(name: "general.notchFineTuneWidth", defaultValue: 0)
        static let notchFineTuneHeight = SettingKey(name: "general.notchFineTuneHeight", defaultValue: 0)
        static let handlerEnabled = SettingKey(name: "general.handlerEnabled", defaultValue: false)
        static let handlerWidth = SettingKey(name: "general.handlerWidth", defaultValue: 184)
        static let handlerHeight = SettingKey(name: "general.handlerHeight", defaultValue: 8)
        static let handlerTransparent = SettingKey(name: "general.handlerTransparent", defaultValue: false)
        static let demoMode = SettingKey(name: "general.demoMode", defaultValue: false)
        static let hasAppliedLaunchAtLoginDefault = SettingKey(
            name: "general.hasAppliedLaunchAtLoginDefault",
            defaultValue: false
        )
    }

    @ObservationIgnored private let defaults: UserDefaults

    var showInFullscreen: FullscreenVisibility {
        didSet { defaults.set(showInFullscreen, for: Keys.showInFullscreen) }
    }
    var mediaSource: MediaSource {
        didSet { defaults.set(mediaSource, for: Keys.mediaSource) }
    }
    var preferRoundButtons: Bool {
        didSet { defaults.set(preferRoundButtons, for: Keys.preferRoundButtons) }
    }
    var translucentBackground: Bool {
        didSet { defaults.set(translucentBackground, for: Keys.translucentBackground) }
    }
    var alwaysOpenOnHover: Bool {
        didSet { defaults.set(alwaysOpenOnHover, for: Keys.alwaysOpenOnHover) }
    }
    var disableHaptics: Bool {
        didSet { defaults.set(disableHaptics, for: Keys.disableHaptics) }
    }
    var preventCloseWhileTyping: Bool {
        didSet { defaults.set(preventCloseWhileTyping, for: Keys.preventCloseWhileTyping) }
    }
    var lockWhileTyping: Bool {
        didSet { defaults.set(lockWhileTyping, for: Keys.lockWhileTyping) }
    }
    var contentPadding: Int {
        didSet { defaults.set(contentPadding, for: Keys.contentPadding) }
    }
    var notchFineTuneWidth: Int {
        didSet { defaults.set(notchFineTuneWidth, for: Keys.notchFineTuneWidth) }
    }
    var notchFineTuneHeight: Int {
        didSet { defaults.set(notchFineTuneHeight, for: Keys.notchFineTuneHeight) }
    }
    var handlerEnabled: Bool {
        didSet { defaults.set(handlerEnabled, for: Keys.handlerEnabled) }
    }
    var handlerWidth: Int {
        didSet { defaults.set(handlerWidth, for: Keys.handlerWidth) }
    }
    var handlerHeight: Int {
        didSet { defaults.set(handlerHeight, for: Keys.handlerHeight) }
    }
    var handlerTransparent: Bool {
        didSet { defaults.set(handlerTransparent, for: Keys.handlerTransparent) }
    }
    var demoMode: Bool {
        didSet { defaults.set(demoMode, for: Keys.demoMode) }
    }

    /// Not user-facing: records that the "launch at login = true" default was applied once,
    /// so a user who later turns it off is never re-registered. Survives "Reset Settings".
    var hasAppliedLaunchAtLoginDefault: Bool {
        didSet { defaults.set(hasAppliedLaunchAtLoginDefault, for: Keys.hasAppliedLaunchAtLoginDefault) }
    }

    /// Only meaningful while `preventCloseWhileTyping` is on, as in the PRD schema.
    var isTypingLockActive: Bool { preventCloseWhileTyping && lockWhileTyping }

    var notchFineTune: CGSize {
        CGSize(width: notchFineTuneWidth, height: notchFineTuneHeight)
    }

    var handlerSize: CGSize {
        CGSize(width: handlerWidth, height: handlerHeight)
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        showInFullscreen = defaults.value(for: Keys.showInFullscreen)
        mediaSource = defaults.value(for: Keys.mediaSource)
        preferRoundButtons = defaults.value(for: Keys.preferRoundButtons)
        translucentBackground = defaults.value(for: Keys.translucentBackground)
        alwaysOpenOnHover = defaults.value(for: Keys.alwaysOpenOnHover)
        disableHaptics = defaults.value(for: Keys.disableHaptics)
        preventCloseWhileTyping = defaults.value(for: Keys.preventCloseWhileTyping)
        lockWhileTyping = defaults.value(for: Keys.lockWhileTyping)
        contentPadding = defaults.value(for: Keys.contentPadding)
        notchFineTuneWidth = defaults.value(for: Keys.notchFineTuneWidth)
        notchFineTuneHeight = defaults.value(for: Keys.notchFineTuneHeight)
        handlerEnabled = defaults.value(for: Keys.handlerEnabled)
        handlerWidth = defaults.value(for: Keys.handlerWidth)
        handlerHeight = defaults.value(for: Keys.handlerHeight)
        handlerTransparent = defaults.value(for: Keys.handlerTransparent)
        demoMode = defaults.value(for: Keys.demoMode)
        hasAppliedLaunchAtLoginDefault = defaults.value(for: Keys.hasAppliedLaunchAtLoginDefault)
    }

    func resetToDefaults() {
        showInFullscreen = Keys.showInFullscreen.defaultValue
        mediaSource = Keys.mediaSource.defaultValue
        preferRoundButtons = Keys.preferRoundButtons.defaultValue
        translucentBackground = Keys.translucentBackground.defaultValue
        alwaysOpenOnHover = Keys.alwaysOpenOnHover.defaultValue
        disableHaptics = Keys.disableHaptics.defaultValue
        preventCloseWhileTyping = Keys.preventCloseWhileTyping.defaultValue
        lockWhileTyping = Keys.lockWhileTyping.defaultValue
        contentPadding = Keys.contentPadding.defaultValue
        notchFineTuneWidth = Keys.notchFineTuneWidth.defaultValue
        notchFineTuneHeight = Keys.notchFineTuneHeight.defaultValue
        handlerEnabled = Keys.handlerEnabled.defaultValue
        handlerWidth = Keys.handlerWidth.defaultValue
        handlerHeight = Keys.handlerHeight.defaultValue
        handlerTransparent = Keys.handlerTransparent.defaultValue
        demoMode = Keys.demoMode.defaultValue
    }
}
