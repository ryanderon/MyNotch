import Observation

/// Battery and Bluetooth feed live activities only. Each service is installed only while its activity kind
/// is enabled, so a disabled activity has no listener at all.
final class SystemActivitySources {
    private let coordinator: ActivityCoordinator
    private let liveActivities: LiveActivitySettings
    private let power = PowerService()
    private let bluetooth = BluetoothService()
    private var batteryDetector = BatteryEventDetector()

    /// Lives for the app's lifetime and only wakes when the enabled activity kinds change.
    private var settingsObservation: Task<Void, Never>?

    init(coordinator: ActivityCoordinator, liveActivities: LiveActivitySettings) {
        self.coordinator = coordinator
        self.liveActivities = liveActivities
    }

    func start() {
        power.snapshotDidChange = { [weak self] snapshot in self?.powerDidChange(snapshot) }
        bluetooth.deviceEventDidOccur = { [weak self] event in
            self?.coordinator.post(.bluetooth(event), lifetime: .transient)
        }
        let liveActivities = liveActivities
        settingsObservation = Task { [weak self] in
            for await _ in Observations({ [liveActivities.isKindEnabled(.battery), liveActivities.isKindEnabled(.bluetooth)] }) {
                self?.updateRunningServices()
            }
        }
    }

    private func updateRunningServices() {
        if liveActivities.isKindEnabled(.battery) {
            power.start()
        } else {
            power.stop()
            batteryDetector = BatteryEventDetector()
        }
        if liveActivities.isKindEnabled(.bluetooth) {
            bluetooth.start()
        } else {
            bluetooth.stop()
        }
    }

    private func powerDidChange(_ snapshot: PowerSourceSnapshot) {
        batteryDetector.consume(snapshot)
        guard let event = batteryDetector.event else { return }
        coordinator.post(.battery(event), lifetime: .transient)
    }
}
