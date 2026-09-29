import SwiftUI

struct TrayView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let tray = model.tray
        VStack(spacing: 6) {
            HStack {
                WidgetTitle(text: tray.items.isEmpty ? "Tray" : "Tray · \(tray.items.count)")
                if !tray.items.isEmpty {
                    Button("Clear", action: model.clearTray)
                        .buttonStyle(NotchButtonStyle())
                }
            }
            if tray.items.isEmpty {
                WidgetMessage(systemImage: "tray.and.arrow.down", message: "Drag files onto the notch to keep them here")
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 10) {
                        ForEach(tray.items) { TrayTile(item: $0) }
                    }
                }
                .scrollIndicators(.never)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            model.addToTray(urls)
            return true
        }
    }
}

private struct TrayTile: View {
    @Environment(AppModel.self) private var model
    let item: TrayItem
    @State private var thumbnail: NSImage?
    @State private var isHovering = false

    var body: some View {
        let fileURL = model.tray.resolvedURL(for: item)
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                thumbnailImage
                    .frame(width: 56, height: 56)
                if isHovering {
                    Button { model.removeFromTray(item.id) } label: { Image(systemName: "xmark") }
                        .buttonStyle(NotchIconButtonStyle(size: 18))
                        .offset(x: 6, y: -6)
                }
            }
            Text(item.displayName)
                .font(.system(size: 10))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 72)
        }
        .opacity(fileURL == nil ? 0.4 : 1)
        .onHover { isHovering = $0 }
        .onDrag { fileURL.flatMap(NSItemProvider.init(contentsOf:)) ?? NSItemProvider() }
        .task(id: item.id) {
            guard let fileURL else { return }
            thumbnail = await model.trayThumbnails.thumbnail(for: item, fileURL: fileURL)
        }
    }

    @ViewBuilder
    private var thumbnailImage: some View {
        if let thumbnail {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "doc")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
