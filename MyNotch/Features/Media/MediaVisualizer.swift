import AppKit
import SwiftUI

/// SwiftUI wrapper around a layer-backed view, so the visualizer's motion never re-renders SwiftUI.
struct MediaVisualizer: NSViewRepresentable {
    let effect: MediaEffect
    let tint: CGColor
    let gifPath: String
    let isAnimating: Bool

    func makeNSView(context: Context) -> MediaVisualizerView {
        MediaVisualizerView()
    }

    func updateNSView(_ view: MediaVisualizerView, context: Context) {
        view.configure(MediaVisualizerView.Configuration(
            effect: effect,
            tint: tint,
            gifPath: gifPath,
            isAnimating: isAnimating
        ))
    }
}

final class MediaVisualizerView: NSView {
    struct Configuration: Equatable {
        let effect: MediaEffect
        let tint: CGColor
        let gifPath: String
        let isAnimating: Bool
    }

    private var configuration: Configuration?
    private var effectLayer: CALayer?
    private var gifView: NSImageView?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    func configure(_ newConfiguration: Configuration) {
        guard newConfiguration != configuration else { return }
        configuration = newConfiguration
        rebuild()
    }

    override func layout() {
        super.layout()
        if effectLayer?.frame.size != bounds.size {
            rebuild()
        }
    }

    /// Rebuilding is cheap and only happens on configuration or size changes, never per frame.
    private func rebuild() {
        effectLayer?.removeFromSuperlayer()
        effectLayer = nil
        gifView?.removeFromSuperview()
        gifView = nil
        guard let configuration, bounds.width > 0, bounds.height > 0 else { return }
        if configuration.effect == .gif {
            showGIF(configuration)
        } else {
            showLayer(configuration)
        }
    }

    private func showLayer(_ configuration: Configuration) {
        let layer: CALayer = switch configuration.effect {
        case .spectrograph: VisualizerLayers.spectrograph(in: bounds, tint: configuration.tint)
        case .waves: VisualizerLayers.waves(in: bounds, tint: configuration.tint)
        case .vibratingCircle, .gif: VisualizerLayers.vibratingCircle(in: bounds, tint: configuration.tint)
        }
        self.layer?.addSublayer(layer)
        effectLayer = layer
        if configuration.isAnimating {
            VisualizerLayers.startAnimating(layer, effect: configuration.effect)
        }
    }

    /// NSImageView plays GIF frames itself; `animates` is switched off whenever playback pauses.
    private func showGIF(_ configuration: Configuration) {
        let imageView = NSImageView(frame: bounds)
        imageView.autoresizingMask = [.width, .height]
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.image = configuration.gifPath.isEmpty ? nil : NSImage(contentsOfFile: configuration.gifPath)
        imageView.animates = configuration.isAnimating
        addSubview(imageView)
        gifView = imageView
    }
}
