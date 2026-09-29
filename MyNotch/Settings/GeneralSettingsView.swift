import SwiftUI

struct GeneralSettingsView: View {
    let settings: SettingsStore

    var body: some View {
        Form {
            BehaviorSection(general: settings.general)
            AppearanceSection(general: settings.general)
            TypingSection(general: settings.general)
            NotchSizeSection(general: settings.general)
            HandlerSection(general: settings.general)
            Section {
                Toggle("Demo mode", isOn: Bindable(settings.general).demoMode)
                Button("Reset Settings", action: settings.resetToDefaults)
                Button("Quit MyNotch") { NSApplication.shared.terminate(nil) }
            }
        }
        .formStyle(.grouped)
    }
}

private struct BehaviorSection: View {
    @Bindable var general: GeneralSettings

    var body: some View {
        Section {
            LaunchAtLoginToggle()
            Picker("Show in fullscreen", selection: $general.showInFullscreen) {
                ForEach(FullscreenVisibility.allCases) { Text($0.title).tag($0) }
            }
            Picker("Media source", selection: $general.mediaSource) {
                ForEach(MediaSource.allCases) { Text($0.title).tag($0) }
            }
            Toggle("Always open on hover", isOn: $general.alwaysOpenOnHover)
            Toggle("Disable haptics", isOn: $general.disableHaptics)
        }
    }
}

private struct AppearanceSection: View {
    @Bindable var general: GeneralSettings

    var body: some View {
        Section("Appearance") {
            Toggle("Prefer round buttons", isOn: $general.preferRoundButtons)
            Toggle("Translucent background (experimental)", isOn: $general.translucentBackground)
            Stepper(value: $general.contentPadding, in: GeneralSettings.contentPaddingRange) {
                LabeledContent("Content padding", value: "\(general.contentPadding) px")
            }
        }
    }
}

private struct TypingSection: View {
    @Bindable var general: GeneralSettings

    var body: some View {
        Section("Typing") {
            Toggle("Don't close while typing", isOn: $general.preventCloseWhileTyping)
            Toggle("Lock open while typing", isOn: $general.lockWhileTyping)
                .disabled(!general.preventCloseWhileTyping)
        }
    }
}

private struct NotchSizeSection: View {
    @Bindable var general: GeneralSettings

    var body: some View {
        Section {
            Stepper(value: $general.notchFineTuneWidth, in: GeneralSettings.notchFineTuneWidthRange) {
                LabeledContent("Width offset", value: "\(general.notchFineTuneWidth) px")
            }
            Stepper(value: $general.notchFineTuneHeight, in: GeneralSettings.notchFineTuneHeightRange) {
                LabeledContent("Height offset", value: "\(general.notchFineTuneHeight) px")
            }
        } header: {
            Text("Notch size")
        } footer: {
            Text("Adjust if the closed notch doesn't blend with the physical one.")
        }
    }
}

private struct HandlerSection: View {
    @Bindable var general: GeneralSettings

    var body: some View {
        Section {
            Toggle("Show handler on screens without a notch", isOn: $general.handlerEnabled)
            Group {
                Stepper(value: $general.handlerWidth, in: GeneralSettings.handlerWidthRange, step: 4) {
                    LabeledContent("Handler width", value: "\(general.handlerWidth) px")
                }
                Stepper(value: $general.handlerHeight, in: GeneralSettings.handlerHeightRange) {
                    LabeledContent("Handler height", value: "\(general.handlerHeight) px")
                }
                Toggle("Transparent until hovered", isOn: $general.handlerTransparent)
            }
            .disabled(!general.handlerEnabled)
        } header: {
            Text("Screens without a notch")
        }
    }
}
