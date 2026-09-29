import SwiftUI

struct AboutSettingsView: View {
    let updater: UpdaterService
    @State private var checksAutomatically = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        let shortVersion = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(shortVersion) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 6) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .frame(width: 72, height: 72)
                    Text("MyNotch").font(.title2.bold())
                    Text("Version \(version)").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            Section("Updates") {
                if updater.isAvailable {
                    Toggle("Check for updates automatically", isOn: $checksAutomatically)
                        .onChange(of: checksAutomatically) { _, isOn in updater.automaticallyChecksForUpdates = isOn }
                    Button("Check for Updates…", action: updater.checkForUpdates)
                } else {
                    Text("Updates are unavailable in this build (Sparkle is not linked).")
                        .foregroundStyle(.secondary)
                }
            }
            Section("Credits") {
                Text("Made for personal use by Ryan Deron.")
                Text("Updates by Sparkle. All data stays on this Mac; no license server, no analytics.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { checksAutomatically = updater.automaticallyChecksForUpdates }
    }
}
