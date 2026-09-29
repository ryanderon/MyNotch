import AppKit
import OSLog
import QuickLookThumbnailing

/// Small QuickLook thumbnails, generated lazily when a tray tile appears. Kept in a bounded in-memory cache
/// and on disk (Caches), so reopening the tray never regenerates them.
final class TrayThumbnailCache {
    static let pixelSize = CGSize(width: 96, height: 96)

    private let memoryCache: NSCache<NSUUID, NSImage> = {
        let cache = NSCache<NSUUID, NSImage>()
        cache.countLimit = 60
        cache.totalCostLimit = 8 * 1024 * 1024
        return cache
    }()

    private let directory = URL.cachesDirectory.appending(path: "MyNotch/Thumbnails", directoryHint: .isDirectory)

    func thumbnail(for item: TrayItem, fileURL: URL) async -> NSImage? {
        let key = item.id as NSUUID
        if let cached = memoryCache.object(forKey: key) { return cached }
        let diskURL = directory.appending(path: "\(item.id.uuidString).png")
        if let image = NSImage(contentsOf: diskURL) {
            store(image, for: key)
            return image
        }
        guard let image = await generate(for: fileURL) else { return nil }
        store(image, for: key)
        writeToDisk(image, at: diskURL)
        return image
    }

    func removeThumbnail(for id: TrayItem.ID) {
        memoryCache.removeObject(forKey: id as NSUUID)
        let diskURL = directory.appending(path: "\(id.uuidString).png")
        do {
            if FileManager.default.fileExists(atPath: diskURL.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: diskURL)
            }
        } catch {
            Logger.persistence.error("Could not remove thumbnail: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func generate(for fileURL: URL) async -> NSImage? {
        let request = QLThumbnailGenerator.Request(
            fileAt: fileURL,
            size: Self.pixelSize,
            scale: 1,
            representationTypes: .all
        )
        do {
            return try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request).nsImage
        } catch {
            return NSWorkspace.shared.icon(forFile: fileURL.path(percentEncoded: false))
        }
    }

    private func store(_ image: NSImage, for key: NSUUID) {
        let cost = Int(Self.pixelSize.width * Self.pixelSize.height * 4)
        memoryCache.setObject(image, forKey: key, cost: cost)
    }

    private func writeToDisk(_ image: NSImage, at url: URL) {
        guard let tiff = image.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try png.write(to: url, options: .atomic)
        } catch {
            Logger.persistence.error("Could not cache thumbnail: \(error.localizedDescription, privacy: .public)")
        }
    }
}
