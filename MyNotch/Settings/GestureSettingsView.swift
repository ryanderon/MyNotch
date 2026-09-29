import SwiftUI

struct GestureSettingsView: View {
    @Bindable var gestures: GestureSettings

    var body: some View {
        Form {
            Section {
                Toggle("Enable gestures while hovering the notch", isOn: $gestures.gesturesOnHover)
            } footer: {
                Text("Trackpad swipes are only read while the cursor is over the notch.")
            }
            Section {
                Toggle("Swipe down to open, up to close", isOn: $gestures.verticalOpenClose)
                Toggle("Swipe left or right to change track", isOn: $gestures.horizontalMediaControl)
                Toggle("Invert track swipe direction", isOn: $gestures.invertMediaGestures)
                    .disabled(!gestures.horizontalMediaControl)
            }
            .disabled(!gestures.gesturesOnHover)
        }
        .formStyle(.grouped)
    }
}
