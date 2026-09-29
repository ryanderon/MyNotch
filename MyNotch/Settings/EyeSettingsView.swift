import SwiftUI

struct EyeSettingsView: View {
    @Bindable var eye: EyeSettings

    var body: some View {
        Form {
            Section {
                Toggle("Enable Eye", isOn: $eye.isEnabled)
            } footer: {
                Text("A pair of eyes that follow your cursor. Mouse tracking runs only while the eyes are visible.")
            }
            Section {
                Toggle("Show when the notch is closed", isOn: $eye.showWhenClosed)
                Toggle("Show when the notch is open", isOn: $eye.showWhenOpen)
                Toggle("Blink", isOn: $eye.blinks)
                Toggle("Get sleepy when the cursor is idle", isOn: $eye.sleepsWhenIdle)
            }
            .disabled(!eye.isEnabled)
        }
        .formStyle(.grouped)
    }
}
