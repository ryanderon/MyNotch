import Foundation
import Testing
@testable import MyNotch

@MainActor
struct JSONFileStoreTests {
    private struct Sample: Codable, Equatable {
        let title: String
        let date: Date
    }

    private let store = JSONFileStore<Sample>(
        fileURL: FileManager.default.temporaryDirectory.appending(path: "MyNotchTests-\(UUID().uuidString).json")
    )

    @Test func missingFileLoadsAsNil() throws {
        #expect(try store.load() == nil)
    }

    @Test func savedValueRoundTrips() throws {
        let sample = Sample(title: "Groceries", date: Date(timeIntervalSince1970: 1_700_000_000))

        try store.save(sample)

        #expect(try store.load() == sample)
        try FileManager.default.removeItem(at: store.fileURL)
    }

    @Test func corruptFileThrowsInsteadOfReturningEmptyData() throws {
        try Data("not json".utf8).write(to: store.fileURL)

        #expect(throws: DecodingError.self) { try store.load() }
        try FileManager.default.removeItem(at: store.fileURL)
    }
}
