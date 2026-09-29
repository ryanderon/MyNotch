import CoreGraphics
import Foundation
import Testing
@testable import MyNotch

/// Each test gets its own defaults domain so tests never touch the real app's settings or each other.
func makeIsolatedDefaults() throws -> UserDefaults {
    try #require(UserDefaults(suiteName: "MyNotchTests.\(UUID().uuidString)"))
}

@MainActor
struct SettingsStoreTests {
    private let defaults: UserDefaults

    init() throws {
        defaults = try makeIsolatedDefaults()
    }

    @Test func generalDefaultsMatchPRD() {
        let general = SettingsStore(defaults: defaults).general

        #expect(general.showInFullscreen == .notchedScreens)
        #expect(general.preferRoundButtons)
        #expect(!general.translucentBackground)
        #expect(!general.alwaysOpenOnHover)
        #expect(general.disableHaptics)
        #expect(general.contentPadding == 12)
        #expect(general.notchFineTune == .zero)
        #expect(general.handlerSize == CGSize(width: 184, height: 8))
        #expect(!general.handlerEnabled)
        #expect(!general.demoMode)
    }

    @Test func liveActivityDefaultsMatchPRD() {
        let liveActivities = SettingsStore(defaults: defaults).liveActivities

        #expect(liveActivities.inactivityTimeout == 10)
        #expect(liveActivities.enabledKinds == [.media, .filesTray, .newUpdate])
        #expect(liveActivities.visibleInFullscreen == Set(LiveActivityKind.allCases))
        #expect(liveActivities.mediaEffect == .spectrograph)
        #expect(liveActivities.albumCornerRadius == 5)
    }

    @Test func nookDefaultsEnableMediaMirrorAndNotes() {
        let nook = SettingsStore(defaults: defaults).nook

        #expect(nook.enabledWidgets.map(\.kind) == [.mediaPlayer, .mirror, .notes])
        #expect(nook.enabledWidgets.map(\.width) == [5, 2, 5])
        #expect(nook.daysBehind == 7 && nook.daysAhead == 7)
    }

    @Test func eyeAndPetAreOffByDefault() {
        let settings = SettingsStore(defaults: defaults)

        #expect(!settings.eye.isEnabled)
        #expect(!settings.pet.isEnabled)
        #expect(settings.pet.type == nil)
        #expect(settings.shelf.trayWidth == 11 && settings.shelf.dropAreaWidth == 11)
    }

    @Test func changesPersistAcrossStores() {
        let settings = SettingsStore(defaults: defaults)
        settings.general.alwaysOpenOnHover = true
        settings.general.showInFullscreen = .never
        settings.liveActivities.enabledKinds = [.battery]
        settings.pet.type = .blob

        let reloaded = SettingsStore(defaults: defaults)

        #expect(reloaded.general.alwaysOpenOnHover)
        #expect(reloaded.general.showInFullscreen == .never)
        #expect(reloaded.liveActivities.enabledKinds == [.battery])
        #expect(reloaded.pet.type == .blob)
    }

    @Test func resetRestoresDefaultsButKeepsMarkersAndPetType() {
        let settings = SettingsStore(defaults: defaults)
        settings.general.alwaysOpenOnHover = true
        settings.general.hasAppliedLaunchAtLoginDefault = true
        settings.pet.type = .cat
        settings.nook.widgets.reverse()

        settings.resetToDefaults()

        #expect(!settings.general.alwaysOpenOnHover)
        #expect(settings.general.hasAppliedLaunchAtLoginDefault)
        #expect(settings.pet.type == .cat)
        #expect(settings.nook.widgets == NookSettings.defaultWidgets)
    }

    @Test func storedWidgetListGainsNewKindsAtTheEnd() {
        let stored = [NookWidgetPlacement(kind: .timer, isEnabled: true, width: 3)]

        let completed = NookSettings.completed(stored)

        #expect(completed.first == stored.first)
        #expect(Set(completed.map(\.kind)) == Set(NookWidgetKind.allCases))
    }
}
