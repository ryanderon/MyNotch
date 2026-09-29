import SwiftUI

enum PetLayout {
    /// Width of the pet's status card in the nook, in cells.
    static let cardWidth = 4
}

/// The pet's card in the open nook: stats and the four care actions.
struct PetStatusCard: View {
    @Environment(AppModel.self) private var model
    let pet: PetStore
    let sprites: PetSpriteSheet
    @State private var isPlaying = false

    var body: some View {
        let now = Date()
        let state = pet.state
        VStack(spacing: 4) {
            WidgetTitle(text: "\(sprites.type.title) · Level \(state.level)")
            if isPlaying {
                PetPlayGame { reward in
                    isPlaying = false
                    pet.play(reward: reward)
                }
            } else {
                HStack(spacing: 8) {
                    PetAvatar(pet: pet, sprites: sprites, size: 52)
                    VStack(spacing: 4) {
                        StatBar(title: "Food", value: state.hungerLevel(at: now), tint: .orange)
                        StatBar(title: "Fun", value: state.happinessLevel(at: now), tint: .pink)
                        StatBar(title: "Energy", value: state.energyLevel(at: now), tint: .mint)
                    }
                }
                PetActions(pet: pet, hasRunAway: state.hasRunAway(at: now), startGame: { isPlaying = true })
            }
        }
    }
}

private struct StatBar: View {
    let title: String
    let value: Double
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 34, alignment: .leading)
            ProgressView(value: value, total: 100)
                .tint(tint)
                .controlSize(.mini)
        }
    }
}

private struct PetActions: View {
    let pet: PetStore
    let hasRunAway: Bool
    let startGame: () -> Void

    var body: some View {
        if hasRunAway {
            Button("Call back with food", action: pet.feed)
                .buttonStyle(NotchButtonStyle(isProminent: true))
        } else {
            HStack(spacing: 4) {
                Button(action: pet.feed) { Image(systemName: "fork.knife") }.help("Feed")
                Button(action: startGame) { Image(systemName: "gamecontroller") }.help("Play")
                Button(action: pet.pet) { Image(systemName: "hand.raised") }.help("Pet")
                Button(action: pet.toggleSleep) {
                    Image(systemName: pet.state.isSleeping ? "sun.max" : "moon.zzz")
                }
                .help(pet.state.isSleeping ? "Wake up" : "Sleep")
            }
            .buttonStyle(NotchIconButtonStyle(size: 24))
        }
    }
}
