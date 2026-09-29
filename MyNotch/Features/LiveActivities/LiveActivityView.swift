import SwiftUI

/// A live activity widens the notch: content sits in two wings, the physical notch stays black in the middle.
struct LiveActivityView: View {
    @Environment(AppModel.self) private var model
    let activity: LiveActivity
    let layout: NotchLayout

    var body: some View {
        HStack(spacing: 0) {
            wing { leading }
            Color.clear.frame(width: layout.notchSize.width)
            wing { trailing }
        }
        .frame(height: layout.barHeight)
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture { model.coordinator.activityTapped() }
    }

    private func wing(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(width: NotchLayout.liveActivityWingWidth, height: layout.barHeight)
    }

    @ViewBuilder
    private var leading: some View {
        switch activity {
        case .media: MediaArtworkThumbnail(size: layout.barHeight - 8)
        case .filesTray: ActivityIcon(systemImage: "tray.full.fill", tint: .white)
        case .calendar: ActivityIcon(systemImage: "calendar", tint: .red)
        case .newUpdate: ActivityIcon(systemImage: "arrow.down.circle.fill", tint: .blue)
        case .bluetooth(let event): ActivityIcon(systemImage: event.deviceKind.systemImage, tint: .white)
        case .battery(let event): ActivityIcon(systemImage: event.systemImage, tint: event.tint)
        case .timerEnded: ActivityIcon(systemImage: "timer", tint: .orange)
        }
    }

    @ViewBuilder
    private var trailing: some View {
        switch activity {
        case .media:
            MediaActivityVisualizer()
                .frame(width: layout.barHeight - 10, height: layout.barHeight - 14)
        case .filesTray(let count):
            ActivityText(count == 1 ? "1 file" : "\(count) files")
        case .calendar(let event):
            ActivityText(event.startDate.formatted(date: .omitted, time: .shortened))
        case .newUpdate(let version):
            ActivityText(version)
        case .bluetooth(let event):
            ActivityText(event.isConnected ? "Connected" : "Disconnected", tint: event.isConnected ? .green : .secondary)
        case .battery(let event):
            ActivityText("\(event.level)%", tint: event.tint)
        case .timerEnded:
            ActivityText("Done", tint: .orange)
        }
    }
}

private struct ActivityIcon: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(tint)
    }
}

private struct ActivityText: View {
    let text: String
    let tint: Color

    init(_ text: String, tint: Color = .white) {
        self.text = text
        self.tint = tint
    }

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

private struct MediaActivityVisualizer: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let liveActivities = model.settings.liveActivities
        MediaVisualizer(
            effect: liveActivities.mediaEffect,
            tint: model.media.visualizerTint(colored: liveActivities.coloredEffects),
            gifPath: liveActivities.gifPath,
            isAnimating: model.media.nowPlaying?.isPlaying == true && model.isNotchVisibleToUser
        )
    }
}

extension BluetoothDeviceEvent.DeviceKind {
    var systemImage: String {
        switch self {
        case .headphones: "airpodspro"
        case .keyboard: "keyboard"
        case .mouse: "computermouse"
        case .other: "wave.3.right"
        }
    }
}

extension BatteryEvent {
    var systemImage: String {
        switch reason {
        case .pluggedIn: "battery.100percent.bolt"
        case .unplugged: level > 50 ? "battery.75percent" : "battery.50percent"
        case .low: "battery.25percent"
        }
    }

    var tint: Color {
        switch reason {
        case .pluggedIn: .green
        case .unplugged: .white
        case .low: .red
        }
    }
}
