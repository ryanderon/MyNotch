import Foundation
import Observation
import OSLog
import UserNotifications

/// A short one-off animation the pet plays in response to something.
enum PetReaction: Equatable {
    case eating
    case petted
    case startled
}

/// The living pet: its persisted state plus the actions from the nook card. Stats are computed on demand
/// from timestamps; the only scheduled thing is a system notification for "pet is hungry", never a timer.
@Observable
final class PetStore {
    private static let hungerNotificationID = "MyNotch.pet.hungry"

    private(set) var state: PetState
    private(set) var reaction: PetReaction?

    @ObservationIgnored private let document: LocalDocument<PetState>
    @ObservationIgnored private let settings: PetSettings
    @ObservationIgnored private var reactionReset: Task<Void, Never>?
    @ObservationIgnored private var fellAsleepWithMac = false

    init(document: LocalDocument<PetState>, settings: PetSettings) {
        self.document = document
        self.settings = settings
        state = document.load(default: .newborn(at: Date()))
    }

    func feed() {
        update { $0.feed(at: $1) }
        react(.eating)
    }

    func play(reward: Double) {
        update { $0.play(at: $1, reward: reward) }
        react(.petted)
    }

    func pet() {
        update { $0.pet(at: $1) }
        react(.petted)
    }

    func toggleSleep() {
        fellAsleepWithMac = false
        if state.isSleeping {
            update { $0.wakeUp(at: $1) }
        } else {
            update { $0.fallAsleep(at: $1) }
        }
    }

    func musicTrackDidChange() {
        update { $0.listenToMusic(at: $1) }
    }

    func fileWasDropped() {
        react(.startled)
    }

    /// The pet naps with the Mac, and wakes with it unless the user had put it to bed themselves.
    func macWillSleep() {
        guard !state.isSleeping else { return }
        fellAsleepWithMac = true
        update { $0.fallAsleep(at: $1) }
    }

    func macDidWake() {
        guard fellAsleepWithMac else { return }
        fellAsleepWithMac = false
        update { $0.wakeUp(at: $1) }
    }

    func requestNotificationPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            Logger.app.error("Notification permission failed: \(error.localizedDescription, privacy: .public)")
        }
        rescheduleHungerNotification()
    }

    /// Replaces any pending alert with one at the exact moment hunger crosses the threshold.
    func rescheduleHungerNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.hungerNotificationID])
        guard settings.isEnabled, settings.hungerNotifications, let type = settings.type,
              let alertDate = state.hungerAlertDate(from: Date()) else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your \(type.title.lowercased()) is hungry"
        content.body = "Open the notch and give it something to eat."
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(alertDate.timeIntervalSinceNow, 1), repeats: false)
        center.add(UNNotificationRequest(identifier: Self.hungerNotificationID, content: content, trigger: trigger))
    }

    func flushPendingSave() {
        document.flush()
    }

    func cancelHungerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.hungerNotificationID])
    }

    private func update(_ change: (inout PetState, Date) -> Void) {
        change(&state, Date())
        document.scheduleSave(state)
        rescheduleHungerNotification()
    }

    /// Reactions end on their own after a moment; the task is the stop point for the animation.
    private func react(_ newReaction: PetReaction) {
        reaction = newReaction
        reactionReset?.cancel()
        reactionReset = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(1.5))
            } catch {
                return // Replaced by a newer reaction.
            }
            self?.reaction = nil
        }
    }
}
