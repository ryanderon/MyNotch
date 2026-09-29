import Foundation
import Observation
import OSLog

struct TrayItem: Codable, Identifiable, Equatable {
    let id: UUID
    /// A bookmark instead of a path, so a file that is moved or renamed is still found; no file data is kept.
    let bookmark: Data
    let displayName: String
    let addedAt: Date
}

/// The temporary file shelf. Persisted as JSON so the tray survives relaunches.
@Observable
final class TrayStore {
    private(set) var items: [TrayItem]

    @ObservationIgnored var itemCountDidChange: ((Int) -> Void)?
    @ObservationIgnored private let document: LocalDocument<[TrayItem]>

    init(document: LocalDocument<[TrayItem]>) {
        self.document = document
        items = document.load(default: [])
    }

    func add(_ urls: [URL]) {
        let existingURLs = Set(items.compactMap { resolvedURL(for: $0)?.standardizedFileURL })
        let newItems = urls
            .filter { !existingURLs.contains($0.standardizedFileURL) }
            .compactMap { Self.makeItem(for: $0) }
        guard !newItems.isEmpty else { return }
        items.append(contentsOf: newItems)
        itemsDidChange()
    }

    func remove(_ id: TrayItem.ID) {
        items.removeAll { $0.id == id }
        itemsDidChange()
    }

    func removeAll() {
        items.removeAll()
        itemsDidChange()
    }

    func flushPendingSave() {
        document.flush()
    }

    /// Nil when the file was deleted since it was added.
    func resolvedURL(for item: TrayItem) -> URL? {
        var isStale = false
        do {
            return try URL(resolvingBookmarkData: item.bookmark, options: [.withoutUI], bookmarkDataIsStale: &isStale)
        } catch {
            Logger.persistence.info("Tray item no longer resolves: \(item.displayName, privacy: .public)")
            return nil
        }
    }

    private func itemsDidChange() {
        document.scheduleSave(items)
        itemCountDidChange?(items.count)
    }

    private static func makeItem(for url: URL) -> TrayItem? {
        do {
            let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            return TrayItem(id: UUID(), bookmark: bookmark, displayName: url.lastPathComponent, addedAt: Date())
        } catch {
            let fileName = url.lastPathComponent
            Logger.persistence.error(
                "Could not bookmark \(fileName, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }
}
