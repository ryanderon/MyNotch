import Foundation
import Observation

struct TodoItem: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var isDone: Bool
}

/// Local-only to-dos, stored as JSON in Application Support.
@Observable
final class TodoStore {
    private(set) var items: [TodoItem]

    @ObservationIgnored private let document: LocalDocument<[TodoItem]>

    init(document: LocalDocument<[TodoItem]>) {
        self.document = document
        items = document.load(default: [])
    }

    var remainingCount: Int { items.filter { !$0.isDone }.count }

    func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(TodoItem(id: UUID(), title: trimmed, isDone: false))
        document.scheduleSave(items)
    }

    func toggle(_ id: TodoItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isDone.toggle()
        document.scheduleSave(items)
    }

    func delete(_ id: TodoItem.ID) {
        items.removeAll { $0.id == id }
        document.scheduleSave(items)
    }

    func flushPendingSave() {
        document.flush()
    }

    func clearCompleted() {
        items.removeAll(where: \.isDone)
        document.scheduleSave(items)
    }
}
