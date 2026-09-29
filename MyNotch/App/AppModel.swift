import AppKit
import Observation

/// The pet and its sprites exist together, only while Pet is enabled; dropping this releases both.
struct PetCompanion {
    let store: PetStore
    let sprites: PetSpriteSheet
}

/// Owns every long-lived object and wires events into the coordinator. Views receive it through the environment.
@Observable
final class AppModel {
    let settings: SettingsStore
    let coordinator: ActivityCoordinator
    let session = SessionMonitor()
    let media = MediaService()
    let countdown = CountdownTimer()
    let calendar: CalendarService
    let tray: TrayStore

    private(set) var placement: NotchPlacement?
    var petCompanion: PetCompanion?

    /// False while the panel is fully covered (e.g. by a fullscreen app); animations stop when false.
    var isPanelVisible = false

    @ObservationIgnored var openSettings: () -> Void = {}
    @ObservationIgnored let updater = UpdaterService()
    @ObservationIgnored let trayThumbnails = TrayThumbnailCache()
    @ObservationIgnored lazy var eyeTracker = EyeTracker(settings: settings.eye) { [weak self] in
        self?.isNotchVisibleToUser ?? false
    }
    @ObservationIgnored lazy var notes = NotesStore(document: LocalDocument(fileName: "notes.json"))
    @ObservationIgnored lazy var todos = TodoStore(document: LocalDocument(fileName: "todos.json"))
    @ObservationIgnored let petDocument = LocalDocument<PetState>(fileName: "pet.json")

    @ObservationIgnored private let screenObserver = ScreenObserver()
    @ObservationIgnored private let systemActivitySources: SystemActivitySources
    @ObservationIgnored var lifecycleObservations: [Task<Void, Never>] = []

    init(settings: SettingsStore) {
        self.settings = settings
        coordinator = ActivityCoordinator(settings: settings)
        calendar = CalendarService(nook: settings.nook)
        tray = TrayStore(document: LocalDocument(fileName: "tray.json"))
        systemActivitySources = SystemActivitySources(coordinator: coordinator, liveActivities: settings.liveActivities)
    }

    var layout: NotchLayout? {
        placement.map { NotchLayout(notchSize: $0.geometry.notchFrame.size, settings: settings) }
    }

    /// Animations, the Eye, and the Pet only run while this is true.
    var isNotchVisibleToUser: Bool {
        placement != nil && isPanelVisible && session.isUserPresent
    }

    func start() {
        session.start()
        screenObserver.screensDidChange = { [weak self] in self?.updatePlacement() }
        screenObserver.start()
        updatePlacement()
        connectEvents()
        systemActivitySources.start()
        eyeTracker.start()
        updater.start()
        startLifecycleObservations()
        trayCountDidChange(tray.items.count)
    }

    func updatePlacement() {
        let resolved = NotchPlacement.resolve(
            screens: screenObserver.currentScreens(),
            rules: NotchPlacementRules(general: settings.general)
        )
        if resolved != placement {
            placement = resolved
        }
        coordinator.updateScreen(ScreenContext(
            hasNotch: resolved?.geometry.kind == .notch,
            isFullscreenActive: resolved?.isFullscreenActive ?? false
        ))
    }

    /// Writes any debounced edits before the app quits.
    func flushPendingSaves() {
        notes.flushPendingSave()
        todos.flushPendingSave()
        tray.flushPendingSave()
        petCompanion?.store.flushPendingSave()
    }

    // MARK: Actions

    func perform(_ command: MediaCommand) {
        media.perform(command)
    }

    func addToTray(_ urls: [URL]) {
        tray.add(urls)
        petCompanion?.store.fileWasDropped()
    }

    func removeFromTray(_ id: TrayItem.ID) {
        tray.remove(id)
        trayThumbnails.removeThumbnail(for: id)
    }

    func clearTray() {
        tray.items.forEach { trayThumbnails.removeThumbnail(for: $0.id) }
        tray.removeAll()
    }

    /// The AirDrop picker belongs to this app, which is never frontmost on its own.
    func sendViaAirDrop(_ urls: [URL]) {
        guard !urls.isEmpty, let service = NSSharingService(named: .sendViaAirDrop) else { return }
        NSApplication.shared.activate()
        service.perform(withItems: urls)
        petCompanion?.store.fileWasDropped()
    }

    // MARK: Event wiring

    private func connectEvents() {
        let coordinator = coordinator
        coordinator.activityActionRequested = { [weak self] activity in self?.performAction(for: activity) }
        media.playbackDidChange = { update in
            switch update {
            case .playing: coordinator.post(.media, lifetime: .ongoing)
            case .paused: coordinator.post(.media, lifetime: .transient)
            case .stopped: coordinator.end(.media)
            }
        }
        media.trackDidChange = { [weak self] in
            coordinator.mediaTrackChanged()
            self?.petCompanion?.store.musicTrackDidChange()
        }
        countdown.didFinish = { coordinator.post(.timerEnded, lifetime: .transient) }
        calendar.eventIsStartingSoon = { coordinator.post(.calendar($0), lifetime: .transient) }
        updater.updateFound = { coordinator.post(.newUpdate(version: $0), lifetime: .ongoing) }
        tray.itemCountDidChange = { [weak self] in self?.trayCountDidChange($0) }
        session.systemWillSleep = { [weak self] in self?.petCompanion?.store.macWillSleep() }
        session.systemDidWake = { [weak self] in self?.petCompanion?.store.macDidWake() }
        eyeTracker.glanceTarget = { [weak self] in self?.petWingCenter }
    }

    private func performAction(for activity: LiveActivity) {
        switch activity {
        case .media:
            perform(.playPause)
        case .filesTray:
            coordinator.open(.tray)
        case .calendar:
            coordinator.open()
        case .newUpdate:
            coordinator.end(.newUpdate)
            updater.checkForUpdates()
        case .bluetooth, .battery, .timerEnded:
            coordinator.end(activity.kind)
        }
    }

    private func trayCountDidChange(_ count: Int) {
        if count > 0 {
            coordinator.post(.filesTray(itemCount: count), lifetime: .ongoing)
        } else {
            coordinator.end(.filesTray)
        }
    }

    /// Where the eyes glance when they look at the pet: the middle of the right wing.
    private var petWingCenter: CGPoint? {
        guard petCompanion != nil, let frame = placement?.geometry.notchFrame else { return nil }
        return CGPoint(x: frame.maxX + NotchLayout.companionWingWidth / 2, y: frame.midY)
    }
}

extension NotchPlacementRules {
    init(general: GeneralSettings) {
        self.init(
            fullscreenVisibility: general.showInFullscreen,
            isHandlerEnabled: general.handlerEnabled,
            handlerSize: general.handlerSize,
            notchFineTune: general.notchFineTune
        )
    }
}

extension NotchLayout {
    init(notchSize: CGSize, settings: SettingsStore) {
        let hasPet = settings.pet.activeType != nil
        self.init(
            notchSize: notchSize,
            contentPadding: CGFloat(settings.general.contentPadding),
            nookWidgetWidths: settings.nook.enabledWidgets.map(\.width) + (hasPet ? [PetLayout.cardWidth] : []),
            showsDividers: settings.nook.showDividers,
            trayWidth: settings.shelf.trayWidth,
            dropAreaWidth: settings.shelf.dropAreaWidth,
            hasCompanionWings: settings.eye.isShownWhenClosed || hasPet
        )
    }
}
