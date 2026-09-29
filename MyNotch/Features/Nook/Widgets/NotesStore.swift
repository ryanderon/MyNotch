import Foundation
import Observation

struct Note: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    var updatedAt: Date
}

/// Lightweight local notes, stored as JSON in Application Support. Loaded on first use.
@Observable
final class NotesStore {
    private(set) var notes: [Note]
    private(set) var selectedIndex = 0

    @ObservationIgnored private let document: LocalDocument<[Note]>

    init(document: LocalDocument<[Note]>) {
        self.document = document
        let loaded = document.load(default: [])
        notes = loaded.isEmpty ? [Self.emptyNote()] : loaded
    }

    var selectedNote: Note { notes[selectedIndex] }

    var canSelectPrevious: Bool { selectedIndex > 0 }
    var canSelectNext: Bool { selectedIndex < notes.count - 1 }

    func updateSelectedText(_ text: String) {
        guard notes[selectedIndex].text != text else { return }
        notes[selectedIndex].text = text
        notes[selectedIndex].updatedAt = Date()
        document.scheduleSave(notes)
    }

    func addNote() {
        notes.append(Self.emptyNote())
        selectedIndex = notes.count - 1
        document.scheduleSave(notes)
    }

    /// The last note is cleared instead of removed, so the widget always has a page to type on.
    func deleteSelectedNote() {
        if notes.count == 1 {
            notes[0] = Self.emptyNote()
        } else {
            notes.remove(at: selectedIndex)
            selectedIndex = min(selectedIndex, notes.count - 1)
        }
        document.scheduleSave(notes)
    }

    func flushPendingSave() {
        document.flush()
    }

    func selectPrevious() {
        selectedIndex = max(selectedIndex - 1, 0)
    }

    func selectNext() {
        selectedIndex = min(selectedIndex + 1, notes.count - 1)
    }

    private static func emptyNote() -> Note {
        Note(id: UUID(), text: "", updatedAt: Date())
    }
}
