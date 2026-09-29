import SwiftUI

/// Widgets laid out in cells, in the user's order. Widgets are created when the nook opens and
/// destroyed when it closes, so none of them costs anything while the notch is closed.
struct NookGridView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let widgets = model.settings.nook.enabledWidgets
        let showsDividers = model.settings.nook.showDividers
        if widgets.isEmpty && model.petCompanion == nil {
            EmptyNookView()
        } else {
            HStack(spacing: 0) {
                ForEach(Array(widgets.enumerated()), id: \.element.kind) { index, placement in
                    if index > 0 && showsDividers {
                        NookDivider()
                    }
                    NookWidgetView(kind: placement.kind)
                        .frame(width: CGFloat(placement.width) * NotchLayout.cellWidth)
                }
                if let companion = model.petCompanion {
                    if !widgets.isEmpty && showsDividers {
                        NookDivider()
                    }
                    PetStatusCard(pet: companion.store, sprites: companion.sprites)
                        .padding(.horizontal, 6)
                        .frame(width: CGFloat(PetLayout.cardWidth) * NotchLayout.cellWidth)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct NookWidgetView: View {
    let kind: NookWidgetKind

    var body: some View {
        Group {
            switch kind {
            case .mediaPlayer: MediaPlayerWidget()
            case .mirror: MirrorWidget()
            case .notes: NotesWidget()
            case .calendar: CalendarWidget()
            case .shortcuts: ShortcutsWidget()
            case .todos: TodosWidget()
            case .timer: TimerWidget()
            }
        }
        .padding(.horizontal, 6)
        .frame(maxHeight: .infinity)
    }
}

private struct NookDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .frame(width: 1)
            .padding(.vertical, 12)
            .padding(.horizontal, (NotchLayout.dividerWidth - 1) / 2)
    }
}

private struct EmptyNookView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 8) {
            Text("No widgets enabled")
                .font(.headline)
            Button("Choose Widgets…", action: model.openSettings)
                .buttonStyle(NotchButtonStyle(isProminent: true))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Small shared title used at the top of every widget.
struct WidgetTitle: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.white.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Placeholder shown when a widget can't show content yet (no permission, nothing playing, etc.).
struct WidgetMessage: View {
    let systemImage: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.6))
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(NotchButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
