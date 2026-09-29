import SwiftUI

struct TodosWidget: View {
    @Environment(AppModel.self) private var model
    @State private var draft = ""
    @FocusState private var isAdding: Bool

    var body: some View {
        let todos = model.todos
        VStack(spacing: 4) {
            HStack {
                WidgetTitle(text: "To-dos · \(todos.remainingCount) left")
                if todos.items.contains(where: \.isDone) {
                    Button("Clear done", action: todos.clearCompleted)
                        .font(.system(size: 9))
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(todos.items) { item in
                        TodoRow(item: item, todos: todos)
                    }
                }
            }
            .scrollIndicators(.never)
            TextField("Add a to-do", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
                .focused($isAdding)
                .reportsTyping(isAdding, to: model.coordinator)
                .onSubmit {
                    todos.add(title: draft)
                    draft = ""
                }
        }
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let todos: TodoStore
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            Button { todos.toggle(item.id) } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? .green : .white.opacity(0.7))
            }
            .buttonStyle(.plain)
            Text(item.title)
                .font(.system(size: 12))
                .strikethrough(item.isDone)
                .foregroundStyle(.white.opacity(item.isDone ? 0.45 : 1))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if isHovering {
                Button { todos.delete(item.id) } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .font(.system(size: 11))
        .onHover { isHovering = $0 }
    }
}
