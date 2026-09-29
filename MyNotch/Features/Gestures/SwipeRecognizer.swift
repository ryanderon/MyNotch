import CoreGraphics

enum SwipeDirection: Equatable {
    case up
    case down
    case left
    case right
}

/// One trackpad scroll sample, already converted to finger movement (positive y = fingers moving down).
struct ScrollSample: Equatable {
    enum Phase: Equatable {
        case began
        case changed
        case ended
        /// Momentum (inertia) and legacy mouse-wheel events never count as swipes.
        case ignored
    }

    let fingerDelta: CGVector
    let phase: Phase
}

/// Turns a stream of scroll samples into at most one swipe per gesture. Pure, so thresholds are testable.
struct SwipeRecognizer {
    static let threshold: CGFloat = 36

    private(set) var recognizedSwipe: SwipeDirection?
    private var accumulated = CGVector.zero
    private var hasRecognizedInCurrentGesture = false

    mutating func consume(_ sample: ScrollSample) {
        recognizedSwipe = nil
        switch sample.phase {
        case .began:
            accumulated = sample.fingerDelta
            hasRecognizedInCurrentGesture = false
            recognizeIfPastThreshold()
        case .changed:
            accumulated.dx += sample.fingerDelta.dx
            accumulated.dy += sample.fingerDelta.dy
            recognizeIfPastThreshold()
        case .ended:
            accumulated = .zero
        case .ignored:
            break
        }
    }

    private mutating func recognizeIfPastThreshold() {
        guard !hasRecognizedInCurrentGesture else { return }
        let horizontal = abs(accumulated.dx)
        let vertical = abs(accumulated.dy)
        guard max(horizontal, vertical) >= Self.threshold else { return }
        hasRecognizedInCurrentGesture = true
        if vertical >= horizontal {
            recognizedSwipe = accumulated.dy > 0 ? .down : .up
        } else {
            recognizedSwipe = accumulated.dx > 0 ? .right : .left
        }
    }
}
