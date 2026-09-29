import CoreGraphics

/// Where a pupil sits inside its eye, given the cursor. Pure so the feel can be tuned and tested.
enum PupilMath {
    /// Beyond this distance (in points) the pupil is fully pushed to the edge of the eye.
    static let fullDeflectionDistance: CGFloat = 240

    static func offset(eyeCenter: CGPoint, target: CGPoint, maxOffset: CGFloat) -> CGVector {
        let dx = target.x - eyeCenter.x
        let dy = target.y - eyeCenter.y
        let distance = (dx * dx + dy * dy).squareRoot()
        guard distance > 0.5 else { return .zero }
        let magnitude = maxOffset * min(distance / fullDeflectionDistance, 1)
        return CGVector(dx: dx / distance * magnitude, dy: dy / distance * magnitude)
    }
}

/// How open the eyelids are, from the Eye settings and how long the cursor has been still.
enum EyelidState: Equatable {
    case open
    case droopy
    case closed

    static let idleDelay: Double = 30

    static func resolve(secondsSinceCursorMoved: Double, sleepsWhenIdle: Bool) -> EyelidState {
        sleepsWhenIdle && secondsSinceCursorMoved >= idleDelay ? .droopy : .open
    }

    /// Fraction of the eye covered by the lid.
    var coverage: CGFloat {
        switch self {
        case .open: 0
        case .droopy: 0.45
        case .closed: 1
        }
    }
}
