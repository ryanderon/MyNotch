import Foundation
import IOKit.ps
import OSLog

struct PowerSourceSnapshot: Equatable {
    let level: Int
    let isCharging: Bool
    let isOnACPower: Bool
}

/// Wraps IOKit power-source notifications: the system calls us when the charger or battery level changes,
/// so there is no polling. Only runs while the Battery live activity is enabled.
final class PowerService {
    var snapshotDidChange: ((PowerSourceSnapshot) -> Void)?

    private var runLoopSource: CFRunLoopSource?

    var isRunning: Bool { runLoopSource != nil }

    func start() {
        guard runLoopSource == nil else { return }
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            let service = Unmanaged<PowerService>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { service.publishCurrentSnapshot() }
        }
        guard let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() else {
            Logger.services.error("Could not create the power source run loop source")
            return
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        runLoopSource = source
        publishCurrentSnapshot()
    }

    func stop() {
        guard let runLoopSource else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        self.runLoopSource = nil
    }

    private func publishCurrentSnapshot() {
        guard let snapshot = Self.currentSnapshot() else { return }
        snapshotDidChange?(snapshot)
    }

    /// Nil on Macs without an internal battery.
    static func currentSnapshot() -> PowerSourceSnapshot? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue()
                    as? [String: Any],
                  description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType else {
                continue
            }
            let current = description[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maximum = max(description[kIOPSMaxCapacityKey] as? Int ?? 100, 1)
            return PowerSourceSnapshot(
                level: current * 100 / maximum,
                isCharging: description[kIOPSIsChargingKey] as? Bool ?? false,
                isOnACPower: description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
            )
        }
        return nil
    }
}
