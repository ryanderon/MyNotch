import AppKit
import CoreGraphics

/// Reports when the notch may need to move or hide: displays changed, a Space switched,
/// or another app became active (entering or leaving fullscreen). Purely notification-driven.
final class ScreenObserver {
    var screensDidChange: (() -> Void)?

    private var tokens: [NSObjectProtocol] = []

    func start() {
        guard tokens.isEmpty else { return }
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        tokens = [
            NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
            ) { [weak self] _ in MainActor.assumeIsolated { self?.screensDidChange?() } },
            workspaceCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
            ) { [weak self] _ in MainActor.assumeIsolated { self?.screensDidChange?() } },
            workspaceCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
            ) { [weak self] _ in MainActor.assumeIsolated { self?.screensDidChange?() } }
        ]
    }

    func currentScreens() -> [ScreenDescription] {
        let fullscreenSizes = fullscreenWindowFrames()
        return NSScreen.screens.map { screen in
            ScreenDescription(
                metrics: ScreenMetrics(screen: screen),
                hasFullscreenWindow: fullscreenSizes.contains { Self.frame($0, covers: screen) }
            )
        }
    }

    /// A fullscreen app shows a normal-layer window exactly as large as its screen. Window bounds are public
    /// window-list keys, so this needs no Screen Recording permission.
    private func fullscreenWindowFrames() -> [CGRect] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        return windows.compactMap { window in
            guard window[kCGWindowLayer as String] as? Int == 0,
                  window[kCGWindowOwnerPID as String] as? Int32 != ownPID,
                  let boundsDictionary = window[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary) else {
                return nil
            }
            return bounds
        }
    }

    /// Window-list bounds use a top-left origin on the primary display; NSScreen frames use bottom-left.
    private static func frame(_ windowBounds: CGRect, covers screen: NSScreen) -> Bool {
        guard let primaryHeight = NSScreen.screens.first?.frame.height else { return false }
        let screenFrame = screen.frame
        let screenInWindowSpace = CGRect(
            x: screenFrame.minX,
            y: primaryHeight - screenFrame.maxY,
            width: screenFrame.width,
            height: screenFrame.height
        )
        return windowBounds.integral == screenInWindowSpace.integral
    }
}
