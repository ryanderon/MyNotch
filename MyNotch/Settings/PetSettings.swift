import Foundation
import Observation

enum PetType: String, Codable, CaseIterable, Identifiable {
    case cat
    case dog
    case blob

    var id: Self { self }

    var title: String {
        switch self {
        case .cat: "Cat"
        case .dog: "Dog"
        case .blob: "Blob"
        }
    }
}

@Observable
final class PetSettings {
    private enum Keys {
        static let isEnabled = SettingKey(name: "pet.enabled", defaultValue: false)
        static let type = SettingKey<PetType?>(name: "pet.type", defaultValue: nil)
        static let hungerNotifications = SettingKey(name: "pet.hungerNotifications", defaultValue: true)
    }

    @ObservationIgnored private let defaults: UserDefaults

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, for: Keys.isEnabled) }
    }

    /// Nil until the user picks a pet on first enable.
    var type: PetType? {
        didSet { defaults.setEncoded(type, for: Keys.type) }
    }
    var hungerNotifications: Bool {
        didSet { defaults.set(hungerNotifications, for: Keys.hungerNotifications) }
    }

    /// The pet only exists once it is enabled and a type has been chosen.
    var activeType: PetType? { isEnabled ? type : nil }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        isEnabled = defaults.value(for: Keys.isEnabled)
        type = defaults.decodedValue(for: Keys.type)
        hungerNotifications = defaults.value(for: Keys.hungerNotifications)
    }

    /// The chosen pet type is kept: resetting settings must not orphan the pet's saved stats.
    func resetToDefaults() {
        isEnabled = Keys.isEnabled.defaultValue
        hungerNotifications = Keys.hungerNotifications.defaultValue
    }
}
