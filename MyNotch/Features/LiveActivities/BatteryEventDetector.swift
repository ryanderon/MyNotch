/// Turns a stream of power snapshots into the three moments worth a live activity:
/// charger plugged in, charger unplugged, and battery running low (once per discharge).
struct BatteryEventDetector {
    static let lowBatteryLevel = 20

    private(set) var event: BatteryEvent?
    private var previous: PowerSourceSnapshot?
    private var hasWarnedLow = false

    mutating func consume(_ snapshot: PowerSourceSnapshot) {
        event = nil
        defer { previous = snapshot }
        if snapshot.isOnACPower {
            hasWarnedLow = false
        }
        // The first snapshot only establishes a baseline; launching the app is not a charger event.
        guard let previous else { return }
        if snapshot.isOnACPower && !previous.isOnACPower {
            event = BatteryEvent(level: snapshot.level, isCharging: snapshot.isCharging, reason: .pluggedIn)
        } else if !snapshot.isOnACPower && previous.isOnACPower {
            event = BatteryEvent(level: snapshot.level, isCharging: false, reason: .unplugged)
        } else if !snapshot.isOnACPower && snapshot.level <= Self.lowBatteryLevel && !hasWarnedLow {
            hasWarnedLow = true
            event = BatteryEvent(level: snapshot.level, isCharging: false, reason: .low)
        }
    }
}
