import SwiftUI

struct CalendarWidget: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let calendarService = model.calendar
        VStack(spacing: 4) {
            WidgetTitle(text: Date().formatted(.dateTime.weekday(.wide).month().day()))
            switch calendarService.access {
            case .unknown:
                ProgressView().controlSize(.small).frame(maxHeight: .infinity)
            case .denied:
                WidgetMessage(
                    systemImage: "calendar.badge.exclamationmark",
                    message: "Allow calendar access in System Settings",
                    actionTitle: "Open Settings",
                    action: openPrivacySettings
                )
            case .granted:
                EventList(days: groupedEvents(calendarService.events))
            }
        }
    }

    private func groupedEvents(_ events: [CalendarEventItem]) -> [CalendarDay] {
        let visible = CalendarEventRules.visibleEvents(
            events,
            now: Date(),
            options: CalendarFilterOptions(nook: model.settings.nook),
            calendar: .current
        )
        let byDay = Dictionary(grouping: visible) { Calendar.current.startOfDay(for: $0.startDate) }
        return byDay.keys.sorted().map { CalendarDay(date: $0, events: byDay[$0] ?? []) }
    }

    private func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

private struct CalendarDay: Identifiable {
    let date: Date
    let events: [CalendarEventItem]

    var id: Date { date }

    var title: String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

private struct EventList: View {
    let days: [CalendarDay]

    var body: some View {
        if days.isEmpty {
            WidgetMessage(systemImage: "calendar", message: "No events")
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(days) { day in
                        Text(day.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        ForEach(day.events) { EventRow(event: $0) }
                    }
                }
            }
            .scrollIndicators(.never)
        }
    }
}

private struct EventRow: View {
    let event: CalendarEventItem

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(cgColor: event.calendarColor))
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Text(event.isAllDay ? "All day" : event.startDate.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .opacity(event.endDate < Date() ? 0.5 : 1)
    }
}
