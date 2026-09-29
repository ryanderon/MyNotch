/// What a recognized swipe does, given the current notch state and the Gestures settings.
enum SwipeAction: Equatable {
    case openNook
    case close
    case hideLiveActivity
    case media(MediaCommand)

    struct Rules: Equatable {
        let verticalOpenClose: Bool
        let horizontalMediaControl: Bool
        let invertMediaGestures: Bool
    }

    /// Swiping left moves forward (next track), like paging; "invert" flips it.
    static func resolve(_ swipe: SwipeDirection, presentation: NotchPresentation, rules: Rules) -> SwipeAction? {
        switch swipe {
        case .down:
            guard rules.verticalOpenClose, !presentation.isOpen else { return nil }
            return .openNook
        case .up:
            guard rules.verticalOpenClose else { return nil }
            if case .liveActivity = presentation { return .hideLiveActivity }
            return presentation.isOpen ? .close : nil
        case .left, .right:
            guard rules.horizontalMediaControl, !presentation.isOpen else { return nil }
            let isForward = (swipe == .left) != rules.invertMediaGestures
            return .media(isForward ? .nextTrack : .previousTrack)
        }
    }
}
