import SwiftUI

struct PetSettingsView: View {
    @Bindable var pet: PetSettings

    var body: some View {
        Form {
            Section {
                Toggle("Enable Pet", isOn: $pet.isEnabled)
            } footer: {
                Text("A pet that lives in your notch. Feed it and play with it from the nook; it never dies, "
                    + "but it may wander off if neglected.")
            }
            Section("Choose your pet") {
                HStack(spacing: 16) {
                    ForEach(PetType.allCases) { type in
                        PetChoice(type: type, isSelected: pet.type == type) { pet.type = type }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(!pet.isEnabled)
            Section {
                Toggle("Notify me when my pet is hungry", isOn: $pet.hungerNotifications)
            }
            .disabled(!pet.isEnabled)
        }
        .formStyle(.grouped)
    }
}

private struct PetChoice: View {
    let type: PetType
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(spacing: 6) {
                if let image = PetSpriteRenderer.render(type, pose: PetPose(eyes: .happy)) {
                    Image(decorative: image, scale: PetSpriteRenderer.scale)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 56, height: 56)
                }
                Text(type.title)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.black.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
