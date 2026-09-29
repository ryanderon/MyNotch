import AppKit
import SwiftUI

/// Hosts the SwiftUI notch and turns AppKit input (hover, file drags, trackpad scrolls) into events.
/// Everything is scoped to the visible notch shape: there is no global monitor, and no work while
/// the cursor is elsewhere.
final class NotchHostingView: NSHostingView<NotchRootView> {
    var interactiveSize: CGSize = .zero {
        didSet {
            guard interactiveSize != oldValue else { return }
            updateTrackingAreas()
        }
    }

    var pointerDidEnter: (() -> Void)?
    var pointerDidExit: (() -> Void)?
    var fileDragDidEnter: (() -> Void)?
    var fileDragDidExit: (() -> Void)?
    var scrollDidOccur: ((NSEvent) -> Void)?

    private var notchTrackingArea: NSTrackingArea?
    private var isFileDragInside = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        registerForDraggedTypes([.fileURL])
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let notchTrackingArea {
            removeTrackingArea(notchTrackingArea)
        }
        let trackingArea = NSTrackingArea(
            rect: interactiveRect,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self
        )
        addTrackingArea(trackingArea)
        notchTrackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        pointerDidEnter?()
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        pointerDidExit?()
    }

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        scrollDidOccur?(event)
    }

    // The panel is non-activating, so the first click must reach SwiftUI directly.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    // MARK: File drags

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let operation = super.draggingEntered(sender)
        updateFileDrag(sender)
        return isFileDragInside ? operation.union(.copy) : operation
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let operation = super.draggingUpdated(sender)
        updateFileDrag(sender)
        return isFileDragInside ? operation.union(.copy) : operation
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        super.draggingExited(sender)
        endFileDrag()
    }

    override func concludeDragOperation(_ sender: (any NSDraggingInfo)?) {
        super.concludeDragOperation(sender)
        endFileDrag()
    }

    /// The panel is larger than the visible shape, so a drag only counts once it reaches the shape itself.
    /// Drags that start inside MyNotch (a file dragged out of the Tray) have a local source and are ignored.
    private func updateFileDrag(_ info: any NSDraggingInfo) {
        guard info.draggingSource == nil else { return }
        let isInside = interactiveRect.contains(convert(info.draggingLocation, from: nil))
        guard isInside != isFileDragInside else { return }
        isFileDragInside = isInside
        if isInside {
            fileDragDidEnter?()
        } else {
            fileDragDidExit?()
        }
    }

    private func endFileDrag() {
        guard isFileDragInside else { return }
        isFileDragInside = false
        fileDragDidExit?()
    }

    private var interactiveRect: CGRect {
        let originY = isFlipped ? 0 : bounds.height - interactiveSize.height
        return CGRect(
            x: (bounds.width - interactiveSize.width) / 2,
            y: originY,
            width: interactiveSize.width,
            height: interactiveSize.height
        )
    }
}
