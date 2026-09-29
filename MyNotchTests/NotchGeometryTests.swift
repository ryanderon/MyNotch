import CoreGraphics
import Testing
@testable import MyNotch

@MainActor
struct NotchGeometryTests {
    private let builtInMetrics = ScreenMetrics(
        frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        topInset: 32,
        leftAreaWidth: 663,
        rightAreaWidth: 663
    )

    @Test func notchIsCenteredBetweenAuxiliaryAreas() throws {
        let geometry = try #require(NotchGeometry(metrics: builtInMetrics))
        #expect(geometry.notchFrame == CGRect(x: 663, y: 950, width: 186, height: 32))
        #expect(geometry.kind == .notch)
    }

    @Test func screenWithoutTopInsetHasNoNotch() {
        let metrics = ScreenMetrics(frame: builtInMetrics.frame, topInset: 0, leftAreaWidth: 663, rightAreaWidth: 663)
        #expect(NotchGeometry(metrics: metrics) == nil)
    }

    @Test func screenWithoutAuxiliaryAreasHasNoNotch() {
        let metrics = ScreenMetrics(frame: builtInMetrics.frame, topInset: 24, leftAreaWidth: 0, rightAreaWidth: 0)
        #expect(NotchGeometry(metrics: metrics) == nil)
    }

    @Test func auxiliaryAreasCoveringTheScreenHaveNoNotch() {
        let metrics = ScreenMetrics(frame: builtInMetrics.frame, topInset: 32, leftAreaWidth: 756, rightAreaWidth: 756)
        #expect(NotchGeometry(metrics: metrics) == nil)
    }

    @Test func notchOnSecondaryScreenUsesScreenOrigin() throws {
        let metrics = ScreenMetrics(
            frame: CGRect(x: 1920, y: 200, width: 1512, height: 982),
            topInset: 32,
            leftAreaWidth: 663,
            rightAreaWidth: 663
        )
        let geometry = try #require(NotchGeometry(metrics: metrics))
        #expect(geometry.notchFrame.origin == CGPoint(x: 2583, y: 1150))
    }

    @Test func panelFrameIsTopCenteredOnNotch() throws {
        let geometry = try #require(NotchGeometry(metrics: builtInMetrics))
        let frame = geometry.panelFrame(fitting: CGSize(width: 640, height: 200))
        #expect(frame == CGRect(x: 436, y: 782, width: 640, height: 200))
    }

    @Test func panelFrameNeverShrinksBelowNotch() throws {
        let geometry = try #require(NotchGeometry(metrics: builtInMetrics))
        #expect(geometry.panelFrame(fitting: CGSize(width: 10, height: 10)) == geometry.notchFrame)
    }

    @Test func fineTuneGrowsAroundCenterAndStaysAtTopEdge() throws {
        let geometry = try #require(NotchGeometry(metrics: builtInMetrics))
        let adjusted = geometry.adjusted(by: CGSize(width: 10, height: -4))
        #expect(adjusted.notchFrame == CGRect(x: 658, y: 954, width: 196, height: 28))
    }

    @Test func handlerIsTopCentered() {
        let geometry = NotchGeometry.handler(screenFrame: builtInMetrics.frame, size: CGSize(width: 184, height: 8))
        #expect(geometry.notchFrame == CGRect(x: 664, y: 974, width: 184, height: 8))
        #expect(geometry.kind == .handler)
    }
}
