import Foundation

enum ShortcutsRunnerError: Error {
    case failed(exitCode: Int32)
}

/// Runs Apple Shortcuts through the system `shortcuts` command-line tool (macOS 12+), off the main thread.
nonisolated enum ShortcutsRunner {
    private static let executableURL = URL(filePath: "/usr/bin/shortcuts")

    static func run(named name: String) async throws {
        _ = try await execute(arguments: ["run", name])
    }

    static func availableShortcuts() async throws -> [String] {
        let output = try await execute(arguments: ["list"])
        return output
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.isEmpty }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private static func execute(arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { finished in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if finished.terminationStatus == 0 {
                    continuation.resume(returning: String(decoding: data, as: UTF8.self))
                } else {
                    continuation.resume(throwing: ShortcutsRunnerError.failed(exitCode: finished.terminationStatus))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
