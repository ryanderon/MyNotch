import Foundation
import Observation

/// Turns modules on and off as their settings change, so a disabled module has no listener, store, or timer.
/// Each loop lives for the app's lifetime and only wakes when the settings it reads change.
extension AppModel {
    func startLifecycleObservations() {
        let general = settings.general
        let liveActivities = settings.liveActivities
        let nook = settings.nook
        let pet = settings.pet
        lifecycleObservations = [
            Task { [weak self] in
                for await _ in Observations({ NotchPlacementRules(general: general) }) {
                    self?.updatePlacement()
                }
            },
            Task { [weak self] in
                for await _ in Observations({ CoordinatorRules(liveActivities: liveActivities, nook: nook) }) {
                    self?.coordinator.settingsDidChange()
                }
            },
            Task { [weak self] in
                for await needsMedia in Observations({
                    liveActivities.isKindEnabled(.media) || nook.isWidgetEnabled(.mediaPlayer) || general.demoMode
                }) {
                    self?.updateMediaService(isNeeded: needsMedia)
                }
            },
            Task { [weak self] in
                for await needsCalendar in Observations({
                    nook.isWidgetEnabled(.calendar) || liveActivities.isKindEnabled(.calendar)
                }) {
                    self?.updateCalendarService(isNeeded: needsCalendar)
                }
            },
            Task { [weak self] in
                for await _ in Observations({ CalendarFilterOptions(nook: nook) }) {
                    self?.calendar.reload()
                }
            },
            Task { [weak self] in
                for await petType in Observations({ pet.activeType }) {
                    self?.updatePetCompanion(type: petType)
                }
            },
            Task { [weak self] in
                for await _ in Observations({ pet.hungerNotifications }) {
                    self?.petCompanion?.store.rescheduleHungerNotification()
                }
            }
        ]
    }

    /// Demo mode shows a sample track instead of listening to Spotify.
    private func updateMediaService(isNeeded: Bool) {
        media.stop()
        coordinator.end(.media)
        guard isNeeded else { return }
        if settings.general.demoMode {
            media.apply(.playing(DemoContent.nowPlaying(at: Date())), artwork: DemoContent.artwork())
        } else {
            media.start()
        }
    }

    private func updateCalendarService(isNeeded: Bool) {
        if isNeeded {
            calendar.start()
        } else {
            calendar.stop()
            coordinator.end(.calendar)
        }
    }

    private func updatePetCompanion(type: PetType?) {
        guard let type else {
            petCompanion?.store.flushPendingSave()
            petCompanion?.store.cancelHungerNotification()
            petCompanion = nil
            return
        }
        guard petCompanion?.sprites.type != type else { return }
        let store = petCompanion?.store ?? PetStore(document: petDocument, settings: settings.pet)
        petCompanion = PetCompanion(store: store, sprites: PetSpriteSheet(type: type))
        Task { await store.requestNotificationPermission() }
    }
}

/// The settings that change which live activity may be shown, observed as one value.
struct CoordinatorRules: Equatable {
    let isEnabled: Bool
    let hideOnNonNotched: Bool
    let quickPeek: Bool
    let enabledKinds: Set<LiveActivityKind>
    let visibleInFullscreen: Set<LiveActivityKind>
    let isNookEnabled: Bool

    init(liveActivities: LiveActivitySettings, nook: NookSettings) {
        isEnabled = liveActivities.isEnabled
        hideOnNonNotched = liveActivities.hideOnNonNotched
        quickPeek = liveActivities.quickPeek
        enabledKinds = liveActivities.enabledKinds
        visibleInFullscreen = liveActivities.visibleInFullscreen
        isNookEnabled = nook.isEnabled
    }
}
