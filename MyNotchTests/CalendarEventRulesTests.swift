import CoreGraphics
import Foundation
import Testing
@testable import MyNotch

@MainActor
struct CalendarEventRulesTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    /// 2026-09-30 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_790_769_600)

    private func event(
        _ id: String,
        startOffsetHours: Double,
        durationHours: Double = 1,
        isAllDay: Bool = false,
        calendarID: String = "work"
    ) -> CalendarEventItem {
        let start = now.addingTimeInterval(startOffsetHours * 3600)
        return CalendarEventItem(
            id: id, title: id, startDate: start, endDate: start.addingTimeInterval(durationHours * 3600),
            isAllDay: isAllDay, calendarID: calendarID, calendarColor: CGColor(gray: 1, alpha: 1)
        )
    }

    private func options(
        excluded: Set<String> = [],
        pastToday: Bool = false,
        allDay: Bool = false,
        multiDay: Bool = false
    ) -> CalendarFilterOptions {
        CalendarFilterOptions(
            excludedCalendarIDs: excluded, showPastEventsToday: pastToday, showAllDayEvents: allDay,
            showMultiDayEvents: multiDay, daysBehind: 7, daysAhead: 7
        )
    }

    @Test func fetchIntervalCoversDaysBehindAndAhead() {
        let interval = CalendarEventRules.fetchInterval(around: now, options: options(), calendar: calendar)

        #expect(interval.start == calendar.startOfDay(for: now).addingTimeInterval(-7 * 86_400))
        #expect(interval.end == calendar.startOfDay(for: now).addingTimeInterval(8 * 86_400))
    }

    @Test func pastEventsTodayAreHiddenByDefault() {
        let events = [event("morning", startOffsetHours: -3), event("later", startOffsetHours: 2)]

        let visible = CalendarEventRules.visibleEvents(events, now: now, options: options(), calendar: calendar)
        let withPast = CalendarEventRules.visibleEvents(events, now: now, options: options(pastToday: true), calendar: calendar)

        #expect(visible.map(\.id) == ["later"])
        #expect(withPast.map(\.id) == ["morning", "later"])
    }

    @Test func allDayAndMultiDayEventsAreOptIn() {
        let events = [
            event("holiday", startOffsetHours: 12, durationHours: 24, isAllDay: true),
            event("trip", startOffsetHours: 1, durationHours: 50)
        ]

        #expect(CalendarEventRules.visibleEvents(events, now: now, options: options(), calendar: calendar).isEmpty)
        let everything = options(allDay: true, multiDay: true)
        #expect(CalendarEventRules.visibleEvents(events, now: now, options: everything, calendar: calendar).count == 2)
    }

    @Test func excludedCalendarsAreHidden() {
        let events = [event("a", startOffsetHours: 1), event("b", startOffsetHours: 2, calendarID: "home")]

        let visible = CalendarEventRules.visibleEvents(events, now: now, options: options(excluded: ["home"]), calendar: calendar)

        #expect(visible.map(\.id) == ["a"])
    }

    @Test func reminderFiresFiveMinutesBeforeNextEvent() throws {
        let events = [event("later", startOffsetHours: 3), event("soon", startOffsetHours: 1)]

        let reminder = try #require(CalendarEventRules.nextReminder(
            in: events, now: now, excludedCalendarIDs: [], alreadyAnnounced: []
        ))

        #expect(reminder.event.id == "soon")
        #expect(reminder.fireDate == now.addingTimeInterval(3600 - 300))
    }

    @Test func imminentEventFiresImmediatelyAndAnnouncedOnesAreSkipped() throws {
        let events = [event("now", startOffsetHours: 0.02), event("next", startOffsetHours: 2)]

        let immediate = try #require(CalendarEventRules.nextReminder(
            in: events, now: now, excludedCalendarIDs: [], alreadyAnnounced: []
        ))
        let afterAnnouncing = CalendarEventRules.nextReminder(
            in: events, now: now, excludedCalendarIDs: [], alreadyAnnounced: ["now"]
        )

        #expect(immediate.fireDate == now)
        #expect(afterAnnouncing?.event.id == "next")
    }
}
