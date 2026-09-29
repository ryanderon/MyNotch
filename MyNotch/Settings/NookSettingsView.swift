import SwiftUI

struct NookSettingsView: View {
    @Bindable var nook: NookSettings

    var body: some View {
        Form {
            Section {
                NookPreview(nook: nook)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
            Section {
                Toggle("Enable nook", isOn: $nook.isEnabled)
                Toggle("Show dividers between widgets", isOn: $nook.showDividers)
            } footer: {
                Text("When the nook is off, clicking the notch does nothing.")
            }
            WidgetListSection(nook: nook)
            CalendarOptionsSection(nook: nook)
            ShortcutsSelectionSection(nook: nook)
        }
        .formStyle(.grouped)
    }
}

private struct WidgetListSection: View {
    @Bindable var nook: NookSettings

    var body: some View {
        Section {
            List {
                ForEach($nook.widgets) { $placement in
                    HStack {
                        Image(systemName: "line.3.horizontal").foregroundStyle(.tertiary)
                        Toggle(isOn: $placement.isEnabled) {
                            Label(placement.kind.title, systemImage: placement.kind.systemImage)
                        }
                        Spacer()
                        Stepper(value: $placement.width, in: NookWidgetPlacement.widthRange) {
                            Text("\(placement.width) cells").monospacedDigit().foregroundStyle(.secondary)
                        }
                        .fixedSize()
                    }
                }
                .onMove { nook.widgets.move(fromOffsets: $0, toOffset: $1) }
            }
            .frame(minHeight: 230)
        } header: {
            Text("Widgets")
        } footer: {
            Text("Drag to reorder.")
        }
    }
}

private struct CalendarOptionsSection: View {
    @Environment(AppModel.self) private var model
    @Bindable var nook: NookSettings

    var body: some View {
        Section("Calendar") {
            Stepper(value: $nook.daysBehind, in: NookSettings.dayRange) {
                LabeledContent("Days behind", value: "\(nook.daysBehind)")
            }
            Stepper(value: $nook.daysAhead, in: NookSettings.dayRange) {
                LabeledContent("Days ahead", value: "\(nook.daysAhead)")
            }
            Toggle("Show past events today", isOn: $nook.showPastEventsToday)
            Toggle("Show all-day events", isOn: $nook.showAllDayEvents)
            Toggle("Show multi-day events", isOn: $nook.showMultiDayEvents)
            ForEach(model.calendar.calendars) { source in
                Toggle(isOn: inclusion(of: source.id)) {
                    Label {
                        Text(source.title)
                    } icon: {
                        Circle().fill(Color(cgColor: source.color)).frame(width: 9, height: 9)
                    }
                }
            }
            if model.calendar.calendars.isEmpty {
                Text("Enable the Calendar widget or live activity to choose calendars.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func inclusion(of calendarID: String) -> Binding<Bool> {
        Binding(
            get: { !nook.excludedCalendarIDs.contains(calendarID) },
            set: { isIncluded in
                if isIncluded {
                    nook.excludedCalendarIDs.remove(calendarID)
                } else {
                    nook.excludedCalendarIDs.insert(calendarID)
                }
            }
        )
    }
}

private struct ShortcutsSelectionSection: View {
    @Bindable var nook: NookSettings
    @State private var availableShortcuts: [String] = []
    @State private var loadError: String?

    var body: some View {
        Section("Shortcuts") {
            if let loadError {
                Text(loadError).foregroundStyle(.secondary)
            }
            ForEach(availableShortcuts, id: \.self) { name in
                Toggle(name, isOn: selection(of: name))
            }
        }
        .task { await loadShortcuts() }
    }

    private func loadShortcuts() async {
        do {
            availableShortcuts = try await ShortcutsRunner.availableShortcuts()
            loadError = availableShortcuts.isEmpty ? "No shortcuts found in the Shortcuts app." : nil
        } catch {
            loadError = "Couldn't read your shortcuts."
        }
    }

    private func selection(of name: String) -> Binding<Bool> {
        Binding(
            get: { nook.shortcutNames.contains(name) },
            set: { isSelected in
                if isSelected {
                    nook.shortcutNames.append(name)
                } else {
                    nook.shortcutNames.removeAll { $0 == name }
                }
            }
        )
    }
}

/// A scaled-down sketch of the open nook: widget blocks at their cell widths, so reordering and resizing
/// can be judged without creating the real widgets (and without opening the camera).
private struct NookPreview: View {
    let nook: NookSettings
    private let scale: CGFloat = 0.5

    var body: some View {
        HStack(spacing: nook.showDividers ? NotchLayout.dividerWidth * scale : 0) {
            ForEach(nook.enabledWidgets) { placement in
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.12))
                    .overlay {
                        Image(systemName: placement.kind.systemImage)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(width: CGFloat(placement.width) * NotchLayout.cellWidth * scale)
            }
        }
        .frame(height: NotchLayout.contentHeight * scale)
        .padding(10)
        .background(UnevenRoundedRectangle(bottomLeadingRadius: 14, bottomTrailingRadius: 14).fill(.black))
    }
}
