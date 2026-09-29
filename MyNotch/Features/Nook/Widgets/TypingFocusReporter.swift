import SwiftUI

extension View {
    /// Tells the coordinator when a text field in the notch starts or stops editing, which drives the
    /// "don't close while typing" and "lock while typing" settings.
    func reportsTyping(_ isFocused: Bool, to coordinator: ActivityCoordinator) -> some View {
        onChange(of: isFocused) { _, focused in
            if focused {
                coordinator.typingBegan()
            } else {
                coordinator.typingEnded()
            }
        }
    }
}
