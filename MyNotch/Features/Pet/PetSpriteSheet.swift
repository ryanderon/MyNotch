import CoreGraphics

/// Rendered frames for one pet type. Exists only while the pet is enabled; dropping it releases every bitmap.
final class PetSpriteSheet {
    let type: PetType
    private var cache: [PetAnimation: [CGImage]] = [:]

    init(type: PetType) {
        self.type = type
    }

    func frames(for animation: PetAnimation) -> [CGImage] {
        if let cached = cache[animation] { return cached }
        let frames = animation.poses.compactMap { PetSpriteRenderer.render(type, pose: $0) }
        cache[animation] = frames
        return frames
    }
}
