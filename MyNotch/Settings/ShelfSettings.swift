import Foundation
import Observation

/// Widths (in nook cells) of the two file surfaces: the Tray tab and the Drop Area.
@Observable
final class ShelfSettings {
    static let widthRange = 6...16

    private enum Keys {
        static let trayWidth = SettingKey(name: "tray.width", defaultValue: 11)
        static let dropAreaWidth = SettingKey(name: "dropArea.width", defaultValue: 11)
    }

    @ObservationIgnored private let defaults: UserDefaults

    var trayWidth: Int {
        didSet { defaults.set(trayWidth, for: Keys.trayWidth) }
    }
    var dropAreaWidth: Int {
        didSet { defaults.set(dropAreaWidth, for: Keys.dropAreaWidth) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        trayWidth = defaults.value(for: Keys.trayWidth)
        dropAreaWidth = defaults.value(for: Keys.dropAreaWidth)
    }

    func resetToDefaults() {
        trayWidth = Keys.trayWidth.defaultValue
        dropAreaWidth = Keys.dropAreaWidth.defaultValue
    }
}
