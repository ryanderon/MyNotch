import CoreGraphics

/// Draws the pets procedurally (original art, simple shapes) into small bitmaps. Frames are rendered once
/// when the pet is enabled and cached by PetSpriteSheet; nothing is drawn per frame.
enum PetSpriteRenderer {
    /// Drawing happens in a 32x32 point canvas rendered at 2x.
    static let canvasSize: CGFloat = 32
    static let scale: CGFloat = 2

    static func render(_ type: PetType, pose: PetPose) -> CGImage? {
        let pixels = Int(canvasSize * scale)
        guard let context = CGContext(
            data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.scaleBy(x: scale, y: scale)
        applyPoseTransform(pose, in: context)
        let body = bodyRect(for: type, squash: pose.squash)
        PetBodyDrawing.draw(type, body: body, in: context)
        PetFaceDrawing.drawEyes(pose.eyes, body: body, in: context)
        PetFaceDrawing.drawMouth(pose.mouth, type: type, body: body, in: context)
        if let accessory = pose.accessory {
            PetFaceDrawing.draw(accessory, body: body, in: context)
        }
        return context.makeImage()
    }

    private static func applyPoseTransform(_ pose: PetPose, in context: CGContext) {
        let pivot = CGPoint(x: canvasSize / 2, y: 4)
        context.translateBy(x: pivot.x, y: pivot.y + pose.bounce)
        context.rotate(by: pose.tilt)
        context.translateBy(x: -pivot.x, y: -pivot.y)
    }

    private static func bodyRect(for type: PetType, squash: CGFloat) -> CGRect {
        let baseHeight: CGFloat = type == .blob ? 16 : 15
        let height = baseHeight * squash
        let width: CGFloat = type == .blob ? 20 : 18
        return CGRect(x: (canvasSize - width) / 2, y: 4, width: width, height: height)
    }
}

enum PetPalette {
    static func body(_ type: PetType) -> CGColor {
        switch type {
        case .cat: CGColor(srgbRed: 0.98, green: 0.63, blue: 0.27, alpha: 1)
        case .dog: CGColor(srgbRed: 0.80, green: 0.62, blue: 0.43, alpha: 1)
        case .blob: CGColor(srgbRed: 0.45, green: 0.88, blue: 0.73, alpha: 1)
        }
    }

    static func accent(_ type: PetType) -> CGColor {
        switch type {
        case .cat: CGColor(srgbRed: 0.85, green: 0.45, blue: 0.16, alpha: 1)
        case .dog: CGColor(srgbRed: 0.52, green: 0.36, blue: 0.24, alpha: 1)
        case .blob: CGColor(srgbRed: 0.27, green: 0.70, blue: 0.57, alpha: 1)
        }
    }

    static let ink = CGColor(srgbRed: 0.10, green: 0.10, blue: 0.12, alpha: 1)
    static let blush = CGColor(srgbRed: 1, green: 0.55, blue: 0.62, alpha: 0.8)
    static let white = CGColor(gray: 1, alpha: 1)
}
