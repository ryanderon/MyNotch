import Foundation

/// Pure bookkeeping of which live activities exist, which the user swiped away, and when transient ones expire.
/// Time is always passed in, so the rules are deterministic and testable.
struct LiveActivityBoard: Equatable {
    private struct Entry: Equatable {
        let activity: LiveActivity
        let expiresAt: Date?
    }

    private var entries: [LiveActivityKind: Entry] = [:]
    private var hiddenKinds: Set<LiveActivityKind> = []
    private var peekDeadlines: [LiveActivityKind: Date] = [:]

    var isEmpty: Bool { entries.isEmpty }

    /// `expiresAt == nil` means the activity lasts until it is removed (media playing, files in the tray).
    mutating func show(_ activity: LiveActivity, expiresAt: Date?) {
        entries[activity.kind] = Entry(activity: activity, expiresAt: expiresAt)
    }

    mutating func remove(_ kind: LiveActivityKind) {
        entries[kind] = nil
        hiddenKinds.remove(kind)
        peekDeadlines[kind] = nil
    }

    mutating func hide(_ kind: LiveActivityKind) {
        guard entries[kind] != nil else { return }
        hiddenKinds.insert(kind)
        peekDeadlines[kind] = nil
    }

    mutating func unhide(_ kind: LiveActivityKind) {
        hiddenKinds.remove(kind)
    }

    /// Briefly shows a hidden activity (e.g. a song change) without un-hiding it for good.
    mutating func peek(_ kind: LiveActivityKind, until deadline: Date) {
        guard hiddenKinds.contains(kind) else { return }
        peekDeadlines[kind] = deadline
    }

    mutating func removeExpired(now: Date) {
        for (kind, entry) in entries where entry.expiresAt.map({ $0 <= now }) == true {
            remove(kind)
        }
        peekDeadlines = peekDeadlines.filter { $0.value > now }
    }

    func isHidden(_ kind: LiveActivityKind) -> Bool {
        hiddenKinds.contains(kind)
    }

    /// Highest-priority activity the user hasn't swiped away (or that is currently peeking).
    func visibleActivity(now: Date, allowedKinds: Set<LiveActivityKind>) -> LiveActivity? {
        highestPriority(now: now, allowedKinds: allowedKinds) { kind in
            !hiddenKinds.contains(kind) || peekDeadlines[kind].map { $0 > now } == true
        }
    }

    /// Used by Quick Peek: while hovering, swiped-away activities count too.
    func anyActivity(now: Date, allowedKinds: Set<LiveActivityKind>) -> LiveActivity? {
        highestPriority(now: now, allowedKinds: allowedKinds) { _ in true }
    }

    /// The single moment the coordinator must wake up next; nil means no timer is needed at all.
    var nextDeadline: Date? {
        let expiries = entries.values.compactMap(\.expiresAt)
        return (expiries + peekDeadlines.values).min()
    }

    private func highestPriority(
        now: Date,
        allowedKinds: Set<LiveActivityKind>,
        where isVisible: (LiveActivityKind) -> Bool
    ) -> LiveActivity? {
        entries.values
            .filter { entry in
                allowedKinds.contains(entry.activity.kind)
                    && entry.expiresAt.map { $0 > now } != false
                    && isVisible(entry.activity.kind)
            }
            .max { $0.activity.kind.priority < $1.activity.kind.priority }?
            .activity
    }
}
