import SwiftUI

struct SettingsView: View {
    let model: AppModel

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                GeneralSettingsView(settings: model.settings)
            }
            Tab("Gestures", systemImage: "hand.draw") {
                GestureSettingsView(gestures: model.settings.gestures)
            }
            Tab("Live Activities", systemImage: "capsule.tophalf.filled") {
                LiveActivitySettingsView(liveActivities: model.settings.liveActivities)
            }
            Tab("Nook", systemImage: "square.grid.2x2") {
                NookSettingsView(nook: model.settings.nook)
            }
            Tab("Tray", systemImage: "tray") {
                ShelfWidthSettingsView(title: "Tray width", width: Bindable(model.settings.shelf).trayWidth)
            }
            Tab("Drop Area", systemImage: "tray.and.arrow.down") {
                DropAreaSettingsView(shelf: model.settings.shelf)
            }
            Tab("Eye", systemImage: "eye") {
                EyeSettingsView(eye: model.settings.eye)
            }
            Tab("Pet", systemImage: "pawprint") {
                PetSettingsView(pet: model.settings.pet)
            }
            Tab("About", systemImage: "info.circle") {
                AboutSettingsView(updater: model.updater)
            }
        }
        .frame(width: 560, height: 560)
        .environment(model)
    }
}
