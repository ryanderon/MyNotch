import Foundation

/// One settings object per Settings tab, sharing a single UserDefaults domain.
final class SettingsStore {
    let general: GeneralSettings
    let gestures: GestureSettings
    let liveActivities: LiveActivitySettings
    let nook: NookSettings
    let shelf: ShelfSettings
    let eye: EyeSettings
    let pet: PetSettings

    init(defaults: UserDefaults = .standard) {
        general = GeneralSettings(defaults: defaults)
        gestures = GestureSettings(defaults: defaults)
        liveActivities = LiveActivitySettings(defaults: defaults)
        nook = NookSettings(defaults: defaults)
        shelf = ShelfSettings(defaults: defaults)
        eye = EyeSettings(defaults: defaults)
        pet = PetSettings(defaults: defaults)
    }

    func resetToDefaults() {
        general.resetToDefaults()
        gestures.resetToDefaults()
        liveActivities.resetToDefaults()
        nook.resetToDefaults()
        shelf.resetToDefaults()
        eye.resetToDefaults()
        pet.resetToDefaults()
    }
}
