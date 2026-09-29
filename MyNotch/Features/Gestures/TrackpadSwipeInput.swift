import AppKit

/// Adapts AppKit scroll events (delivered only while the cursor is over the notch) into swipe actions.
final class TrackpadSwipeInput {
    private let settings: GestureSettings
    private let coordinator: ActivityCoordinator
    private let performMediaCommand: (MediaCommand) -> Void
    private var recognizer = SwipeRecognizer()

    init(model: AppModel) {
        settings = model.settings.gestures
        coordinator = model.coordinator
        performMediaCommand = { [weak model] command in model?.perform(command) }
    }

    func handle(_ event: NSEvent) {
        guard settings.gesturesOnHover else { return }
        recognizer.consume(Self.sample(from: event))
        guard let swipe = recognizer.recognizedSwipe else { return }
        let rules = SwipeAction.Rules(
            verticalOpenClose: settings.verticalOpenClose,
            horizontalMediaControl: settings.horizontalMediaControl,
            invertMediaGestures: settings.invertMediaGestures
        )
        guard let action = SwipeAction.resolve(swipe, presentation: coordinator.presentation, rules: rules) else {
            return
        }
        perform(action)
    }

    private func perform(_ action: SwipeAction) {
        switch action {
        case .openNook: coordinator.open()
        case .close: coordinator.close()
        case .hideLiveActivity: coordinator.hideVisibleActivity()
        case .media(let command): performMediaCommand(command)
        }
    }

    /// With natural scrolling the deltas already follow the fingers; otherwise they are mirrored.
    private static func sample(from event: NSEvent) -> ScrollSample {
        let direction: CGFloat = event.isDirectionInvertedFromDevice ? 1 : -1
        let delta = CGVector(dx: event.scrollingDeltaX * direction, dy: event.scrollingDeltaY * direction)
        return ScrollSample(fingerDelta: delta, phase: phase(of: event))
    }

    private static func phase(of event: NSEvent) -> ScrollSample.Phase {
        guard event.hasPreciseScrollingDeltas, event.momentumPhase.isEmpty else { return .ignored }
        if event.phase.contains(.began) { return .began }
        if event.phase.contains(.changed) { return .changed }
        if event.phase.contains(.ended) || event.phase.contains(.cancelled) { return .ended }
        return .ignored
    }
}
