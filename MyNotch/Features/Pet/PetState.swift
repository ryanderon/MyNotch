import Foundation

/// A stat that changes linearly with time from its last recorded value. Nothing ever ticks it:
/// its current value is computed on demand from the timestamp (lazy decay).
struct PetStat: Codable, Equatable {
    static let range: ClosedRange<Double> = 0...100

    var baseline: Double
    var updatedAt: Date

    func value(at date: Date, changePerHour: Double) -> Double {
        let hours = max(date.timeIntervalSince(updatedAt), 0) / 3600
        return (baseline + changePerHour * hours).clamped(to: Self.range)
    }

    /// When a decaying stat will reach `threshold`; nil if it is already there or never will.
    func date(reaching threshold: Double, from date: Date, changePerHour: Double) -> Date? {
        let current = value(at: date, changePerHour: changePerHour)
        guard changePerHour < 0, current > threshold else { return nil }
        return date.addingTimeInterval((current - threshold) / -changePerHour * 3600)
    }

    /// When the stat hit (or will hit) zero; nil if it never empties.
    func emptyDate(changePerHour: Double) -> Date? {
        guard baseline > 0 else { return updatedAt }
        guard changePerHour < 0 else { return nil }
        return updatedAt.addingTimeInterval(baseline / -changePerHour * 3600)
    }

    mutating func add(_ amount: Double, at date: Date, changePerHour: Double) {
        baseline = (value(at: date, changePerHour: changePerHour) + amount).clamped(to: Self.range)
        updatedAt = date
    }
}

enum PetMood: Equatable {
    case happy
    case content
    case hungry
    case sad
    case sleeping
    case dancing
    case ranAway
}

/// Everything the pet remembers between launches. Pure: every rule takes the current date as input.
struct PetState: Codable, Equatable {
    enum Rate {
        static let hunger = -8.0
        static let happiness = -5.0
        static let energyAwake = -6.0
        static let energyAsleep = 20.0
    }

    /// Neglect never kills the pet; after this long with an empty stomach and no fun, it wanders off.
    static let runAwayDelay: TimeInterval = 12 * 3600
    static let hungryThreshold = 25.0

    var hunger: PetStat
    var happiness: PetStat
    var energy: PetStat
    var sleepingSince: Date?
    var adoptedAt: Date
    var careDays: Set<String>

    static func newborn(at date: Date) -> PetState {
        let full = PetStat(baseline: 80, updatedAt: date)
        return PetState(hunger: full, happiness: full, energy: full, sleepingSince: nil, adoptedAt: date, careDays: [])
    }

    var isSleeping: Bool { sleepingSince != nil }

    private var energyRate: Double { isSleeping ? Rate.energyAsleep : Rate.energyAwake }

    func hungerLevel(at date: Date) -> Double { hunger.value(at: date, changePerHour: Rate.hunger) }
    func happinessLevel(at date: Date) -> Double { happiness.value(at: date, changePerHour: Rate.happiness) }
    func energyLevel(at date: Date) -> Double { energy.value(at: date, changePerHour: energyRate) }

    /// Grows with regular care: one level for every three distinct days the pet was fed or played with.
    var level: Int { careDays.count / 3 + 1 }

    func hasRunAway(at date: Date) -> Bool {
        guard let hungerEmpty = hunger.emptyDate(changePerHour: Rate.hunger),
              let happinessEmpty = happiness.emptyDate(changePerHour: Rate.happiness) else {
            return false
        }
        return date.timeIntervalSince(max(hungerEmpty, happinessEmpty)) >= Self.runAwayDelay
    }

    func mood(at date: Date, isMusicPlaying: Bool) -> PetMood {
        if hasRunAway(at: date) { return .ranAway }
        if isSleeping { return .sleeping }
        if isMusicPlaying { return .dancing }
        let hunger = hungerLevel(at: date)
        let happiness = happinessLevel(at: date)
        if hunger < Self.hungryThreshold { return .hungry }
        if happiness < 20 || energyLevel(at: date) < 10 { return .sad }
        return hunger > 60 && happiness > 60 ? .happy : .content
    }

    /// The one moment a "pet is hungry" notification should be scheduled for, if any.
    func hungerAlertDate(from date: Date) -> Date? {
        hunger.date(reaching: Self.hungryThreshold, from: date, changePerHour: Rate.hunger)
    }

    // MARK: Actions

    /// Feeding also calls a runaway pet back home.
    mutating func feed(at date: Date) {
        if hasRunAway(at: date) {
            happiness = PetStat(baseline: 30, updatedAt: date)
        }
        hunger.add(35, at: date, changePerHour: Rate.hunger)
        recordCare(on: date)
    }

    mutating func play(at date: Date, reward: Double) {
        happiness.add(reward, at: date, changePerHour: Rate.happiness)
        energy.add(-10, at: date, changePerHour: energyRate)
        recordCare(on: date)
    }

    mutating func pet(at date: Date) {
        happiness.add(5, at: date, changePerHour: Rate.happiness)
    }

    mutating func listenToMusic(at date: Date) {
        happiness.add(2, at: date, changePerHour: Rate.happiness)
    }

    mutating func fallAsleep(at date: Date) {
        guard !isSleeping else { return }
        energy.add(0, at: date, changePerHour: Rate.energyAwake)
        sleepingSince = date
    }

    mutating func wakeUp(at date: Date) {
        guard isSleeping else { return }
        energy.add(0, at: date, changePerHour: Rate.energyAsleep)
        sleepingSince = nil
    }

    private mutating func recordCare(on date: Date) {
        careDays.insert(date.formatted(.iso8601.year().month().day()))
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
