import Foundation
#if canImport(Sparkle)
import Sparkle
#endif

/// Sparkle 2 with a static appcast (GitHub Releases), so updates never depend on a server of ours.
/// Sparkle calls its delegates on the main thread.
/// The Sparkle parts compile only when the Sparkle package product is linked to the MyNotch target.
final class UpdaterService: NSObject {
    /// Posted as the "New Update" live activity instead of Sparkle popping a window over the user's work.
    var updateFound: ((String) -> Void)?

    #if canImport(Sparkle)
    private var controller: SPUStandardUpdaterController?
    #endif

    var isAvailable: Bool {
        #if canImport(Sparkle)
        true
        #else
        false
        #endif
    }

    func start() {
        #if canImport(Sparkle)
        guard controller == nil else { return }
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: self)
        #endif
    }

    func checkForUpdates() {
        #if canImport(Sparkle)
        controller?.checkForUpdates(nil)
        #endif
    }

    /// The update check is the app's only network call, so it can be turned off in About.
    var automaticallyChecksForUpdates: Bool {
        get {
            #if canImport(Sparkle)
            controller?.updater.automaticallyChecksForUpdates ?? false
            #else
            false
            #endif
        }
        set {
            #if canImport(Sparkle)
            controller?.updater.automaticallyChecksForUpdates = newValue
            #endif
        }
    }
}

#if canImport(Sparkle)
extension UpdaterService: SPUUpdaterDelegate {
    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        MainActor.assumeIsolated { updateFound?(version) }
    }
}

extension UpdaterService: SPUStandardUserDriverDelegate {
    /// A Dock-less app must opt into gentle reminders, or Sparkle warns that scheduled alerts may go unseen.
    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }

    nonisolated func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        guard !state.userInitiated else { return }
        let version = update.displayVersionString
        MainActor.assumeIsolated { updateFound?(version) }
    }
}
#endif
