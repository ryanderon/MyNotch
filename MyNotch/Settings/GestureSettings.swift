import Foundation
import Observation

@Observable
final class GestureSettings {
    private enum Keys {
        static let gesturesOnHover = SettingKey(name: "gestures.gesturesOnHover", defaultValue: true)
        static let verticalOpenClose = SettingKey(name: "gestures.verticalOpenClose", defaultValue: true)
        static let horizontalMediaControl = SettingKey(name: "gestures.horizontalMediaControl", defaultValue: true)
        static let invertMediaGestures = SettingKey(name: "gestures.invertMediaGestures", defaultValue: false)
    }

    @ObservationIgnored private let defaults: UserDefaults

    var gesturesOnHover: Bool {
        didSet { defaults.set(gesturesOnHover, for: Keys.gesturesOnHover) }
    }
    var verticalOpenClose: Bool {
        didSet { defaults.set(verticalOpenClose, for: Keys.verticalOpenClose) }
    }
    var horizontalMediaControl: Bool {
        didSet { defaults.set(horizontalMediaControl, for: Keys.horizontalMediaControl) }
    }
    var invertMediaGestures: Bool {
        didSet { defaults.set(invertMediaGestures, for: Keys.invertMediaGestures) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        gesturesOnHover = defaults.value(for: Keys.gesturesOnHover)
        verticalOpenClose = defaults.value(for: Keys.verticalOpenClose)
        horizontalMediaControl = defaults.value(for: Keys.horizontalMediaControl)
        invertMediaGestures = defaults.value(for: Keys.invertMediaGestures)
    }

    func resetToDefaults() {
        gesturesOnHover = Keys.gesturesOnHover.defaultValue
        verticalOpenClose = Keys.verticalOpenClose.defaultValue
        horizontalMediaControl = Keys.horizontalMediaControl.defaultValue
        invertMediaGestures = Keys.invertMediaGestures.defaultValue
    }
}
