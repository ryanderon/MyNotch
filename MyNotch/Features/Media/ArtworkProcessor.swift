import AppKit
import CoreImage
import ImageIO

/// CGImage and CGColor are immutable, so sharing them across the decode task and the UI is safe.
nonisolated struct ProcessedArtwork: @unchecked Sendable {
    let image: CGImage
    /// Average color of the artwork, used to tint the visualizer when "colored effects" is on.
    let dominantColor: CGColor
}

nonisolated enum ArtworkProcessingError: Error {
    case undecodableImage
}

/// Downsamples artwork to twice its display size so only a small bitmap stays in memory.
/// Runs off the main thread (utility QoS), so it is not main-actor isolated.
nonisolated enum ArtworkProcessor {
    static let maximumPixelSize = 128

    static func process(_ data: Data) throws -> ProcessedArtwork {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ArtworkProcessingError.undecodableImage
        }
        return ProcessedArtwork(image: image, dominantColor: averageColor(of: image))
    }

    private static func averageColor(of image: CGImage) -> CGColor {
        let input = CIImage(cgImage: image)
        let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: input,
            kCIInputExtentKey: CIVector(cgRect: input.extent)
        ])
        guard let output = filter?.outputImage else { return CGColor(gray: 1, alpha: 1) }
        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext(options: [.workingColorSpace: NSNull()]).render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )
        return brightened(red: pixel[0], green: pixel[1], blue: pixel[2])
    }

    /// Dark album art would produce an invisible visualizer on the black notch, so the color is lifted.
    private static func brightened(red: UInt8, green: UInt8, blue: UInt8) -> CGColor {
        let color = NSColor(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
        return NSColor(hue: hue, saturation: min(saturation * 1.2, 1), brightness: max(brightness, 0.75), alpha: 1)
            .cgColor
    }
}
