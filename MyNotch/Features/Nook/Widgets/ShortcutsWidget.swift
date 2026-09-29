import OSLog
import SwiftUI

struct ShortcutsWidget: View {
    @Environment(AppModel.self) private var model
    @State private var runningShortcut: String?

    var body: some View {
        let names = model.settings.nook.shortcutNames
        VStack(spacing: 6) {
            WidgetTitle(text: "Shortcuts")
            if names.isEmpty {
                WidgetMessage(
                    systemImage: "square.stack.3d.up",
                    message: "Pick shortcuts in Settings",
                    actionTitle: "Settings…",
                    action: model.openSettings
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(names, id: \.self) { name in
                            ShortcutButton(name: name, isRunning: runningShortcut == name) { run(name) }
                        }
                    }
                }
                .scrollIndicators(.never)
            }
        }
    }

    private func run(_ name: String) {
        runningShortcut = name
        Task {
            do {
                try await ShortcutsRunner.run(named: name)
            } catch {
                Logger.services.error("Shortcut \(name, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            }
            runningShortcut = nil
        }
    }
}

private struct ShortcutButton: View {
    let name: String
    let isRunning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isRunning {
                    ProgressView().controlSize(.mini)
                }
                Text(name).lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 30)
        }
        .buttonStyle(NotchButtonStyle())
        .disabled(isRunning)
    }
}
