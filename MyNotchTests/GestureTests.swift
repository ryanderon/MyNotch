import CoreGraphics
import Testing
@testable import MyNotch

@MainActor
struct SwipeRecognizerTests {
    private func sample(_ dx: CGFloat, _ dy: CGFloat, _ phase: ScrollSample.Phase) -> ScrollSample {
        ScrollSample(fingerDelta: CGVector(dx: dx, dy: dy), phase: phase)
    }

    @Test func smallMovementIsNotASwipe() {
        var recognizer = SwipeRecognizer()
        recognizer.consume(sample(0, 10, .began))
        recognizer.consume(sample(0, 10, .changed))
        #expect(recognizer.recognizedSwipe == nil)
    }

    @Test func accumulatedDownwardMovementIsSwipeDown() {
        var recognizer = SwipeRecognizer()
        recognizer.consume(sample(0, 20, .began))
        recognizer.consume(sample(2, 20, .changed))
        #expect(recognizer.recognizedSwipe == .down)
    }

    @Test func dominantAxisWins() {
        var recognizer = SwipeRecognizer()
        recognizer.consume(sample(-40, 10, .began))
        #expect(recognizer.recognizedSwipe == .left)
    }

    @Test func oneGestureFiresOnlyOnce() {
        var recognizer = SwipeRecognizer()
        recognizer.consume(sample(0, -40, .began))
        #expect(recognizer.recognizedSwipe == .up)
        recognizer.consume(sample(0, -40, .changed))
        #expect(recognizer.recognizedSwipe == nil)
    }

    @Test func newGestureCanFireAgain() {
        var recognizer = SwipeRecognizer()
        recognizer.consume(sample(40, 0, .began))
        recognizer.consume(sample(0, 0, .ended))
        recognizer.consume(sample(40, 0, .began))
        #expect(recognizer.recognizedSwipe == .right)
    }

    @Test func momentumIsIgnored() {
        var recognizer = SwipeRecognizer()
        recognizer.consume(sample(0, 200, .ignored))
        #expect(recognizer.recognizedSwipe == nil)
    }
}

@MainActor
struct SwipeActionTests {
    private let rules = SwipeAction.Rules(verticalOpenClose: true, horizontalMediaControl: true, invertMediaGestures: false)

    @Test func swipeDownOpensClosedNotch() {
        #expect(SwipeAction.resolve(.down, presentation: .closed, rules: rules) == .openNook)
    }

    @Test func swipeUpClosesOpenNotch() {
        #expect(SwipeAction.resolve(.up, presentation: .open(.nook), rules: rules) == .close)
    }

    @Test func swipeUpHidesLiveActivity() {
        #expect(SwipeAction.resolve(.up, presentation: .liveActivity(.media), rules: rules) == .hideLiveActivity)
    }

    @Test func swipeLeftIsNextTrackUnlessInverted() {
        #expect(SwipeAction.resolve(.left, presentation: .closed, rules: rules) == .media(.nextTrack))
        let inverted = SwipeAction.Rules(verticalOpenClose: true, horizontalMediaControl: true, invertMediaGestures: true)
        #expect(SwipeAction.resolve(.left, presentation: .closed, rules: inverted) == .media(.previousTrack))
    }

    @Test func disabledGesturesDoNothing() {
        let off = SwipeAction.Rules(verticalOpenClose: false, horizontalMediaControl: false, invertMediaGestures: false)
        #expect(SwipeAction.resolve(.down, presentation: .closed, rules: off) == nil)
        #expect(SwipeAction.resolve(.right, presentation: .closed, rules: off) == nil)
    }

    @Test func horizontalSwipeIsIgnoredWhileOpen() {
        #expect(SwipeAction.resolve(.left, presentation: .open(.nook), rules: rules) == nil)
    }
}
