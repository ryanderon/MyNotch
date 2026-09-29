import SwiftUI

struct ShelfWidthSettingsView: View {
    let title: String
    @Binding var width: Int

    var body: some View {
        Form {
            Section {
                Stepper(value: $width, in: ShelfSettings.widthRange) {
                    LabeledContent(title, value: "\(width) cells")
                }
            } footer: {
                Text("Files are kept as references, never copied. Drag a file out of the tray into Finder to move it.")
            }
        }
        .formStyle(.grouped)
    }
}

struct DropAreaSettingsView: View {
    @Bindable var shelf: ShelfSettings

    var body: some View {
        Form {
            Section {
                Stepper(value: $shelf.dropAreaWidth, in: ShelfSettings.widthRange) {
                    LabeledContent("Drop area width", value: "\(shelf.dropAreaWidth) cells")
                }
            }
            Section {
                LabeledContent("Targets", value: "AirDrop, Tray")
            } footer: {
                Text("The drop area appears when you drag files onto the notch.")
            }
        }
        .formStyle(.grouped)
    }
}
