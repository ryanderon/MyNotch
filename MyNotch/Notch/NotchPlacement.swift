import CoreGraphics

struct ScreenDescription: Equatable {
    let metrics: ScreenMetrics
    let hasFullscreenWindow: Bool
}

struct NotchPlacementRules: Equatable {
    let fullscreenVisibility: FullscreenVisibility
    let isHandlerEnabled: Bool
    let handlerSize: CGSize
    let notchFineTune: CGSize
}

/// Decides which screen hosts the single notch panel, and whether it is shown at all.
struct NotchPlacement: Equatable {
    let geometry: NotchGeometry
    let isFullscreenActive: Bool

    /// A notched screen always wins; the handler pill is the fallback when no screen has a notch.
    static func resolve(screens: [ScreenDescription], rules: NotchPlacementRules) -> NotchPlacement? {
        if let notched = firstNotchedScreen(in: screens) {
            if notched.screen.hasFullscreenWindow && rules.fullscreenVisibility == .never {
                return nil
            }
            return NotchPlacement(
                geometry: notched.geometry.adjusted(by: rules.notchFineTune),
                isFullscreenActive: notched.screen.hasFullscreenWindow
            )
        }
        guard rules.isHandlerEnabled, let screen = screens.first else { return nil }
        if screen.hasFullscreenWindow && rules.fullscreenVisibility != .allScreens {
            return nil
        }
        return NotchPlacement(
            geometry: .handler(screenFrame: screen.metrics.frame, size: rules.handlerSize),
            isFullscreenActive: screen.hasFullscreenWindow
        )
    }

    private static func firstNotchedScreen(
        in screens: [ScreenDescription]
    ) -> (screen: ScreenDescription, geometry: NotchGeometry)? {
        for screen in screens {
            if let geometry = NotchGeometry(metrics: screen.metrics) {
                return (screen, geometry)
            }
        }
        return nil
    }
}
