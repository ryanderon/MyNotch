import CoreGraphics
import Foundation

/// Sample content for demo mode (screenshots, trying the app without Spotify). Nothing here is persisted.
enum DemoContent {
    static let trackID = "demo:track"

    static func nowPlaying(at date: Date) -> NowPlaying {
        NowPlaying(
            trackID: trackID,
            title: "Midnight Notch",
            artist: "The Menu Bars",
            album: "Demo Mode",
            duration: 214,
            isPlaying: true,
            position: 48,
            positionDate: date
        )
    }

    /// A generated gradient cover, so demo mode needs no bundled image and no network.
    static func artwork() -> ProcessedArtwork? {
        let size = ArtworkProcessor.maximumPixelSize
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let colors = [
            CGColor(srgbRed: 0.98, green: 0.36, blue: 0.53, alpha: 1),
            CGColor(srgbRed: 0.36, green: 0.42, blue: 0.98, alpha: 1)
        ] as CFArray
        guard let context = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) else {
            return nil
        }
        context.drawLinearGradient(
            gradient,
            start: .zero,
            end: CGPoint(x: size, y: size),
            options: []
        )
        guard let image = context.makeImage() else { return nil }
        return ProcessedArtwork(image: image, dominantColor: CGColor(srgbRed: 0.8, green: 0.45, blue: 1, alpha: 1))
    }
}
