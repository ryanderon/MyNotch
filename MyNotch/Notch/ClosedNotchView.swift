import SwiftUI

/// The resting notch. Clicking it opens the nook. With Eye or Pet on, each side of the physical notch gets a
/// small wing: eyes on both wings, the pet on the right; with both on, both eyes move to the left wing.
struct ClosedNotchView: View {
    @Environment(AppModel.self) private var model
    let layout: NotchLayout

    var body: some View {
        HStack(spacing: 0) {
            if layout.hasCompanionWings {
                leadingWing.frame(width: NotchLayout.companionWingWidth)
            }
            Color.clear.frame(width: layout.notchSize.width)
            if layout.hasCompanionWings {
                trailingWing.frame(width: NotchLayout.companionWingWidth)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { model.coordinator.open() }
    }

    private var showsEyes: Bool { model.settings.eye.isShownWhenClosed }
    private var eyeDiameter: CGFloat { min(layout.notchSize.height * 0.42, 12) }

    @ViewBuilder
    private var leadingWing: some View {
        if showsEyes {
            if model.petCompanion != nil {
                EyePair(diameter: eyeDiameter)
            } else {
                EyeView(tracker: model.eyeTracker).frame(width: eyeDiameter, height: eyeDiameter)
            }
        }
    }

    @ViewBuilder
    private var trailingWing: some View {
        if let companion = model.petCompanion {
            PetAvatar(pet: companion.store, sprites: companion.sprites, size: layout.notchSize.height - 4)
        } else if showsEyes {
            EyeView(tracker: model.eyeTracker).frame(width: eyeDiameter, height: eyeDiameter)
        }
    }
}

/// Eyes in the open panel's header (Eye "show when open").
struct HeaderCompanions: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.settings.eye.isShownWhenOpen {
            EyePair(diameter: 10)
        }
    }
}
