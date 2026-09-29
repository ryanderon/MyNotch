import SwiftUI

/// A tiny click game: catch the ball as many times as possible before time runs out.
/// The game's only timer is the countdown task, which ends with the game.
struct PetPlayGame: View {
    static let duration: Duration = .seconds(6)
    static let rewardPerCatch = 6.0

    let finish: (_ reward: Double) -> Void
    @State private var catches = 0
    @State private var ballPosition = CGPoint(x: 0.5, y: 0.5)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06))
                Text("\(catches)")
                    .font(.system(size: 28, weight: .bold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.15))
                Button(action: catchBall) {
                    Circle().fill(Color.yellow).frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .position(x: ballPosition.x * proxy.size.width, y: ballPosition.y * proxy.size.height)
                .animation(.spring(duration: 0.25), value: ballPosition)
            }
        }
        .task {
            do {
                try await Task.sleep(for: Self.duration)
            } catch {
                return // The nook closed mid-game; no reward.
            }
            finish(Double(catches) * Self.rewardPerCatch + 5)
        }
    }

    private func catchBall() {
        catches += 1
        ballPosition = CGPoint(x: .random(in: 0.12...0.88), y: .random(in: 0.15...0.85))
    }
}
