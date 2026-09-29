import SwiftUI

/// Appears while a file drag hovers the notch. v1 has exactly two fixed targets: AirDrop and Tray.
struct DropAreaView: View {
    let layout: NotchLayout

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: layout.barHeight)
            HStack(spacing: 10) {
                DropTarget(kind: .airDrop)
                DropTarget(kind: .tray)
            }
            .padding(.horizontal, layout.contentPadding)
            .padding(.bottom, layout.contentPadding)
        }
        .foregroundStyle(.white)
    }
}

private struct DropTarget: View {
    enum Kind {
        case airDrop
        case tray

        var title: String {
            switch self {
            case .airDrop: "AirDrop"
            case .tray: "Tray"
            }
        }

        var systemImage: String {
            switch self {
            case .airDrop: "airplayaudio"
            case .tray: "tray.and.arrow.down.fill"
            }
        }
    }

    @Environment(AppModel.self) private var model
    let kind: Kind
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: kind.systemImage)
                .font(.system(size: 24, weight: .semibold))
            Text(kind.title)
                .font(.system(size: 12, weight: .semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(.white.opacity(isTargeted ? 0.9 : 0.35))
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(isTargeted ? 0.15 : 0.05)))
        )
        .scaleEffect(isTargeted ? 1.03 : 1)
        .animation(.spring(duration: 0.2), value: isTargeted)
        .dropDestination(for: URL.self) { urls, _ in
            handleDrop(urls)
            return true
        } isTargeted: { isTargeted = $0 }
    }

    private func handleDrop(_ urls: [URL]) {
        switch kind {
        case .airDrop: model.sendViaAirDrop(urls)
        case .tray: model.addToTray(urls)
        }
    }
}
