import Foundation

/// Reads and writes one Codable value as a JSON file in Application Support, so user data (notes, to-dos,
/// tray, pet) stays local and in an open format.
struct JSONFileStore<Value: Codable> {
    let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    init(fileName: String) {
        fileURL = URL.applicationSupportDirectory
            .appending(path: "MyNotch", directoryHint: .isDirectory)
            .appending(path: fileName)
    }

    /// Returns nil when nothing has been saved yet; a file that exists but can't be decoded throws.
    func load() throws -> Value? {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder.fileStore.decode(Value.self, from: data)
    }

    func save(_ value: Value) throws {
        let data = try JSONEncoder.fileStore.encode(value)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    /// Keeps an unreadable file next to the original instead of letting the next save overwrite it.
    func moveAsideUnreadableFile() throws {
        let backupURL = fileURL.appendingPathExtension("unreadable-\(Int(Date().timeIntervalSince1970))")
        try FileManager.default.moveItem(at: fileURL, to: backupURL)
    }
}

private extension JSONEncoder {
    static let fileStore: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

private extension JSONDecoder {
    static let fileStore: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
