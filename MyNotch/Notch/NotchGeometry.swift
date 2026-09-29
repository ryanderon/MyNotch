import AppKit

/// The screen values notch detection needs, decoupled from NSScreen so the math is testable.
struct ScreenMetrics: Equatable {
    let frame: CGRect
    let topInset: CGFloat
    let leftAreaWidth: CGFloat
    let rightAreaWidth: CGFloat
}

extension ScreenMetrics {
    init(screen: NSScreen) {
        self.init(
            frame: screen.frame,
            topInset: screen.safeAreaInsets.top,
            leftAreaWidth: screen.auxiliaryTopLeftArea?.width ?? 0,
            rightAreaWidth: screen.auxiliaryTopRightArea?.width ?? 0
        )
    }
}

/// Position and size of the notch (or the handler pill on screens without one),
/// in global screen coordinates (origin bottom-left).
struct NotchGeometry: Equatable {
    enum Kind: Equatable {
        case notch
        case handler
    }

    let notchFrame: CGRect
    let kind: Kind

    /// Returns nil for screens without a notch (no top inset, or no obscured area between the auxiliary areas).
    init?(metrics: ScreenMetrics) {
        let notchWidth = metrics.frame.width - metrics.leftAreaWidth - metrics.rightAreaWidth
        let hasAuxiliaryAreas = metrics.leftAreaWidth > 0 && metrics.rightAreaWidth > 0
        guard metrics.topInset > 0, hasAuxiliaryAreas, notchWidth > 0 else { return nil }
        notchFrame = CGRect(
            x: metrics.frame.minX + metrics.leftAreaWidth,
            y: metrics.frame.maxY - metrics.topInset,
            width: notchWidth,
            height: metrics.topInset
        )
        kind = .notch
    }

    private init(notchFrame: CGRect, kind: Kind) {
        self.notchFrame = notchFrame
        self.kind = kind
    }

    static func handler(screenFrame: CGRect, size: CGSize) -> NotchGeometry {
        let frame = CGRect(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height,
            width: size.width,
            height: size.height
        )
        return NotchGeometry(notchFrame: frame, kind: .handler)
    }

    /// Grows or shrinks the notch around its center while keeping it glued to the top edge.
    func adjusted(by fineTune: CGSize) -> NotchGeometry {
        NotchGeometry(
            notchFrame: topCenteredFrame(size: CGSize(
                width: notchFrame.width + fineTune.width,
                height: notchFrame.height + fineTune.height
            )),
            kind: kind
        )
    }

    /// Never smaller than the notch itself.
    func panelFrame(fitting contentSize: CGSize) -> CGRect {
        topCenteredFrame(size: CGSize(
            width: max(contentSize.width, notchFrame.width),
            height: max(contentSize.height, notchFrame.height)
        ))
    }

    private func topCenteredFrame(size: CGSize) -> CGRect {
        CGRect(x: notchFrame.midX - size.width / 2, y: notchFrame.maxY - size.height, width: size.width, height: size.height)
    }
}
