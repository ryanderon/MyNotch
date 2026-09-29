import AppKit
import Observation

/// Tracks whether the user can see the screen at all (not asleep, not locked), so animations,
/// the Eye's mouse monitor, and the Pet can shut down completely while nobody is looking.
@Observable
final class SessionMonitor {
    private(set) var isAsleep = false
    private(set) var isLocked = false

    var isUserPresent: Bool { !isAsleep && !isLocked }

    /// Lets the Pet react to the Mac going to sleep and waking up.
    @ObservationIgnored var systemWillSleep: (() -> Void)?
    @ObservationIgnored var systemDidWake: (() -> Void)?

    @ObservationIgnored private var tokens: [NSObjectProtocol] = []

    func start() {
        guard tokens.isEmpty else { return }
        observeWorkspace(NSWorkspace.willSleepNotification) { $0.isAsleep = true; $0.systemWillSleep?() }
        observeWorkspace(NSWorkspace.screensDidSleepNotification) { $0.isAsleep = true }
        observeWorkspace(NSWorkspace.didWakeNotification) { $0.isAsleep = false; $0.systemDidWake?() }
        observeWorkspace(NSWorkspace.screensDidWakeNotification) { $0.isAsleep = false }
        // Lock state has no public NSWorkspace notification; these distributed notifications are posted by loginwindow.
        observeDistributed("com.apple.screenIsLocked") { $0.isLocked = true }
        observeDistributed("com.apple.screenIsUnlocked") { $0.isLocked = false }
    }

    private func observeWorkspace(_ name: Notification.Name, update: @escaping (SessionMonitor) -> Void) {
        let token = NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) {
            [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                update(self)
            }
        }
        tokens.append(token)
    }

    private func observeDistributed(_ name: String, update: @escaping (SessionMonitor) -> Void) {
        let token = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(name), object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                update(self)
            }
        }
        tokens.append(token)
    }
}
