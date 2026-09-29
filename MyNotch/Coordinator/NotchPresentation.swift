import Foundation

enum NookTab: Equatable {
    case nook
    case tray
}

enum NotchPresentation: Equatable {
    case closed
    case liveActivity(LiveActivity)
    case open(NookTab)
    case dropArea

    var isOpen: Bool {
        if case .open = self { return true }
        return false
    }
}

enum ActivityLifetime {
    /// Stays until explicitly ended (music playing, files in the tray).
    case ongoing
    /// Disappears after the inactivity timeout (charger plugged in, device connected).
    case transient
}

struct ScreenContext: Equatable {
    var hasNotch = true
    var isFullscreenActive = false
}
