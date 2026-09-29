import Foundation
import Testing
@testable import MyNotch

@MainActor
struct PetStateTests {
    private let start = Date(timeIntervalSince1970: 1_790_769_600)

    private func hours(_ value: Double) -> Date {
        start.addingTimeInterval(value * 3600)
    }

    @Test func statsDecayLazilyFromTimestamps() {
        let pet = PetState.newborn(at: start)

        #expect(pet.hungerLevel(at: hours(5)) == 40)
        #expect(pet.happinessLevel(at: hours(4)) == 60)
        #expect(pet.energyLevel(at: hours(10)) == 20)
    }

    @Test func statsNeverGoBelowZeroOrAboveHundred() {
        var pet = PetState.newborn(at: start)
        #expect(pet.hungerLevel(at: hours(100)) == 0)

        pet.feed(at: start)
        pet.feed(at: start)
        #expect(pet.hungerLevel(at: start) == 100)
    }

    @Test func sleepingRestoresEnergy() {
        var pet = PetState.newborn(at: start)
        pet.fallAsleep(at: hours(5))

        #expect(pet.energyLevel(at: hours(6)) == 50 + 20)

        pet.wakeUp(at: hours(6))
        #expect(pet.energyLevel(at: hours(7)) == 70 - 6)
    }

    @Test func petNeverDiesButRunsAwayAfterLongNeglect() {
        let pet = PetState.newborn(at: start)

        #expect(!pet.hasRunAway(at: hours(20)))
        #expect(pet.hasRunAway(at: hours(16 + 12)))
        #expect(pet.mood(at: hours(30), isMusicPlaying: false) == .ranAway)
    }

    @Test func foodCallsARunawayPetBack() {
        var pet = PetState.newborn(at: start)

        pet.feed(at: hours(30))

        #expect(!pet.hasRunAway(at: hours(30)))
        #expect(pet.hungerLevel(at: hours(30)) == 35)
    }

    @Test func moodFollowsNeedsAndMusic() {
        let pet = PetState.newborn(at: start)

        #expect(pet.mood(at: start, isMusicPlaying: false) == .happy)
        #expect(pet.mood(at: start, isMusicPlaying: true) == .dancing)
        #expect(pet.mood(at: hours(8), isMusicPlaying: false) == .hungry)
    }

    @Test func careOnDistinctDaysRaisesLevel() {
        var pet = PetState.newborn(at: start)
        for day in 0..<3 {
            pet.feed(at: hours(Double(day) * 24))
            pet.feed(at: hours(Double(day) * 24 + 1))
        }

        #expect(pet.level == 2)
    }

    @Test func hungerAlertIsScheduledForThresholdCrossing() {
        let pet = PetState.newborn(at: start)

        #expect(pet.hungerAlertDate(from: start) == hours((80 - 25) / 8))
        #expect(pet.hungerAlertDate(from: hours(20)) == nil)
    }
}
