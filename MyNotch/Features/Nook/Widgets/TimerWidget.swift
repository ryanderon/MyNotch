import SwiftUI

struct TimerWidget: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let countdown = model.countdown
        VStack(spacing: 8) {
            WidgetTitle(text: "Timer")
            RemainingTimeText(countdown: countdown)
            switch countdown.state {
            case .idle:
                PresetGrid(countdown: countdown)
            case .running:
                controls(primaryTitle: "Pause", primaryAction: countdown.pause, countdown: countdown)
            case .paused:
                controls(primaryTitle: "Resume", primaryAction: countdown.resume, countdown: countdown)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func controls(primaryTitle: String, primaryAction: @escaping () -> Void, countdown: CountdownTimer) -> some View {
        HStack(spacing: 6) {
            Button(primaryTitle, action: primaryAction)
                .buttonStyle(NotchButtonStyle(isProminent: true))
            Button("Reset", action: countdown.reset)
                .buttonStyle(NotchButtonStyle())
        }
    }
}

/// Ticks once per second only while the countdown runs; idle or paused, it renders a static value.
private struct RemainingTimeText: View {
    let countdown: CountdownTimer

    var body: some View {
        let isRunning = if case .running = countdown.state { true } else { false }
        TimelineView(.periodic(from: .now, by: isRunning ? 1 : 3600)) { context in
            Text(Duration.seconds(countdown.remaining(at: context.date).rounded(.up))
                .formatted(.time(pattern: .minuteSecond)))
                .font(.system(size: 26, weight: .semibold).monospacedDigit())
        }
    }
}

private struct PresetGrid: View {
    let countdown: CountdownTimer

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 34), spacing: 4)], spacing: 4) {
            ForEach(CountdownTimer.presetMinutes, id: \.self) { minutes in
                Button("\(minutes)m") { countdown.start(minutes: minutes) }
                    .buttonStyle(NotchButtonStyle())
            }
        }
    }
}
