import Foundation
import OSLog

/// A JSON file plus the policy every local store shares: load once, fall back to a default without losing
/// an unreadable file, and coalesce rapid edits (typing) into one write.
final class LocalDocument<Value: Codable> {
    private static var saveDelay: Duration { .milliseconds(600) }

    private let store: JSONFileStore<Value>
    private var pendingSave: Task<Void, Never>?
    private var pendingValue: Value?

    init(store: JSONFileStore<Value>) {
        self.store = store
    }

    convenience init(fileName: String) {
        self.init(store: JSONFileStore(fileName: fileName))
    }

    func load(default defaultValue: Value) -> Value {
        do {
            return try store.load() ?? defaultValue
        } catch {
            logFailure("Unreadable", error: error)
            moveAsideUnreadableFile()
            return defaultValue
        }
    }

    /// The pending write is replaced by each new edit, so a burst of keystrokes costs a single disk write.
    func scheduleSave(_ value: Value) {
        pendingSave?.cancel()
        pendingValue = value
        pendingSave = Task { [weak self] in
            do {
                try await Task.sleep(for: Self.saveDelay)
            } catch {
                return // Cancelled: a newer edit scheduled its own save.
            }
            self?.saveNow(value)
        }
    }

    /// Writes a scheduled save immediately (app is quitting or the module is being turned off).
    func flush() {
        guard let pendingValue else { return }
        saveNow(pendingValue)
    }

    func saveNow(_ value: Value) {
        pendingSave?.cancel()
        pendingSave = nil
        pendingValue = nil
        do {
            try store.save(value)
        } catch {
            logFailure("Could not save", error: error)
        }
    }

    private func moveAsideUnreadableFile() {
        do {
            try store.moveAsideUnreadableFile()
        } catch {
            logFailure("Could not back up unreadable", error: error)
        }
    }

    private func logFailure(_ message: String, error: Error) {
        let fileName = store.fileURL.lastPathComponent
        Logger.persistence.error(
            "\(message, privacy: .public) \(fileName, privacy: .public): \(error.localizedDescription, privacy: .public)"
        )
    }
}
