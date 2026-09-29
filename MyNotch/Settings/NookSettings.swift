import Foundation
import Observation

enum NookWidgetKind: String, Codable, CaseIterable, Identifiable {
    case mediaPlayer
    case mirror
    case notes
    case calendar
    case shortcuts
    case todos
    case timer

    var id: Self { self }

    var title: String {
        switch self {
        case .mediaPlayer: "Media Player"
        case .mirror: "Mirror"
        case .notes: "Notes"
        case .calendar: "Calendar"
        case .shortcuts: "Shortcuts"
        case .todos: "To-dos"
        case .timer: "Timer"
        }
    }

    var systemImage: String {
        switch self {
        case .mediaPlayer: "music.note"
        case .mirror: "camera"
        case .notes: "note.text"
        case .calendar: "calendar"
        case .shortcuts: "square.stack.3d.up"
        case .todos: "checklist"
        case .timer: "timer"
        }
    }

    var defaultWidth: Int {
        switch self {
        case .mediaPlayer, .notes, .calendar: 5
        case .shortcuts, .todos: 4
        case .timer: 3
        case .mirror: 2
        }
    }
}

struct NookWidgetPlacement: Codable, Equatable, Identifiable {
    static let widthRange = 2...8

    let kind: NookWidgetKind
    var isEnabled: Bool
    var width: Int

    var id: NookWidgetKind { kind }
}

@Observable
final class NookSettings {
    static let dayRange = 0...30

    static let defaultWidgets: [NookWidgetPlacement] = NookWidgetKind.allCases.map { kind in
        let enabledByDefault: Set<NookWidgetKind> = [.mediaPlayer, .mirror, .notes]
        return NookWidgetPlacement(kind: kind, isEnabled: enabledByDefault.contains(kind), width: kind.defaultWidth)
    }

    private enum Keys {
        static let isEnabled = SettingKey(name: "nook.enabled", defaultValue: true)
        static let showDividers = SettingKey(name: "nook.showDividers", defaultValue: true)
        static let widgets = SettingKey(name: "nook.widgets", defaultValue: NookSettings.defaultWidgets)
        static let excludedCalendarIDs = SettingKey(name: "nook.calendar.excludedCalendarIDs", defaultValue: Set<String>())
        static let showPastEventsToday = SettingKey(name: "nook.calendar.showPastToday", defaultValue: false)
        static let showAllDayEvents = SettingKey(name: "nook.calendar.allDay", defaultValue: false)
        static let showMultiDayEvents = SettingKey(name: "nook.calendar.multiDay", defaultValue: false)
        static let daysBehind = SettingKey(name: "nook.calendar.daysBehind", defaultValue: 7)
        static let daysAhead = SettingKey(name: "nook.calendar.daysAhead", defaultValue: 7)
        static let shortcutNames = SettingKey(name: "nook.shortcuts.names", defaultValue: [String]())
    }

    @ObservationIgnored private let defaults: UserDefaults

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, for: Keys.isEnabled) }
    }
    var showDividers: Bool {
        didSet { defaults.set(showDividers, for: Keys.showDividers) }
    }
    var widgets: [NookWidgetPlacement] {
        didSet { defaults.setEncoded(widgets, for: Keys.widgets) }
    }

    /// Stored as exclusions so "all calendars" stays the default and newly added calendars show up automatically.
    var excludedCalendarIDs: Set<String> {
        didSet { defaults.setEncoded(excludedCalendarIDs, for: Keys.excludedCalendarIDs) }
    }
    var showPastEventsToday: Bool {
        didSet { defaults.set(showPastEventsToday, for: Keys.showPastEventsToday) }
    }
    var showAllDayEvents: Bool {
        didSet { defaults.set(showAllDayEvents, for: Keys.showAllDayEvents) }
    }
    var showMultiDayEvents: Bool {
        didSet { defaults.set(showMultiDayEvents, for: Keys.showMultiDayEvents) }
    }
    var daysBehind: Int {
        didSet { defaults.set(daysBehind, for: Keys.daysBehind) }
    }
    var daysAhead: Int {
        didSet { defaults.set(daysAhead, for: Keys.daysAhead) }
    }
    var shortcutNames: [String] {
        didSet { defaults.setEncoded(shortcutNames, for: Keys.shortcutNames) }
    }

    var enabledWidgets: [NookWidgetPlacement] {
        widgets.filter(\.isEnabled)
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        isEnabled = defaults.value(for: Keys.isEnabled)
        showDividers = defaults.value(for: Keys.showDividers)
        widgets = Self.completed(defaults.decodedValue(for: Keys.widgets))
        excludedCalendarIDs = defaults.decodedValue(for: Keys.excludedCalendarIDs)
        showPastEventsToday = defaults.value(for: Keys.showPastEventsToday)
        showAllDayEvents = defaults.value(for: Keys.showAllDayEvents)
        showMultiDayEvents = defaults.value(for: Keys.showMultiDayEvents)
        daysBehind = defaults.value(for: Keys.daysBehind)
        daysAhead = defaults.value(for: Keys.daysAhead)
        shortcutNames = defaults.decodedValue(for: Keys.shortcutNames)
    }

    func isWidgetEnabled(_ kind: NookWidgetKind) -> Bool {
        isEnabled && widgets.contains { $0.kind == kind && $0.isEnabled }
    }

    func resetToDefaults() {
        isEnabled = Keys.isEnabled.defaultValue
        showDividers = Keys.showDividers.defaultValue
        widgets = Keys.widgets.defaultValue
        excludedCalendarIDs = Keys.excludedCalendarIDs.defaultValue
        showPastEventsToday = Keys.showPastEventsToday.defaultValue
        showAllDayEvents = Keys.showAllDayEvents.defaultValue
        showMultiDayEvents = Keys.showMultiDayEvents.defaultValue
        daysBehind = Keys.daysBehind.defaultValue
        daysAhead = Keys.daysAhead.defaultValue
        shortcutNames = Keys.shortcutNames.defaultValue
    }

    /// Keeps the stored order but appends widget kinds added in a later version, so none silently disappear.
    static func completed(_ stored: [NookWidgetPlacement]) -> [NookWidgetPlacement] {
        let storedKinds = Set(stored.map(\.kind))
        return stored + defaultWidgets.filter { !storedKinds.contains($0.kind) }
    }
}
