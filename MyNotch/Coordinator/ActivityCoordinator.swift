import Foundation
import Observation

/// Single source of truth for what the notch shows. Every event flows into this type,
/// and it decides the presentation; views and the window controller only react to it.
@Observable
final class ActivityCoordinator {
    private(set) var presentation: NotchPresentation = .closed
    private(set) var isPointerInside = false
    private(set) var isTyping = false

    /// Media play/pause, opening the updater, etc. are performed by the owner of the services.
    @ObservationIgnored var activityActionRequested: ((LiveActivity) -> Void)?

    private var openTab: NookTab?
    private var isDropTargeted = false
    private var isLockedOpen = false
    private var board = LiveActivityBoard()
    private var screen = ScreenContext()

    /// Only exists while a transient activity or peek is pending; fires once at the next deadline.
    @ObservationIgnored private var deadlineTimer: Timer?

    private let settings: SettingsStore
    private let now: () -> Date

    init(settings: SettingsStore, now: @escaping () -> Date = Date.init) {
        self.settings = settings
        self.now = now
    }

    // MARK: Opening and closing

    func open(_ tab: NookTab = .nook) {
        guard tab == .tray || settings.nook.isEnabled else { return }
        openTab = tab
        refresh()
    }

    /// An explicit close (swipe up, click on the close button) also releases the typing lock.
    func close() {
        isLockedOpen = false
        openTab = nil
        refresh()
    }

    func toggleOpen() {
        if presentation.isOpen {
            close()
        } else {
            open()
        }
    }

    // MARK: Pointer and typing

    func pointerEntered() {
        isPointerInside = true
        if settings.general.alwaysOpenOnHover {
            open()
        } else {
            refresh()
        }
    }

    func pointerExited() {
        isPointerInside = false
        closeUnlessHeldOpen()
    }

    func typingBegan() {
        isTyping = true
        if settings.general.isTypingLockActive {
            isLockedOpen = true
        }
    }

    func typingEnded() {
        isTyping = false
        if !isPointerInside {
            closeUnlessHeldOpen()
        }
    }

    // MARK: Drag and drop

    func dragEntered() {
        isDropTargeted = true
        refresh()
    }

    func dragExited() {
        isDropTargeted = false
        refresh()
    }

    // MARK: Live activities

    func post(_ activity: LiveActivity, lifetime: ActivityLifetime) {
        guard settings.liveActivities.isKindEnabled(activity.kind) else { return }
        if settings.liveActivities.unhideAutomatically {
            board.unhide(activity.kind)
        }
        board.show(activity, expiresAt: lifetime == .transient ? inactivityDeadline() : nil)
        refresh()
    }

    /// Song changes may briefly surface a swiped-away media activity (the "show song change" setting).
    func mediaTrackChanged() {
        guard settings.liveActivities.showSongChange else { return }
        board.peek(.media, until: inactivityDeadline())
        refresh()
    }

    func end(_ kind: LiveActivityKind) {
        board.remove(kind)
        refresh()
    }

    func hideVisibleActivity() {
        guard case .liveActivity(let activity) = presentation else { return }
        board.hide(activity.kind)
        refresh()
    }

    func activityTapped() {
        guard case .liveActivity(let activity) = presentation else {
            open()
            return
        }
        if settings.liveActivities.isInteractive {
            activityActionRequested?(activity)
        } else {
            open()
        }
    }

    // MARK: Environment

    func updateScreen(_ newScreen: ScreenContext) {
        guard newScreen != screen else { return }
        screen = newScreen
        refresh()
    }

    /// Re-evaluates after a settings change (enabled kinds, fullscreen rules) without any new event.
    func settingsDidChange() {
        refresh()
    }

    // MARK: Resolution

    private func closeUnlessHeldOpen() {
        let isHeldByTyping = isTyping && settings.general.preventCloseWhileTyping
        if isHeldByTyping || isLockedOpen {
            refresh()
        } else {
            openTab = nil
            refresh()
        }
    }

    private func refresh() {
        let currentTime = now()
        board.removeExpired(now: currentTime)
        let resolved = resolvePresentation(at: currentTime)
        if resolved != presentation {
            presentation = resolved
        }
        scheduleNextDeadline(from: currentTime)
    }

    private func resolvePresentation(at currentTime: Date) -> NotchPresentation {
        if isDropTargeted { return .dropArea }
        if let openTab { return .open(openTab) }
        if let activity = currentActivity(at: currentTime) { return .liveActivity(activity) }
        return .closed
    }

    private func currentActivity(at currentTime: Date) -> LiveActivity? {
        let liveSettings = settings.liveActivities
        guard liveSettings.isEnabled else { return nil }
        if !screen.hasNotch && liveSettings.hideOnNonNotched { return nil }
        let allowedKinds = screen.isFullscreenActive
            ? liveSettings.enabledKinds.intersection(liveSettings.visibleInFullscreen)
            : liveSettings.enabledKinds
        if let visible = board.visibleActivity(now: currentTime, allowedKinds: allowedKinds) {
            return visible
        }
        guard isPointerInside && liveSettings.quickPeek else { return nil }
        return board.anyActivity(now: currentTime, allowedKinds: allowedKinds)
    }

    private func inactivityDeadline() -> Date {
        now().addingTimeInterval(TimeInterval(settings.liveActivities.inactivityTimeout))
    }

    private func scheduleNextDeadline(from currentTime: Date) {
        deadlineTimer?.invalidate()
        deadlineTimer = nil
        guard let deadline = board.nextDeadline else { return }
        let interval = max(deadline.timeIntervalSince(currentTime), 0.05)
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        timer.tolerance = max(interval * 0.1, 0.1)
        RunLoop.main.add(timer, forMode: .common)
        deadlineTimer = timer
    }
}
