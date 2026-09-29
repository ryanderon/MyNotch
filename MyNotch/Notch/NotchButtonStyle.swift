import SwiftUI

/// The "Prefer round buttons" setting: capsules or rounded rectangles for every button inside the notch.
enum NotchButtonShape {
    case capsule
    case roundedRectangle
}

extension EnvironmentValues {
    @Entry var notchButtonShape: NotchButtonShape = .capsule
}

struct NotchButtonStyle: ButtonStyle {
    @Environment(\.notchButtonShape) private var shape
    var isProminent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(background(isPressed: configuration.isPressed))
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private func background(isPressed: Bool) -> some View {
        let fill = Color.white.opacity(isPressed ? 0.3 : (isProminent ? 0.22 : 0.12))
        switch shape {
        case .capsule: Capsule().fill(fill)
        case .roundedRectangle: RoundedRectangle(cornerRadius: 6).fill(fill)
        }
    }
}

/// Icon-only variant used for transport controls and small toolbar actions.
struct NotchIconButtonStyle: ButtonStyle {
    @Environment(\.notchButtonShape) private var shape
    var size: CGFloat = 26

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(background(isPressed: configuration.isPressed))
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private func background(isPressed: Bool) -> some View {
        let fill = Color.white.opacity(isPressed ? 0.28 : 0.1)
        switch shape {
        case .capsule: Circle().fill(fill)
        case .roundedRectangle: RoundedRectangle(cornerRadius: 6).fill(fill)
        }
    }
}
