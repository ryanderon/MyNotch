import EventKit
import Observation
import OSLog

struct CalendarSource: Equatable, Identifiable {
    let id: String
    let title: String
    let color: CGColor
}

enum CalendarAccess: Equatable {
    case unknown
    case granted
    case denied
}

/// EventKit wrapper. Events are re-read only when EventKit reports a change (`EKEventStoreChanged`)
/// or the widget's date range changes; the live activity uses one timer aimed at the next event,
/// never periodic polling. The event store only exists while the Calendar widget or activity is on.
@Observable
final class CalendarService {
    private(set) var access = CalendarAccess.unknown
    private(set) var events: [CalendarEventItem] = []
    private(set) var calendars: [CalendarSource] = []

    @ObservationIgnored var eventIsStartingSoon: ((UpcomingEvent) -> Void)?

    @ObservationIgnored private let nook: NookSettings
    @ObservationIgnored private var store: EKEventStore?
    @ObservationIgnored private var changeObserver: NSObjectProtocol?
    @ObservationIgnored private var reminderTimer: Timer?
    @ObservationIgnored private var announcedEventIDs: Set<String> = []

    init(nook: NookSettings) {
        self.nook = nook
    }

    var isRunning: Bool { store != nil }

    func start() {
        guard store == nil else { return }
        let store = EKEventStore()
        self.store = store
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        }
        Task { await requestAccessAndLoad(store) }
    }

    func stop() {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
        changeObserver = nil
        reminderTimer?.invalidate()
        reminderTimer = nil
        store = nil
        events = []
        calendars = []
    }

    func reload() {
        guard let store, access == .granted else { return }
        let interval = CalendarEventRules.fetchInterval(
            around: Date(),
            options: CalendarFilterOptions(nook: nook),
            calendar: .current
        )
        let predicate = store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: nil)
        events = store.events(matching: predicate).map { CalendarEventItem(event: $0) }
        calendars = store.calendars(for: .event).map { CalendarSource(calendar: $0) }
        scheduleNextReminder()
    }

    private func requestAccessAndLoad(_ store: EKEventStore) async {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            access = .granted
        case .notDetermined:
            do {
                access = try await store.requestFullAccessToEvents() ? .granted : .denied
            } catch {
                Logger.services.error("Calendar access request failed: \(error.localizedDescription, privacy: .public)")
                access = .denied
            }
        default:
            access = .denied
        }
        reload()
    }

    private func scheduleNextReminder() {
        reminderTimer?.invalidate()
        reminderTimer = nil
        let now = Date()
        guard let reminder = CalendarEventRules.nextReminder(
            in: events,
            now: now,
            excludedCalendarIDs: nook.excludedCalendarIDs,
            alreadyAnnounced: announcedEventIDs
        ) else { return }
        let interval = max(reminder.fireDate.timeIntervalSince(now), 0.1)
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.announce(reminder.event) }
        }
        timer.tolerance = min(max(interval * 0.1, 1), 30)
        RunLoop.main.add(timer, forMode: .common)
        reminderTimer = timer
    }

    private func announce(_ event: CalendarEventItem) {
        announcedEventIDs.insert(event.id)
        eventIsStartingSoon?(UpcomingEvent(title: event.title, startDate: event.startDate))
        scheduleNextReminder()
    }
}

private extension CalendarEventItem {
    init(event: EKEvent) {
        self.init(
            id: "\(event.eventIdentifier ?? UUID().uuidString)-\(event.startDate.timeIntervalSince1970)",
            title: event.title ?? "Untitled",
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay,
            calendarID: event.calendar.calendarIdentifier,
            calendarColor: event.calendar.cgColor
        )
    }
}

private extension CalendarSource {
    init(calendar: EKCalendar) {
        self.init(id: calendar.calendarIdentifier, title: calendar.title, color: calendar.cgColor)
    }
}
