import SwiftUI

struct MediaArtworkThumbnail: View {
    @Environment(AppModel.self) private var model
    let size: CGFloat

    var body: some View {
        let cornerRadius = CGFloat(model.settings.liveActivities.albumCornerRadius) * size / 24
        Group {
            if let artwork = model.media.artwork {
                Image(decorative: artwork.image, scale: 2)
                    .resizable()
                    .interpolation(.medium)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.12))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension MediaService {
    func visualizerTint(colored: Bool) -> CGColor {
        guard colored, let artwork else { return CGColor(gray: 1, alpha: 1) }
        return artwork.dominantColor
    }
}
