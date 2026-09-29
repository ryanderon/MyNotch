import SwiftUI

struct NotchRootView: View {
    let model: AppModel

    var body: some View {
        if let layout = model.layout, let placement = model.placement {
            NotchShellView(layout: layout, isHandler: placement.geometry.kind == .handler)
                .environment(model)
        }
    }
}

/// The black shape that morphs between presentations. Content views never size the shape;
/// NotchLayout does, so the window, tracking area, and view always agree.
private struct NotchShellView: View {
    @Environment(AppModel.self) private var model
    let layout: NotchLayout
    let isHandler: Bool

    private var presentation: NotchPresentation { model.coordinator.presentation }
    private var isHovering: Bool { model.coordinator.isPointerInside }
    private var size: CGSize { layout.size(for: presentation, isHovering: isHovering) }

    var body: some View {
        NotchContentView(presentation: presentation, layout: layout)
            .frame(width: size.width, height: size.height)
            .background(NotchBackground(presentation: presentation, isHandler: isHandler, isHovering: isHovering))
            .clipShape(shape)
            .contentShape(shape)
            .contextMenu {
                Button("Settings…", action: model.openSettings)
                Button("Quit MyNotch") { NSApplication.shared.terminate(nil) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.spring(duration: 0.35, bounce: 0.15), value: presentation)
            .animation(.spring(duration: 0.2), value: isHovering)
            .environment(\.notchButtonShape, model.settings.general.preferRoundButtons ? .capsule : .roundedRectangle)
    }

    private var shape: UnevenRoundedRectangle {
        let radius = bottomCornerRadius
        return UnevenRoundedRectangle(bottomLeadingRadius: radius, bottomTrailingRadius: radius)
    }

    private var bottomCornerRadius: CGFloat {
        switch presentation {
        case .closed: isHandler ? size.height / 2 : (isHovering ? 10 : 8)
        case .liveActivity: 12
        case .open: 24
        case .dropArea: 20
        }
    }
}

private struct NotchBackground: View {
    @Environment(AppModel.self) private var model
    let presentation: NotchPresentation
    let isHandler: Bool
    let isHovering: Bool

    var body: some View {
        if presentation.isOpen && model.settings.general.translucentBackground {
            Rectangle().fill(.ultraThinMaterial).overlay(Color.black.opacity(0.55))
        } else {
            Color.black.opacity(isInvisibleHandler ? Self.hitTestableOpacity : 1)
        }
    }

    /// A fully transparent pixel lets clicks and hovers fall through the window, so the invisible handler
    /// keeps a barely-there alpha to stay hoverable.
    private static let hitTestableOpacity = 0.01

    private var isInvisibleHandler: Bool {
        isHandler && presentation == .closed && !isHovering && model.settings.general.handlerTransparent
    }
}

private struct NotchContentView: View {
    @Environment(AppModel.self) private var model
    let presentation: NotchPresentation
    let layout: NotchLayout

    var body: some View {
        switch presentation {
        case .closed:
            ClosedNotchView(layout: layout)
        case .liveActivity(let activity):
            LiveActivityView(activity: activity, layout: layout)
        case .open(let tab):
            OpenNotchView(tab: tab, layout: layout)
        case .dropArea:
            DropAreaView(layout: layout)
        }
    }
}
