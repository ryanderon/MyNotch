import Foundation
import Observation

@Observable
final class EyeSettings {
    private enum Keys {
        static let isEnabled = SettingKey(name: "eye.enabled", defaultValue: false)
        static let showWhenClosed = SettingKey(name: "eye.showWhenClosed", defaultValue: true)
        static let showWhenOpen = SettingKey(name: "eye.showWhenOpen", defaultValue: true)
        static let blinks = SettingKey(name: "eye.blink", defaultValue: true)
        static let sleepsWhenIdle = SettingKey(name: "eye.sleepWhenIdle", defaultValue: true)
    }

    @ObservationIgnored private let defaults: UserDefaults

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, for: Keys.isEnabled) }
    }
    var showWhenClosed: Bool {
        didSet { defaults.set(showWhenClosed, for: Keys.showWhenClosed) }
    }
    var showWhenOpen: Bool {
        didSet { defaults.set(showWhenOpen, for: Keys.showWhenOpen) }
    }
    var blinks: Bool {
        didSet { defaults.set(blinks, for: Keys.blinks) }
    }
    var sleepsWhenIdle: Bool {
        didSet { defaults.set(sleepsWhenIdle, for: Keys.sleepsWhenIdle) }
    }

    var isShownWhenClosed: Bool { isEnabled && showWhenClosed }
    var isShownWhenOpen: Bool { isEnabled && showWhenOpen }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        isEnabled = defaults.value(for: Keys.isEnabled)
        showWhenClosed = defaults.value(for: Keys.showWhenClosed)
        showWhenOpen = defaults.value(for: Keys.showWhenOpen)
        blinks = defaults.value(for: Keys.blinks)
        sleepsWhenIdle = defaults.value(for: Keys.sleepsWhenIdle)
    }

    func resetToDefaults() {
        isEnabled = Keys.isEnabled.defaultValue
        showWhenClosed = Keys.showWhenClosed.defaultValue
        showWhenOpen = Keys.showWhenOpen.defaultValue
        blinks = Keys.blinks.defaultValue
        sleepsWhenIdle = Keys.sleepsWhenIdle.defaultValue
    }
}
