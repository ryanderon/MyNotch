import SwiftUI

struct NotesWidget: View {
    @Environment(AppModel.self) private var model
    @FocusState private var isEditing: Bool

    var body: some View {
        let notes = model.notes
        VStack(spacing: 4) {
            NotesToolbar(notes: notes)
            TextEditor(text: Binding(get: { notes.selectedNote.text }, set: notes.updateSelectedText))
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                .focused($isEditing)
                .reportsTyping(isEditing, to: model.coordinator)
        }
    }
}

private struct NotesToolbar: View {
    let notes: NotesStore

    var body: some View {
        HStack(spacing: 4) {
            WidgetTitle(text: notes.notes.count > 1 ? "Notes \(notes.selectedIndex + 1)/\(notes.notes.count)" : "Notes")
            Button(action: notes.selectPrevious) { Image(systemName: "chevron.left") }
                .disabled(!notes.canSelectPrevious)
            Button(action: notes.selectNext) { Image(systemName: "chevron.right") }
                .disabled(!notes.canSelectNext)
            Button(action: notes.addNote) { Image(systemName: "plus") }
                .help("New note")
            Button(action: notes.deleteSelectedNote) { Image(systemName: "trash") }
                .help("Delete note")
        }
        .buttonStyle(NotchIconButtonStyle(size: 18))
    }
}
