import CoreGraphics
import Testing
@testable import MyNotch

@MainActor
struct PupilMathTests {
    @Test func cursorOnEyeCenterKeepsPupilCentered() {
        #expect(PupilMath.offset(eyeCenter: .zero, target: .zero, maxOffset: 3) == .zero)
    }

    @Test func farCursorPushesPupilToEdge() {
        let offset = PupilMath.offset(eyeCenter: .zero, target: CGPoint(x: 1000, y: 0), maxOffset: 3)
        #expect(offset == CGVector(dx: 3, dy: 0))
    }

    @Test func nearCursorMovesPupilPartially() {
        let offset = PupilMath.offset(eyeCenter: .zero, target: CGPoint(x: 0, y: -120), maxOffset: 4)
        #expect(offset == CGVector(dx: 0, dy: -2))
    }

    @Test func eyelidsDroopOnlyWhenIdleAndAllowed() {
        #expect(EyelidState.resolve(secondsSinceCursorMoved: 5, sleepsWhenIdle: true) == .open)
        #expect(EyelidState.resolve(secondsSinceCursorMoved: 45, sleepsWhenIdle: true) == .droopy)
        #expect(EyelidState.resolve(secondsSinceCursorMoved: 45, sleepsWhenIdle: false) == .open)
    }
}
