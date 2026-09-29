import Foundation

enum LiveActivityKind: String, Codable, CaseIterable, Identifiable {
    case media
    case filesTray
    case calendar
    case newUpdate
    case bluetooth
    case battery
    case timerEnded

    var id: Self { self }

    var title: String {
        switch self {
        case .media: "Media"
        case .filesTray: "Files Tray"
        case .calendar: "Calendar"
        case .newUpdate: "New Update"
        case .bluetooth: "Bluetooth"
        case .battery: "Battery"
        case .timerEnded: "Timer Ended"
        }
    }

    /// Short-lived alerts outrank ongoing state, so a charger event is never hidden behind music.
    var priority: Int {
        switch self {
        case .timerEnded: 7
        case .bluetooth: 6
        case .battery: 5
        case .newUpdate: 4
        case .calendar: 3
        case .media: 2
        case .filesTray: 1
        }
    }
}

struct UpcomingEvent: Equatable {
    let title: String
    let startDate: Date
}

struct BluetoothDeviceEvent: Equatable {
    enum DeviceKind: Equatable {
        case headphones
        case keyboard
        case mouse
        case other
    }

    let deviceName: String
    let deviceKind: DeviceKind
    let isConnected: Bool
}

struct BatteryEvent: Equatable {
    enum Reason: Equatable {
        case pluggedIn
        case unplugged
        case low
    }

    let level: Int
    let isCharging: Bool
    let reason: Reason
}

enum LiveActivity: Equatable {
    /// The media views read track details from MediaService directly, so the activity carries no payload.
    case media
    case filesTray(itemCount: Int)
    case calendar(UpcomingEvent)
    case newUpdate(version: String)
    case bluetooth(BluetoothDeviceEvent)
    case battery(BatteryEvent)
    case timerEnded

    var kind: LiveActivityKind {
        switch self {
        case .media: .media
        case .filesTray: .filesTray
        case .calendar: .calendar
        case .newUpdate: .newUpdate
        case .bluetooth: .bluetooth
        case .battery: .battery
        case .timerEnded: .timerEnded
        }
    }
}
