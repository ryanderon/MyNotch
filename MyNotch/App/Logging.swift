import OSLog

extension Logger {
    private static let subsystem = "io.github.ryanderon.MyNotch"

    static let app = Logger(subsystem: subsystem, category: "App")
    static let settings = Logger(subsystem: subsystem, category: "Settings")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let services = Logger(subsystem: subsystem, category: "Services")
}
