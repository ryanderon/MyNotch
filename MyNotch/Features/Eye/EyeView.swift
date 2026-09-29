import AppKit
import SwiftUI

/// One eye drawn with Core Animation layers. The tracker moves the pupil layer directly with implicit
/// animations disabled, so following the cursor never triggers a SwiftUI render.
final class EyeLayerView: NSView {
    weak var tracker: EyeTracker?

    private let sclera = CAShapeLayer()
    private let pupil = CALayer()
    private let eyelid = CALayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        sclera.fillColor = NSColor.white.cgColor
        pupil.backgroundColor = NSColor.black.cgColor
        eyelid.backgroundColor = NSColor.black.cgColor
        layer?.addSublayer(sclera)
        sclera.addSublayer(pupil)
        sclera.addSublayer(eyelid)
        sclera.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            tracker?.unregister(self)
        } else {
            tracker?.register(self)
        }
    }

    override func layout() {
        super.layout()
        withoutAnimation {
            sclera.frame = bounds
            sclera.path = CGPath(ellipseIn: bounds, transform: nil)
            sclera.cornerRadius = bounds.width / 2
            let pupilSize = bounds.width * 0.5
            pupil.bounds = CGRect(x: 0, y: 0, width: pupilSize, height: pupilSize)
            pupil.cornerRadius = pupilSize / 2
            pupil.position = CGPoint(x: bounds.midX, y: bounds.midY)
            setLidCoverage(currentCoverage)
        }
    }

    var centerOnScreen: CGPoint? {
        guard let window else { return nil }
        let centerInWindow = convert(CGPoint(x: bounds.midX, y: bounds.midY), to: nil)
        return window.convertPoint(toScreen: centerInWindow)
    }

    func movePupil(by offset: CGVector) {
        withoutAnimation {
            pupil.position = CGPoint(x: bounds.midX + offset.dx, y: bounds.midY + offset.dy)
        }
    }

    var maxPupilOffset: CGFloat { bounds.width * 0.22 }

    private var currentCoverage: CGFloat = 0

    func setEyelid(_ state: EyelidState) {
        currentCoverage = state.coverage
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.35)
        setLidCoverage(state.coverage)
        CATransaction.commit()
    }

    /// A blink is a single short Core Animation run by the render server.
    func blink() {
        let animation = CABasicAnimation(keyPath: "bounds.size.height")
        animation.fromValue = eyelid.bounds.height
        animation.toValue = bounds.height
        animation.duration = 0.09
        animation.autoreverses = true
        eyelid.add(animation, forKey: "blink")
    }

    private func setLidCoverage(_ coverage: CGFloat) {
        let height = bounds.height * coverage
        eyelid.anchorPoint = CGPoint(x: 0.5, y: 1)
        eyelid.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: height)
        eyelid.position = CGPoint(x: bounds.midX, y: bounds.maxY)
    }

    private func withoutAnimation(_ changes: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        changes()
        CATransaction.commit()
    }
}

struct EyeView: NSViewRepresentable {
    let tracker: EyeTracker

    func makeNSView(context: Context) -> EyeLayerView {
        let view = EyeLayerView()
        view.tracker = tracker
        return view
    }

    func updateNSView(_ nsView: EyeLayerView, context: Context) {}
}

/// Two eyes side by side, used on the closed notch wings and in the open panel header.
struct EyePair: View {
    @Environment(AppModel.self) private var model
    let diameter: CGFloat

    var body: some View {
        HStack(spacing: diameter * 0.3) {
            EyeView(tracker: model.eyeTracker)
            EyeView(tracker: model.eyeTracker)
        }
        .frame(width: diameter * 2.3, height: diameter)
    }
}
