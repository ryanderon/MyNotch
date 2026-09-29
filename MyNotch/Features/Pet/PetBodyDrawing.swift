import CoreGraphics

/// Silhouettes for each pet type. Coordinates are in the 32x32 point canvas, y pointing up.
enum PetBodyDrawing {
    static func draw(_ type: PetType, body: CGRect, in context: CGContext) {
        switch type {
        case .cat: drawCat(body: body, in: context)
        case .dog: drawDog(body: body, in: context)
        case .blob: drawBlob(body: body, in: context)
        }
    }

    private static func drawCat(body: CGRect, in context: CGContext) {
        context.setFillColor(PetPalette.body(.cat))
        let tail = CGMutablePath()
        tail.move(to: CGPoint(x: body.maxX - 2, y: body.minY + 4))
        tail.addQuadCurve(to: CGPoint(x: body.maxX + 3, y: body.maxY + 1), control: CGPoint(x: body.maxX + 6, y: body.midY))
        context.setStrokeColor(PetPalette.accent(.cat))
        context.setLineWidth(2.2)
        context.setLineCap(.round)
        context.addPath(tail)
        context.strokePath()
        for isLeft in [true, false] {
            let baseX = isLeft ? body.minX + 3 : body.maxX - 3
            let tipX = isLeft ? body.minX + 2 : body.maxX - 2
            let ear = CGMutablePath()
            ear.move(to: CGPoint(x: baseX - 3, y: body.maxY - 3))
            ear.addLine(to: CGPoint(x: tipX, y: body.maxY + 4))
            ear.addLine(to: CGPoint(x: baseX + 3, y: body.maxY - 2))
            ear.closeSubpath()
            context.addPath(ear)
        }
        context.fillPath()
        context.fillEllipse(in: body)
        drawBelly(in: body, color: PetPalette.white.copy(alpha: 0.35), context: context)
    }

    private static func drawDog(body: CGRect, in context: CGContext) {
        context.setStrokeColor(PetPalette.accent(.dog))
        context.setLineWidth(2)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: body.maxX - 1, y: body.minY + 5))
        context.addLine(to: CGPoint(x: body.maxX + 3, y: body.minY + 9))
        context.strokePath()
        context.setFillColor(PetPalette.body(.dog))
        context.fillEllipse(in: body)
        context.setFillColor(PetPalette.accent(.dog))
        let earSize = CGSize(width: 5, height: 9)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: body.minX - 1.5, y: body.maxY - 10), size: earSize))
        context.fillEllipse(in: CGRect(origin: CGPoint(x: body.maxX - 3.5, y: body.maxY - 10), size: earSize))
        let snout = CGRect(x: body.midX - 4, y: body.minY + 3, width: 8, height: 5)
        context.setFillColor(PetPalette.white.copy(alpha: 0.55) ?? PetPalette.white)
        context.fillEllipse(in: snout)
        context.setFillColor(PetPalette.ink)
        context.fillEllipse(in: CGRect(x: body.midX - 1.2, y: snout.maxY - 2.2, width: 2.4, height: 1.8))
    }

    private static func drawBlob(body: CGRect, in context: CGContext) {
        context.setStrokeColor(PetPalette.accent(.blob))
        context.setLineWidth(1.4)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: body.midX, y: body.maxY - 1))
        context.addQuadCurve(to: CGPoint(x: body.midX + 3, y: body.maxY + 5), control: CGPoint(x: body.midX - 1, y: body.maxY + 4))
        context.strokePath()
        context.setFillColor(PetPalette.accent(.blob))
        context.fillEllipse(in: CGRect(x: body.midX + 1.8, y: body.maxY + 4, width: 3, height: 3))
        let jelly = CGPath(roundedRect: body, cornerWidth: body.width / 2, cornerHeight: body.height / 1.6, transform: nil)
        context.setFillColor(PetPalette.body(.blob))
        context.addPath(jelly)
        context.fillPath()
        drawBelly(in: body, color: PetPalette.white.copy(alpha: 0.3), context: context)
    }

    private static func drawBelly(in body: CGRect, color: CGColor?, context: CGContext) {
        guard let color else { return }
        context.setFillColor(color)
        context.fillEllipse(in: CGRect(x: body.midX - 4, y: body.minY + 1, width: 8, height: 5))
    }
}
