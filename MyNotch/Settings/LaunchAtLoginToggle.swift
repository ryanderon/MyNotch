import SwiftUI

struct LaunchAtLoginToggle: View {
    private let launchAtLogin = LaunchAtLogin()
    @State private var isEnabled = false
    @State private var needsApproval = false
    @State private var errorMessage: String?

    var body: some View {
        Toggle("Launch at login", isOn: Binding(get: { isEnabled }, set: updateLaunchAtLogin))
            .onAppear(perform: refreshStatus)
        if needsApproval {
            Text("Approve MyNotch in System Settings > General > Login Items.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        if let errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func updateLaunchAtLogin(to shouldEnable: Bool) {
        do {
            if shouldEnable {
                try launchAtLogin.enable()
            } else {
                try launchAtLogin.disable()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        refreshStatus()
    }

    private func refreshStatus() {
        needsApproval = launchAtLogin.needsApproval
        isEnabled = launchAtLogin.isEnabled || needsApproval
    }
}
