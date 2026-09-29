import Foundation
import Testing
@testable import MyNotch

@MainActor
final class TestClock {
    var now = Date(timeIntervalSince1970: 1_000_000)

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}

@MainActor
struct ActivityCoordinatorTests {
    private let settings: SettingsStore
    private let clock: TestClock
    private let coordinator: ActivityCoordinator
    private let charging = LiveActivity.battery(BatteryEvent(level: 80, isCharging: true, reason: .pluggedIn))

    init() throws {
        let clock = TestClock()
        self.clock = clock
        settings = SettingsStore(defaults: try makeIsolatedDefaults())
        coordinator = ActivityCoordinator(settings: settings) { clock.now }
    }

    @Test func startsClosed() {
        #expect(coordinator.presentation == .closed)
        #expect(!coordinator.isPointerInside)
    }

    @Test func openAndCloseNook() {
        coordinator.open()
        #expect(coordinator.presentation == .open(.nook))

        coordinator.close()
        #expect(coordinator.presentation == .closed)
    }

    @Test func disabledNookIgnoresOpenButTrayStillOpens() {
        settings.nook.isEnabled = false

        coordinator.open()
        #expect(coordinator.presentation == .closed)

        coordinator.open(.tray)
        #expect(coordinator.presentation == .open(.tray))
    }

    @Test func hoverOpensOnlyWhenOpenOnHoverIsOn() {
        coordinator.pointerEntered()
        #expect(coordinator.presentation == .closed)
        #expect(coordinator.isPointerInside)

        coordinator.pointerExited()
        settings.general.alwaysOpenOnHover = true
        coordinator.pointerEntered()
        #expect(coordinator.presentation == .open(.nook))
    }

    @Test func pointerExitCloses() {
        coordinator.pointerEntered()
        coordinator.open()

        coordinator.pointerExited()

        #expect(coordinator.presentation == .closed)
    }

    @Test func typingKeepsNotchOpenWhenPreventCloseIsOn() {
        settings.general.preventCloseWhileTyping = true
        coordinator.pointerEntered()
        coordinator.open()
        coordinator.typingBegan()

        coordinator.pointerExited()
        #expect(coordinator.presentation == .open(.nook))

        coordinator.typingEnded()
        #expect(coordinator.presentation == .closed)
    }

    @Test func typingLockKeepsNotchOpenUntilExplicitClose() {
        settings.general.preventCloseWhileTyping = true
        settings.general.lockWhileTyping = true
        coordinator.open()
        coordinator.typingBegan()
        coordinator.typingEnded()

        coordinator.pointerExited()
        #expect(coordinator.presentation == .open(.nook))

        coordinator.close()
        #expect(coordinator.presentation == .closed)
    }

    @Test func dragShowsDropAreaOverEverything() {
        coordinator.open()

        coordinator.dragEntered()
        #expect(coordinator.presentation == .dropArea)

        coordinator.dragExited()
        #expect(coordinator.presentation == .open(.nook))
    }

    @Test func disabledActivityKindIsIgnored() {
        coordinator.post(charging, lifetime: .transient)

        #expect(coordinator.presentation == .closed)
    }

    @Test func transientActivityExpiresAfterInactivityTimeout() {
        settings.liveActivities.enabledKinds.insert(.battery)
        coordinator.post(charging, lifetime: .transient)
        #expect(coordinator.presentation == .liveActivity(charging))

        clock.advance(by: 10)
        coordinator.settingsDidChange()

        #expect(coordinator.presentation == .closed)
    }

    @Test func swipedAwayActivityComesBackOnNewEventWhenAutoUnhideIsOn() {
        coordinator.post(.media, lifetime: .ongoing)
        coordinator.hideVisibleActivity()
        #expect(coordinator.presentation == .closed)

        coordinator.post(.media, lifetime: .ongoing)

        #expect(coordinator.presentation == .liveActivity(.media))
    }

    @Test func swipedAwayActivityPeeksOnHover() {
        settings.liveActivities.unhideAutomatically = false
        coordinator.post(.media, lifetime: .ongoing)
        coordinator.hideVisibleActivity()

        coordinator.pointerEntered()

        #expect(coordinator.presentation == .liveActivity(.media))
    }

    @Test func fullscreenOnlyShowsAllowedKinds() {
        settings.liveActivities.visibleInFullscreen = [.filesTray]
        coordinator.post(.media, lifetime: .ongoing)

        coordinator.updateScreen(ScreenContext(hasNotch: true, isFullscreenActive: true))

        #expect(coordinator.presentation == .closed)
    }

    @Test func nonNotchedScreenCanHideActivities() {
        settings.liveActivities.hideOnNonNotched = true
        coordinator.post(.media, lifetime: .ongoing)

        coordinator.updateScreen(ScreenContext(hasNotch: false, isFullscreenActive: false))

        #expect(coordinator.presentation == .closed)
    }

    @Test func tapOnInteractiveActivityRequestsItsAction() {
        var requested: LiveActivity?
        coordinator.activityActionRequested = { requested = $0 }
        coordinator.post(.media, lifetime: .ongoing)

        coordinator.activityTapped()

        #expect(requested == .media)
    }

    @Test func tapOnNonInteractiveActivityOpensNook() {
        settings.liveActivities.isInteractive = false
        coordinator.post(.media, lifetime: .ongoing)

        coordinator.activityTapped()

        #expect(coordinator.presentation == .open(.nook))
    }
}
