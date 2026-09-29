import SwiftUI
import UniformTypeIdentifiers

struct LiveActivitySettingsView: View {
    @Bindable var liveActivities: LiveActivitySettings

    var body: some View {
        Form {
            Section {
                LiveActivityPreview(liveActivities: liveActivities)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
            Section {
                Toggle("Enable live activities", isOn: $liveActivities.isEnabled)
                Stepper(value: $liveActivities.inactivityTimeout, in: LiveActivitySettings.inactivityTimeoutRange) {
                    LabeledContent("Hide after inactivity", value: "\(liveActivities.inactivityTimeout) s")
                }
                Toggle("Interactive (click performs the activity's action)", isOn: $liveActivities.isInteractive)
                Toggle("Quick Peek on hover", isOn: $liveActivities.quickPeek)
                Toggle("Unhide automatically after swiping away", isOn: $liveActivities.unhideAutomatically)
                Toggle("Show song changes", isOn: $liveActivities.showSongChange)
                Toggle("Hide on screens without a notch", isOn: $liveActivities.hideOnNonNotched)
            }
            ActivityKindsSection(liveActivities: liveActivities)
                .disabled(!liveActivities.isEnabled)
            MediaEffectSection(liveActivities: liveActivities)
        }
        .formStyle(.grouped)
    }
}

private struct ActivityKindsSection: View {
    @Bindable var liveActivities: LiveActivitySettings

    var body: some View {
        Section("Activities") {
            Grid(alignment: .leading, verticalSpacing: 6) {
                GridRow {
                    Text("Activity").foregroundStyle(.secondary)
                    Text("Enabled").foregroundStyle(.secondary)
                    Text("In fullscreen").foregroundStyle(.secondary)
                }
                ForEach(LiveActivityKind.allCases) { kind in
                    GridRow {
                        Text(kind.title)
                        Toggle("", isOn: membership(of: kind, in: $liveActivities.enabledKinds)).labelsHidden()
                        Toggle("", isOn: membership(of: kind, in: $liveActivities.visibleInFullscreen)).labelsHidden()
                    }
                }
            }
        }
    }

    private func membership(of kind: LiveActivityKind, in set: Binding<Set<LiveActivityKind>>) -> Binding<Bool> {
        Binding(
            get: { set.wrappedValue.contains(kind) },
            set: { isMember in
                if isMember {
                    set.wrappedValue.insert(kind)
                } else {
                    set.wrappedValue.remove(kind)
                }
            }
        )
    }
}

private struct MediaEffectSection: View {
    @Bindable var liveActivities: LiveActivitySettings

    var body: some View {
        Section("Media") {
            Picker("Effect", selection: $liveActivities.mediaEffect) {
                ForEach(MediaEffect.allCases) { Text($0.title).tag($0) }
            }
            if liveActivities.mediaEffect == .gif {
                LabeledContent("GIF") {
                    Button(liveActivities.gifPath.isEmpty ? "Choose…" : URL(filePath: liveActivities.gifPath).lastPathComponent) {
                        chooseGIF()
                    }
                }
            }
            Toggle("Color effects from album artwork", isOn: $liveActivities.coloredEffects)
            Stepper(value: $liveActivities.albumCornerRadius, in: LiveActivitySettings.albumCornerRadiusRange) {
                LabeledContent("Artwork corner radius", value: "\(liveActivities.albumCornerRadius)")
            }
        }
    }

    private func chooseGIF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.gif]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        liveActivities.gifPath = url.path(percentEncoded: false)
    }
}

/// A static mock of the media live activity, using the current effect settings.
private struct LiveActivityPreview: View {
    @Environment(AppModel.self) private var model
    let liveActivities: LiveActivitySettings

    var body: some View {
        HStack(spacing: 0) {
            MediaArtworkThumbnail(size: 22)
                .frame(width: 60)
            Color.clear.frame(width: 120)
            MediaVisualizer(
                effect: liveActivities.mediaEffect,
                tint: model.media.visualizerTint(colored: liveActivities.coloredEffects),
                gifPath: liveActivities.gifPath,
                isAnimating: true
            )
            .frame(width: 20, height: 16)
            .frame(width: 60)
        }
        .frame(height: 32)
        .background(UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12).fill(.black))
    }
}
