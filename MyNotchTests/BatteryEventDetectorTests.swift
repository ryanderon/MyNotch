import Testing
@testable import MyNotch

@MainActor
struct BatteryEventDetectorTests {
    private func snapshot(_ level: Int, onAC: Bool) -> PowerSourceSnapshot {
        PowerSourceSnapshot(level: level, isCharging: onAC, isOnACPower: onAC)
    }

    @Test func firstSnapshotIsOnlyABaseline() {
        var detector = BatteryEventDetector()
        detector.consume(snapshot(50, onAC: true))
        #expect(detector.event == nil)
    }

    @Test func pluggingInAndUnplugging() {
        var detector = BatteryEventDetector()
        detector.consume(snapshot(50, onAC: false))

        detector.consume(snapshot(50, onAC: true))
        #expect(detector.event?.reason == .pluggedIn)

        detector.consume(snapshot(51, onAC: false))
        #expect(detector.event?.reason == .unplugged)
    }

    @Test func lowBatteryWarnsOncePerDischarge() {
        var detector = BatteryEventDetector()
        detector.consume(snapshot(22, onAC: false))

        detector.consume(snapshot(20, onAC: false))
        #expect(detector.event?.reason == .low)

        detector.consume(snapshot(19, onAC: false))
        #expect(detector.event == nil)
    }

    @Test func chargingResetsLowWarning() {
        var detector = BatteryEventDetector()
        detector.consume(snapshot(21, onAC: false))
        detector.consume(snapshot(20, onAC: false))
        detector.consume(snapshot(20, onAC: true))
        detector.consume(snapshot(20, onAC: false))

        detector.consume(snapshot(19, onAC: false))

        #expect(detector.event?.reason == .low)
    }

    @Test func levelChangesWithoutPowerChangeAreSilent() {
        var detector = BatteryEventDetector()
        detector.consume(snapshot(80, onAC: false))
        detector.consume(snapshot(79, onAC: false))
        #expect(detector.event == nil)
    }
}
