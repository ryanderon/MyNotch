import CoreGraphics
import Testing
@testable import MyNotch

@MainActor
struct NotchPlacementTests {
    private let notchedMetrics = ScreenMetrics(
        frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        topInset: 32,
        leftAreaWidth: 663,
        rightAreaWidth: 663
    )
    private let externalMetrics = ScreenMetrics(
        frame: CGRect(x: 1512, y: 0, width: 2560, height: 1440),
        topInset: 0,
        leftAreaWidth: 0,
        rightAreaWidth: 0
    )

    private func rules(
        visibility: FullscreenVisibility = .notchedScreens,
        handlerEnabled: Bool = false
    ) -> NotchPlacementRules {
        NotchPlacementRules(
            fullscreenVisibility: visibility,
            isHandlerEnabled: handlerEnabled,
            handlerSize: CGSize(width: 184, height: 8),
            notchFineTune: .zero
        )
    }

    @Test func notchedScreenWinsOverExternal() throws {
        let screens = [
            ScreenDescription(metrics: externalMetrics, hasFullscreenWindow: false),
            ScreenDescription(metrics: notchedMetrics, hasFullscreenWindow: false)
        ]

        let placement = try #require(NotchPlacement.resolve(screens: screens, rules: rules(handlerEnabled: true)))

        #expect(placement.geometry.kind == .notch)
    }

    @Test func noNotchAndNoHandlerMeansNoPanel() {
        let screens = [ScreenDescription(metrics: externalMetrics, hasFullscreenWindow: false)]

        #expect(NotchPlacement.resolve(screens: screens, rules: rules()) == nil)
    }

    @Test func handlerIsTopCenteredOnFirstScreen() throws {
        let screens = [ScreenDescription(metrics: externalMetrics, hasFullscreenWindow: false)]

        let placement = try #require(NotchPlacement.resolve(screens: screens, rules: rules(handlerEnabled: true)))

        #expect(placement.geometry.kind == .handler)
        #expect(placement.geometry.notchFrame == CGRect(x: 2700, y: 1432, width: 184, height: 8))
    }

    @Test func fullscreenNeverHidesNotch() {
        let screens = [ScreenDescription(metrics: notchedMetrics, hasFullscreenWindow: true)]

        #expect(NotchPlacement.resolve(screens: screens, rules: rules(visibility: .never)) == nil)
    }

    @Test func fullscreenOnNotchedScreensKeepsNotchButHidesHandler() throws {
        let notched = [ScreenDescription(metrics: notchedMetrics, hasFullscreenWindow: true)]
        let external = [ScreenDescription(metrics: externalMetrics, hasFullscreenWindow: true)]

        let placement = try #require(NotchPlacement.resolve(screens: notched, rules: rules()))
        #expect(placement.isFullscreenActive)
        #expect(NotchPlacement.resolve(screens: external, rules: rules(handlerEnabled: true)) == nil)
    }

    @Test func fullscreenOnAllScreensKeepsHandler() {
        let screens = [ScreenDescription(metrics: externalMetrics, hasFullscreenWindow: true)]

        let placement = NotchPlacement.resolve(screens: screens, rules: rules(visibility: .allScreens, handlerEnabled: true))

        #expect(placement?.geometry.kind == .handler)
    }
}
