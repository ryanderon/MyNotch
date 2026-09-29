import AppKit
import Observation

/// Drives every visible eye. The global mouse monitor and the blink timer exist only while at least one eye
/// is on screen and the user can see it (not locked, asleep, or covered by a fullscreen app).
/// A still mouse costs nothing; a moving one is processed at most 30 times per second.
final class EyeTracker {
    private static let minimumUpdateInterval: TimeInterval = 1.0 / 30
    private static let blinkIntervalRange: ClosedRange<TimeInterval> = 2.5...6

    private let settings: EyeSettings
    private let isVisibleToUser: @MainActor @Sendable () -> Bool
    private var eyes: [ObjectIdentifier: EyeLayerView] = [:]
    private var mouseMonitor: Any?
    private var blinkTimer: Timer?
    private var lastUpdate: TimeInterval = 0
    private var lastCursorMove = Date()
    private var eyelidState = EyelidState.open

    /// Lives for the app's lifetime; wakes only when Eye is toggled or visibility (lock, sleep, occlusion) changes.
    private var visibilityObservation: Task<Void, Never>?

    /// Set when both Eye and Pet are on: the eyes occasionally glance toward the pet's wing.
    var glanceTarget: (() -> CGPoint?)?

    init(settings: EyeSettings, isVisibleToUser: @escaping @MainActor @Sendable () -> Bool) {
        self.settings = settings
        self.isVisibleToUser = isVisibleToUser
    }

    func start() {
        let settings = settings
        let isVisibleToUser = isVisibleToUser
        visibilityObservation = Task { [weak self] in
            for await _ in Observations({ settings.isEnabled && isVisibleToUser() }) {
                self?.updateMonitoring()
            }
        }
    }

    func register(_ eye: EyeLayerView) {
        eyes[ObjectIdentifier(eye)] = eye
        eye.setEyelid(eyelidState)
        updateMonitoring()
        pointEyes(at: NSEvent.mouseLocation)
    }

    func unregister(_ eye: EyeLayerView) {
        eyes[ObjectIdentifier(eye)] = nil
        updateMonitoring()
    }

    private func updateMonitoring() {
        if !eyes.isEmpty && settings.isEnabled && isVisibleToUser() {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
        guard mouseMonitor == nil else { return }
        // Mouse-moved events don't require Accessibility permission (only key events would).
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            let timestamp = event.timestamp
            MainActor.assumeIsolated { self?.cursorDidMove(at: timestamp) }
        }
        scheduleBlink()
    }

    private func stopMonitoring() {
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
        }
        mouseMonitor = nil
        blinkTimer?.invalidate()
        blinkTimer = nil
    }

    private func cursorDidMove(at timestamp: TimeInterval) {
        guard timestamp - lastUpdate >= Self.minimumUpdateInterval else { return }
        lastUpdate = timestamp
        lastCursorMove = Date()
        if eyelidState == .droopy {
            setEyelids(.open)
        }
        pointEyes(at: NSEvent.mouseLocation)
    }

    private func pointEyes(at target: CGPoint) {
        for eye in eyes.values {
            guard let center = eye.centerOnScreen else { continue }
            eye.movePupil(by: PupilMath.offset(eyeCenter: center, target: target, maxOffset: eye.maxPupilOffset))
        }
    }

    private func setEyelids(_ state: EyelidState) {
        guard state != eyelidState else { return }
        eyelidState = state
        eyes.values.forEach { $0.setEyelid(state) }
    }

    /// One randomized timer with generous tolerance; it also checks idleness, so no second timer is needed.
    private func scheduleBlink() {
        blinkTimer?.invalidate()
        let interval = TimeInterval.random(in: Self.blinkIntervalRange)
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.blinkTimerDidFire() }
        }
        timer.tolerance = interval * 0.2
        RunLoop.main.add(timer, forMode: .common)
        blinkTimer = timer
    }

    private func blinkTimerDidFire() {
        let idleSeconds = Date().timeIntervalSince(lastCursorMove)
        setEyelids(EyelidState.resolve(secondsSinceCursorMoved: idleSeconds, sleepsWhenIdle: settings.sleepsWhenIdle))
        if settings.blinks && eyelidState == .open {
            eyes.values.forEach { $0.blink() }
        }
        if idleSeconds > 3, Bool.random(), let petLocation = glanceTarget?() {
            pointEyes(at: petLocation)
        }
        scheduleBlink()
    }
}
