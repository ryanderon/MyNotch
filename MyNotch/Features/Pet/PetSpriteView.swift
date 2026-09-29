import AppKit
import SwiftUI

/// Shows a pet animation on a CALayer. Multi-frame animations are a discrete keyframe animation of
/// `contents` played by the render server; single-frame states are just a static image.
struct PetSpriteView: NSViewRepresentable {
    let frames: [CGImage]
    let isAnimating: Bool

    func makeNSView(context: Context) -> PetSpriteLayerView {
        PetSpriteLayerView()
    }

    func updateNSView(_ view: PetSpriteLayerView, context: Context) {
        view.show(frames: frames, isAnimating: isAnimating)
    }
}

final class PetSpriteLayerView: NSView {
    private static let animationKey = "frames"
    private var shownFrames: [CGImage] = []
    private var isAnimating = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.contentsGravity = .resizeAspect
        layer?.magnificationFilter = .nearest
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show(frames: [CGImage], isAnimating: Bool) {
        guard frames != shownFrames || isAnimating != self.isAnimating else { return }
        shownFrames = frames
        self.isAnimating = isAnimating
        layer?.removeAnimation(forKey: Self.animationKey)
        layer?.contents = frames.first
        guard isAnimating, frames.count > 1 else { return }
        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = frames
        animation.calculationMode = .discrete
        animation.duration = Double(frames.count) / PetAnimation.framesPerSecond
        animation.repeatCount = .infinity
        animation.preferredFrameRateRange = CAFrameRateRange(
            minimum: 1,
            maximum: Float(PetAnimation.framesPerSecond),
            preferred: Float(PetAnimation.framesPerSecond)
        )
        layer?.add(animation, forKey: Self.animationKey)
    }
}

/// The pet as it currently looks, for any size. Shows an empty spot (paw prints) while it has run away.
struct PetAvatar: View {
    @Environment(AppModel.self) private var model
    let pet: PetStore
    let sprites: PetSpriteSheet
    let size: CGFloat

    var body: some View {
        let isMusicPlaying = model.media.nowPlaying?.isPlaying == true
        let mood = pet.state.mood(at: Date(), isMusicPlaying: isMusicPlaying)
        if let animation = PetAnimation.current(mood: mood, reaction: pet.reaction) {
            PetSpriteView(frames: sprites.frames(for: animation), isAnimating: model.isNotchVisibleToUser)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "pawprint")
                .font(.system(size: size * 0.4))
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: size, height: size)
        }
    }
}
