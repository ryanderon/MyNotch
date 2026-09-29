import SwiftUI

/// The open panel: a header row that wraps around the physical notch, then the Nook grid or the Tray.
/// Everything in here only exists while the notch is open, so closing releases it.
struct OpenNotchView: View {
    @Environment(AppModel.self) private var model
    let tab: NookTab
    let layout: NotchLayout

    var body: some View {
        VStack(spacing: layout.contentPadding) {
            OpenNotchHeader(tab: tab, layout: layout)
            Group {
                switch tab {
                case .nook: NookGridView()
                case .tray: TrayView()
                }
            }
            .frame(height: NotchLayout.contentHeight)
            .padding(.horizontal, layout.contentPadding)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .foregroundStyle(.white)
    }
}

private struct OpenNotchHeader: View {
    @Environment(AppModel.self) private var model
    let tab: NookTab
    let layout: NotchLayout

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                TabButton(title: "Nook", systemImage: "square.grid.2x2", isSelected: tab == .nook) {
                    model.coordinator.open(.nook)
                }
                .disabled(!model.settings.nook.isEnabled)
                TabButton(title: "Tray", systemImage: "tray", isSelected: tab == .tray) {
                    model.coordinator.open(.tray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear.frame(width: layout.notchSize.width)

            HStack(spacing: 6) {
                HeaderCompanions()
                Button(action: model.openSettings) {
                    Image(systemName: "gearshape.fill")
                }
                .buttonStyle(NotchIconButtonStyle(size: 22))
                .help("Settings")
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: layout.barHeight)
        .padding(.horizontal, layout.contentPadding)
    }
}

private struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .opacity(isSelected ? 1 : 0.55)
        }
        .buttonStyle(NotchButtonStyle(isProminent: isSelected))
    }
}
