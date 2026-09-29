import AppKit
import SwiftUI

/// Owns the single notch panel for the app's lifetime; it is repositioned and shown or hidden, never recreated.
final class NotchWindowController {
    /// Everything the AppKit side needs from the model, observed as one value.
    private struct FrameState: Equatable {
        let panelFrame: CGRect?
        let interactiveSize: CGSize
        let isOpen: Bool

        init(model: AppModel) {
            let presentation = model.coordinator.presentation
            isOpen = presentation.isOpen
            guard let placement = model.placement, let layout = model.layout else {
                panelFrame = nil
                interactiveSize = .zero
                return
            }
            panelFrame = placement.geometry.panelFrame(fitting: layout.panelSize)
            interactiveSize = layout.size(for: presentation, isHovering: model.coordinator.isPointerInside)
        }
    }

    private let model: AppModel
    private let panel = NotchPanel()
    private let hostingView: NotchHostingView
    private var lastState: FrameState?

    /// Lives as long as the controller; wakes only when the presentation, hover, or layout changes.
    private var stateObservation: Task<Void, Never>?
    private var occlusionToken: NSObjectProtocol?
    private var resignKeyToken: NSObjectProtocol?

    init(model: AppModel) {
        self.model = model
        hostingView = NotchHostingView(rootView: NotchRootView(model: model))
        panel.contentView = hostingView
        connectInput()
        observeOcclusion()
        observeState()
    }

    private func observeState() {
        stateObservation = Task { [weak self, model] in
            for await state in Observations({ FrameState(model: model) }) {
                self?.apply(state)
            }
        }
    }

    private func apply(_ state: FrameState) {
        defer { lastState = state }
        guard let panelFrame = state.panelFrame else {
            panel.orderOut(nil)
            return
        }
        if panel.frame != panelFrame {
            panel.setFrame(panelFrame, display: true)
        }
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
        hostingView.interactiveSize = state.interactiveSize
        if let lastState, lastState.isOpen != state.isOpen {
            performHapticFeedback()
            if !state.isOpen {
                returnKeyboardFocus()
            }
        }
    }

    /// The panel only becomes key for Notes/To-dos typing; once the notch closes, keystrokes must go back
    /// to the app the user was in. That app never stopped being active, so re-activating it restores focus.
    private func returnKeyboardFocus() {
        guard panel.isKeyWindow else { return }
        panel.makeFirstResponder(nil)
        NSWorkspace.shared.frontmostApplication?.activate()
    }

    private func performHapticFeedback() {
        guard !model.settings.general.disableHaptics else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }

    private func connectInput() {
        let coordinator = model.coordinator
        let swipeInput = TrackpadSwipeInput(model: model)
        hostingView.pointerDidEnter = { coordinator.pointerEntered() }
        hostingView.pointerDidExit = { coordinator.pointerExited() }
        hostingView.fileDragDidEnter = { coordinator.dragEntered() }
        hostingView.fileDragDidExit = { coordinator.dragExited() }
        hostingView.scrollDidOccur = { swipeInput.handle($0) }
    }

    private func observeOcclusion() {
        occlusionToken = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification, object: panel, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.model.isPanelVisible = self.panel.occlusionState.contains(.visible)
            }
        }
        // Clicking into another app ends typing even though no text field reported losing focus.
        resignKeyToken = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: panel, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let coordinator = self?.model.coordinator, coordinator.isTyping else { return }
                coordinator.typingEnded()
            }
        }
    }
}
