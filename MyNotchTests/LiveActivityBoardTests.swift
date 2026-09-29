import Foundation
import Testing
@testable import MyNotch

@MainActor
struct LiveActivityBoardTests {
    private let start = Date(timeIntervalSince1970: 1_000_000)
    private let allKinds = Set(LiveActivityKind.allCases)
    private let charging = LiveActivity.battery(BatteryEvent(level: 80, isCharging: true, reason: .pluggedIn))

    @Test func higherPriorityActivityWins() {
        var board = LiveActivityBoard()
        board.show(.media, expiresAt: nil)
        board.show(charging, expiresAt: start.addingTimeInterval(10))

        #expect(board.visibleActivity(now: start, allowedKinds: allKinds) == charging)
    }

    @Test func transientActivityExpiresAndRevealsOngoingOne() {
        var board = LiveActivityBoard()
        board.show(.media, expiresAt: nil)
        board.show(charging, expiresAt: start.addingTimeInterval(10))

        board.removeExpired(now: start.addingTimeInterval(10))

        #expect(board.visibleActivity(now: start.addingTimeInterval(10), allowedKinds: allKinds) == .media)
        #expect(board.nextDeadline == nil)
    }

    @Test func disallowedKindsAreSkipped() {
        var board = LiveActivityBoard()
        board.show(.media, expiresAt: nil)
        board.show(charging, expiresAt: nil)

        #expect(board.visibleActivity(now: start, allowedKinds: [.media]) == .media)
    }

    @Test func hiddenActivityIsOnlyReachableThroughQuickPeek() {
        var board = LiveActivityBoard()
        board.show(.media, expiresAt: nil)

        board.hide(.media)

        #expect(board.visibleActivity(now: start, allowedKinds: allKinds) == nil)
        #expect(board.anyActivity(now: start, allowedKinds: allKinds) == .media)
    }

    @Test func peekShowsHiddenActivityUntilDeadline() {
        var board = LiveActivityBoard()
        board.show(.media, expiresAt: nil)
        board.hide(.media)

        board.peek(.media, until: start.addingTimeInterval(5))

        #expect(board.visibleActivity(now: start, allowedKinds: allKinds) == .media)
        #expect(board.nextDeadline == start.addingTimeInterval(5))
        board.removeExpired(now: start.addingTimeInterval(5))
        #expect(board.visibleActivity(now: start.addingTimeInterval(5), allowedKinds: allKinds) == nil)
    }

    @Test func removingClearsHiddenState() {
        var board = LiveActivityBoard()
        board.show(.media, expiresAt: nil)
        board.hide(.media)

        board.remove(.media)
        board.show(.media, expiresAt: nil)

        #expect(!board.isHidden(.media))
        #expect(board.visibleActivity(now: start, allowedKinds: allKinds) == .media)
    }

    @Test func nextDeadlineIsEarliestExpiry() {
        var board = LiveActivityBoard()
        board.show(charging, expiresAt: start.addingTimeInterval(20))
        board.show(.timerEnded, expiresAt: start.addingTimeInterval(5))

        #expect(board.nextDeadline == start.addingTimeInterval(5))
    }
}
