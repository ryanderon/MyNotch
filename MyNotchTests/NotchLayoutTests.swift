import CoreGraphics
import Testing
@testable import MyNotch

@MainActor
struct NotchLayoutTests {
    private func layout(widths: [Int] = [5, 2, 5], wings: Bool = false, notchHeight: CGFloat = 32) -> NotchLayout {
        NotchLayout(
            notchSize: CGSize(width: 186, height: notchHeight),
            contentPadding: 12,
            nookWidgetWidths: widths,
            showsDividers: true,
            trayWidth: 11,
            dropAreaWidth: 11,
            hasCompanionWings: wings
        )
    }

    @Test func closedMatchesNotchAndGrowsOnHover() {
        #expect(layout().size(for: .closed, isHovering: false) == CGSize(width: 186, height: 32))
        #expect(layout().size(for: .closed, isHovering: true) == CGSize(width: 202, height: 36))
    }

    @Test func companionWingsWidenClosedNotch() {
        let expectedWidth: CGFloat = 186 + 2 * 34
        #expect(layout(wings: true).size(for: .closed, isHovering: false).width == expectedWidth)
    }

    @Test func nookWidthIsCellsPlusDividersPlusPadding() {
        let size = layout().size(for: .open(.nook), isHovering: false)

        let expected = CGSize(width: 12 * 40 + 2 * 9 + 24, height: 32 + 140 + 24)
        #expect(size == expected)
    }

    @Test func narrowNookStillFitsHeaderAroundNotch() {
        let size = layout(widths: [2]).size(for: .open(.nook), isHovering: false)

        let expectedWidth: CGFloat = 186 + 2 * 80
        #expect(size.width == expectedWidth)
    }

    @Test func handlerUsesMinimumBarHeightForLiveActivities() {
        let size = layout(notchHeight: 8).size(for: .liveActivity(.media), isHovering: false)

        #expect(size.height == 28)
    }

    @Test func panelFitsLargestPresentation() {
        let layout = layout()
        let nook = layout.size(for: .open(.nook), isHovering: false)
        let dropArea = layout.size(for: .dropArea, isHovering: false)

        #expect(layout.panelSize.width >= max(nook.width, dropArea.width))
        #expect(layout.panelSize.height >= max(nook.height, dropArea.height))
    }
}
