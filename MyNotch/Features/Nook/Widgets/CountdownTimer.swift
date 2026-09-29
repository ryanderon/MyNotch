import AppKit
import Observation

/// The Timer widget's model. Exactly one system timer exists, and only while a countdown is running:
/// it fires once at the end date instead of ticking every second. The widget shows the remaining time
/// with a TimelineView that exists only while the nook is open.
@Observable
final class CountdownTimer {
    enum State: Equatable {
        case idle
        case running(endDate: Date)
        case paused(remaining: TimeInterval)
    }

    static let presetMinutes = [1, 5, 10, 15, 25, 45]

    private(set) var state: State = .idle
    private(set) var duration: TimeInterval = 5 * 60

    @ObservationIgnored var didFinish: (() -> Void)?
    @ObservationIgnored private var completionTimer: Timer?

    func start(minutes: Int) {
        duration = TimeInterval(minutes * 60)
        run(for: duration)
    }

    func pause() {
        guard case .running(let endDate) = state else { return }
        cancelCompletionTimer()
        state = .paused(remaining: max(endDate.timeIntervalSinceNow, 0))
    }

    func resume() {
        guard case .paused(let remaining) = state else { return }
        run(for: remaining)
    }

    func reset() {
        cancelCompletionTimer()
        state = .idle
    }

    func remaining(at date: Date) -> TimeInterval {
        switch state {
        case .idle: duration
        case .running(let endDate): max(endDate.timeIntervalSince(date), 0)
        case .paused(let remaining): remaining
        }
    }

    private func run(for interval: TimeInterval) {
        cancelCompletionTimer()
        state = .running(endDate: Date().addingTimeInterval(interval))
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.finish() }
        }
        // A timer alarm should be punctual, so tolerance stays small (still lets the system coalesce).
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        completionTimer = timer
    }

    private func finish() {
        completionTimer = nil
        state = .idle
        NSSound(named: "Glass")?.play()
        didFinish?()
    }

    private func cancelCompletionTimer() {
        completionTimer?.invalidate()
        completionTimer = nil
    }
}
