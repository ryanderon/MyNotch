import AppKit
import OSLog
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model: AppModel
    private let settingsScene: NSHostingSceneRepresentation<Settings<SettingsView>>
    private var windowController: NotchWindowController?

    override init() {
        let model = AppModel(settings: SettingsStore())
        self.model = model
        settingsScene = NSHostingSceneRepresentation {
            Settings {
                SettingsView(model: model)
            }
        }
        super.init()
        model.openSettings = { [weak self] in self?.openSettings() }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApplication.shared.addSceneRepresentation(settingsScene)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyLaunchAtLoginDefaultOnFirstRun()
        model.start()
        windowController = NotchWindowController(model: model)
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.flushPendingSaves()
    }

    private func openSettings() {
        // Without a Dock icon the app is never active on its own, so the window would open behind others.
        NSApplication.shared.activate()
        settingsScene.environment.openSettings()
    }

    private func applyLaunchAtLoginDefaultOnFirstRun() {
        let general = model.settings.general
        guard !general.hasAppliedLaunchAtLoginDefault else { return }
        general.hasAppliedLaunchAtLoginDefault = true
        do {
            try LaunchAtLogin().enable()
        } catch {
            Logger.app.error("Could not enable launch at login: \(error.localizedDescription, privacy: .public)")
        }
    }
}
