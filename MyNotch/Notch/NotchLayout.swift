import CoreGraphics

/// Sizes of the notch shape in every presentation. Pure so the window, tracking area,
/// and SwiftUI view all agree on the same numbers.
struct NotchLayout: Equatable {
    static let cellWidth: CGFloat = 40
    static let dividerWidth: CGFloat = 9
    static let contentHeight: CGFloat = 140
    static let dropAreaHeight: CGFloat = 96
    static let liveActivityWingWidth: CGFloat = 80
    static let companionWingWidth: CGFloat = 34
    static let hoverGrowth = CGSize(width: 16, height: 4)

    /// The handler pill is only a few points tall; live activities and the panel header need a real bar height.
    static let minimumBarHeight: CGFloat = 28

    let notchSize: CGSize
    let contentPadding: CGFloat
    let nookWidgetWidths: [Int]
    let showsDividers: Bool
    let trayWidth: Int
    let dropAreaWidth: Int
    let hasCompanionWings: Bool

    var barHeight: CGFloat { max(notchSize.height, Self.minimumBarHeight) }

    func size(for presentation: NotchPresentation, isHovering: Bool) -> CGSize {
        switch presentation {
        case .closed:
            closedSize(isHovering: isHovering)
        case .liveActivity:
            CGSize(width: notchSize.width + 2 * Self.liveActivityWingWidth, height: barHeight)
        case .open(.nook):
            openSize(contentWidth: nookContentWidth)
        case .open(.tray):
            openSize(contentWidth: CGFloat(trayWidth) * Self.cellWidth)
        case .dropArea:
            CGSize(
                width: widthIncludingPadding(CGFloat(dropAreaWidth) * Self.cellWidth),
                height: barHeight + Self.dropAreaHeight + contentPadding
            )
        }
    }

    /// The panel is sized once to fit every presentation, so opening never resizes the window mid-animation.
    var panelSize: CGSize {
        let presentations: [NotchPresentation] = [.liveActivity(.media), .open(.nook), .open(.tray), .dropArea]
        let sizes = presentations.map { size(for: $0, isHovering: false) } + [closedSize(isHovering: true)]
        return CGSize(width: sizes.map(\.width).max() ?? 0, height: sizes.map(\.height).max() ?? 0)
    }

    var nookContentWidth: CGFloat {
        let cells = CGFloat(nookWidgetWidths.reduce(0, +)) * Self.cellWidth
        let dividerCount = showsDividers ? max(nookWidgetWidths.count - 1, 0) : 0
        return cells + CGFloat(dividerCount) * Self.dividerWidth
    }

    private func closedSize(isHovering: Bool) -> CGSize {
        let wings = hasCompanionWings ? 2 * Self.companionWingWidth : 0
        let growth = isHovering ? Self.hoverGrowth : .zero
        return CGSize(width: notchSize.width + wings + growth.width, height: notchSize.height + growth.height)
    }

    private func openSize(contentWidth: CGFloat) -> CGSize {
        CGSize(
            width: widthIncludingPadding(contentWidth),
            height: barHeight + Self.contentHeight + 2 * contentPadding
        )
    }

    /// The open panel is never narrower than a live activity, so the header has room on both sides of the notch.
    private func widthIncludingPadding(_ contentWidth: CGFloat) -> CGFloat {
        max(contentWidth + 2 * contentPadding, notchSize.width + 2 * Self.liveActivityWingWidth)
    }
}
