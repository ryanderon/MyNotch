import QuartzCore

/// Procedural visualizer layers. This is not audio analysis (that would need audio capture permission and
/// real CPU); the motion is a Core Animation loop that the render server plays, so the app itself does no
/// per-frame work. Frame rate is capped at 30 fps per the power budget.
enum VisualizerLayers {
    static let animationKey = "visualizer"
    private static let frameRateRange = CAFrameRateRange(minimum: 10, maximum: 30, preferred: 30)

    static func spectrograph(in bounds: CGRect, tint: CGColor) -> CALayer {
        let barCount = 5
        let barWidth = max(bounds.width / CGFloat(barCount * 2 - 1), 2)
        let replicator = CAReplicatorLayer()
        replicator.frame = bounds
        replicator.instanceCount = barCount
        replicator.instanceTransform = CATransform3DMakeTranslation(barWidth * 2, 0, 0)
        replicator.instanceDelay = 0.13

        let bar = CALayer()
        bar.frame = CGRect(x: 0, y: 0, width: barWidth, height: bounds.height)
        bar.cornerRadius = barWidth / 2
        bar.backgroundColor = tint
        bar.transform = CATransform3DMakeScale(1, 0.3, 1)
        replicator.addSublayer(bar)
        return replicator
    }

    static func waves(in bounds: CGRect, tint: CGColor) -> CALayer {
        let container = CALayer()
        container.frame = bounds
        container.masksToBounds = true
        let wave = CAShapeLayer()
        wave.frame = CGRect(x: 0, y: 0, width: bounds.width * 2, height: bounds.height)
        wave.path = sinePath(width: bounds.width * 2, height: bounds.height, periods: 4)
        wave.strokeColor = tint
        wave.fillColor = nil
        wave.lineWidth = 2
        wave.lineCap = .round
        container.addSublayer(wave)
        return container
    }

    static func vibratingCircle(in bounds: CGRect, tint: CGColor) -> CALayer {
        let diameter = min(bounds.width, bounds.height) * 0.8
        let circle = CAShapeLayer()
        circle.frame = CGRect(x: (bounds.width - diameter) / 2, y: (bounds.height - diameter) / 2,
                              width: diameter, height: diameter)
        circle.path = CGPath(ellipseIn: CGRect(origin: .zero, size: circle.frame.size), transform: nil)
        circle.fillColor = tint.copy(alpha: 0.35)
        circle.strokeColor = tint
        circle.lineWidth = 2
        circle.transform = CATransform3DMakeScale(0.8, 0.8, 1)
        return circle
    }

    /// Starts the loop that matches the layer built for `effect`.
    static func startAnimating(_ layer: CALayer, effect: MediaEffect) {
        switch effect {
        case .spectrograph:
            layer.sublayers?.first?.add(barAnimation(), forKey: animationKey)
        case .waves:
            guard let wave = layer.sublayers?.first else { return }
            wave.add(scrollAnimation(distance: layer.bounds.width / 2), forKey: animationKey)
        case .vibratingCircle:
            layer.add(pulseAnimation(), forKey: animationKey)
        case .gif:
            break
        }
    }

    static func stopAnimating(_ layer: CALayer) {
        layer.removeAnimation(forKey: animationKey)
        layer.sublayers?.forEach { $0.removeAnimation(forKey: animationKey) }
    }

    private static func barAnimation() -> CAAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale.y")
        animation.fromValue = 0.3
        animation.toValue = 1.0
        animation.duration = 0.42
        return looping(animation)
    }

    private static func scrollAnimation(distance: CGFloat) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = 0
        animation.toValue = -distance
        animation.duration = 1.2
        animation.autoreverses = false
        animation.repeatCount = .infinity
        animation.preferredFrameRateRange = frameRateRange
        return animation
    }

    private static func pulseAnimation() -> CAAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 0.8
        animation.toValue = 1.05
        animation.duration = 0.28
        return looping(animation)
    }

    private static func looping(_ animation: CABasicAnimation) -> CAAnimation {
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.preferredFrameRateRange = frameRateRange
        return animation
    }

    private static func sinePath(width: CGFloat, height: CGFloat, periods: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let amplitude = height * 0.35
        let steps = Int(width)
        for step in 0...steps {
            let x = CGFloat(step)
            let y = height / 2 + amplitude * sin(x / width * periods * 2 * .pi)
            if step == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}
