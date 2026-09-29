import CoreGraphics

/// Faces and little accessories (sleep marks, heart, alert, food bowl) shared by every pet type.
enum PetFaceDrawing {
    static func drawEyes(_ eyes: PetPose.Eyes, body: CGRect, in context: CGContext) {
        let eyeY = body.minY + body.height * 0.58
        let centers = [CGPoint(x: body.midX - 3.6, y: eyeY), CGPoint(x: body.midX + 3.6, y: eyeY)]
        context.setFillColor(PetPalette.ink)
        context.setStrokeColor(PetPalette.ink)
        context.setLineWidth(1.1)
        context.setLineCap(.round)
        for center in centers {
            switch eyes {
            case .open:
                context.fillEllipse(in: CGRect(x: center.x - 1.4, y: center.y - 1.6, width: 2.8, height: 3.2))
            case .wide:
                context.fillEllipse(in: CGRect(x: center.x - 1.9, y: center.y - 1.9, width: 3.8, height: 3.8))
            case .closed:
                context.move(to: CGPoint(x: center.x - 1.6, y: center.y))
                context.addLine(to: CGPoint(x: center.x + 1.6, y: center.y))
                context.strokePath()
            case .happy:
                context.addArc(center: CGPoint(x: center.x, y: center.y - 0.8), radius: 1.6,
                               startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: false)
                context.strokePath()
            case .sad:
                context.fillEllipse(in: CGRect(x: center.x - 1.2, y: center.y - 1.6, width: 2.4, height: 2.6))
                let isLeft = center.x < body.midX
                context.move(to: CGPoint(x: center.x - 1.8, y: center.y + (isLeft ? 1.8 : 2.8)))
                context.addLine(to: CGPoint(x: center.x + 1.8, y: center.y + (isLeft ? 2.8 : 1.8)))
                context.strokePath()
            }
        }
        context.setFillColor(PetPalette.blush)
        context.fillEllipse(in: CGRect(x: body.midX - 7.5, y: eyeY - 3.5, width: 2.6, height: 1.6))
        context.fillEllipse(in: CGRect(x: body.midX + 4.9, y: eyeY - 3.5, width: 2.6, height: 1.6))
    }

    static func drawMouth(_ mouth: PetPose.Mouth, type: PetType, body: CGRect, in context: CGContext) {
        // The dog's snout already carries its nose; its mouth sits a little lower.
        let mouthY = body.minY + body.height * (type == .dog ? 0.22 : 0.36)
        context.setStrokeColor(PetPalette.ink)
        context.setFillColor(PetPalette.ink)
        context.setLineWidth(1)
        switch mouth {
        case .smile:
            context.addArc(center: CGPoint(x: body.midX, y: mouthY + 1), radius: 1.4,
                           startAngle: .pi * 1.15, endAngle: .pi * 1.85, clockwise: false)
            context.strokePath()
        case .open:
            context.fillEllipse(in: CGRect(x: body.midX - 1.3, y: mouthY - 0.6, width: 2.6, height: 2.2))
        }
    }

    static func draw(_ accessory: PetPose.Accessory, body: CGRect, in context: CGContext) {
        switch accessory {
        case .sleep: drawSleepMarks(near: CGPoint(x: body.maxX - 1, y: body.maxY + 2), in: context)
        case .heart: drawHeart(at: CGPoint(x: body.maxX, y: body.maxY + 3), in: context)
        case .alert: drawAlert(at: CGPoint(x: body.maxX + 1, y: body.maxY + 1), in: context)
        case .food: drawBowl(at: CGPoint(x: body.minX - 1, y: body.minY), in: context)
        }
    }

    private static func drawSleepMarks(near origin: CGPoint, in context: CGContext) {
        context.setStrokeColor(PetPalette.white)
        context.setLineWidth(0.9)
        for (index, size) in [CGFloat(3), 2.2].enumerated() {
            let corner = CGPoint(x: origin.x + CGFloat(index) * 3.2, y: origin.y + CGFloat(index) * 3.5)
            context.move(to: CGPoint(x: corner.x, y: corner.y + size))
            context.addLine(to: CGPoint(x: corner.x + size, y: corner.y + size))
            context.addLine(to: CGPoint(x: corner.x, y: corner.y))
            context.addLine(to: CGPoint(x: corner.x + size, y: corner.y))
            context.strokePath()
        }
    }

    private static func drawHeart(at center: CGPoint, in context: CGContext) {
        context.setFillColor(CGColor(srgbRed: 1, green: 0.36, blue: 0.47, alpha: 1))
        context.fillEllipse(in: CGRect(x: center.x - 2.4, y: center.y, width: 2.6, height: 2.6))
        context.fillEllipse(in: CGRect(x: center.x - 0.2, y: center.y, width: 2.6, height: 2.6))
        context.move(to: CGPoint(x: center.x - 2.3, y: center.y + 1.1))
        context.addLine(to: CGPoint(x: center.x, y: center.y - 2.4))
        context.addLine(to: CGPoint(x: center.x + 2.3, y: center.y + 1.1))
        context.fillPath()
    }

    private static func drawAlert(at origin: CGPoint, in context: CGContext) {
        context.setFillColor(CGColor(srgbRed: 1, green: 0.8, blue: 0.2, alpha: 1))
        context.fill(CGRect(x: origin.x, y: origin.y + 2, width: 1.4, height: 4))
        context.fillEllipse(in: CGRect(x: origin.x, y: origin.y, width: 1.4, height: 1.4))
    }

    private static func drawBowl(at origin: CGPoint, in context: CGContext) {
        context.setFillColor(CGColor(srgbRed: 0.35, green: 0.55, blue: 0.95, alpha: 1))
        context.addArc(center: CGPoint(x: origin.x, y: origin.y + 2.5), radius: 2.5,
                       startAngle: .pi, endAngle: 0, clockwise: true)
        context.fillPath()
    }
}
