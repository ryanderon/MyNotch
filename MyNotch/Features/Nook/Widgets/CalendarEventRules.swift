import CoreGraphics
import Foundation

struct CalendarEventItem: Equatable, Identifiable {
    /// Recurring events share an identifier, so the occurrence's start date is part of the ID.
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarID: String
    let calendarColor: CGColor
}

struct CalendarFilterOptions: Equatable {
    let excludedCalendarIDs: Set<String>
    let showPastEventsToday: Bool
    let showAllDayEvents: Bool
    let showMultiDayEvents: Bool
    let daysBehind: Int
    let daysAhead: Int
}

struct CalendarReminder: Equatable {
    let event: CalendarEventItem
    let fireDate: Date
}

/// Pure calendar rules shared by the widget and the live activity.
enum CalendarEventRules {
    /// The live activity appears this long before an event starts.
    static let reminderLeadTime: TimeInterval = 5 * 60

    static func fetchInterval(around now: Date, options: CalendarFilterOptions, calendar: Calendar) -> DateInterval {
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -options.daysBehind, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: options.daysAhead + 1, to: today) ?? today
        return DateInterval(start: start, end: max(end, start))
    }

    static func visibleEvents(
        _ events: [CalendarEventItem],
        now: Date,
        options: CalendarFilterOptions,
        calendar: Calendar
    ) -> [CalendarEventItem] {
        events
            .filter { isVisible($0, now: now, options: options, calendar: calendar) }
            .sorted { $0.startDate < $1.startDate }
    }

    static func nextReminder(
        in events: [CalendarEventItem],
        now: Date,
        excludedCalendarIDs: Set<String>,
        alreadyAnnounced: Set<String>
    ) -> CalendarReminder? {
        events
            .filter { event in
                !event.isAllDay && event.startDate > now
                    && !excludedCalendarIDs.contains(event.calendarID)
                    && !alreadyAnnounced.contains(event.id)
            }
            .min { $0.startDate < $1.startDate }
            .map { CalendarReminder(event: $0, fireDate: max(now, $0.startDate.addingTimeInterval(-reminderLeadTime))) }
    }

    private static func isVisible(
        _ event: CalendarEventItem,
        now: Date,
        options: CalendarFilterOptions,
        calendar: Calendar
    ) -> Bool {
        if options.excludedCalendarIDs.contains(event.calendarID) { return false }
        if event.isAllDay && !options.showAllDayEvents { return false }
        if isMultiDay(event, calendar: calendar) && !options.showMultiDayEvents { return false }
        let isPastToday = event.endDate <= now && calendar.isDate(event.startDate, inSameDayAs: now)
        return !isPastToday || options.showPastEventsToday
    }

    private static func isMultiDay(_ event: CalendarEventItem, calendar: Calendar) -> Bool {
        // An event ending exactly at midnight still belongs to its start day.
        !calendar.isDate(event.startDate, inSameDayAs: event.endDate.addingTimeInterval(-1))
    }
}

extension CalendarFilterOptions {
    init(nook: NookSettings) {
        self.init(
            excludedCalendarIDs: nook.excludedCalendarIDs,
            showPastEventsToday: nook.showPastEventsToday,
            showAllDayEvents: nook.showAllDayEvents,
            showMultiDayEvents: nook.showMultiDayEvents,
            daysBehind: nook.daysBehind,
            daysAhead: nook.daysAhead
        )
    }
}
