import AppKit

/// AppKit entry point instead of a SwiftUI App, so AppDelegate can host the Settings scene itself
/// (NSHostingSceneRepresentation) and open it from the notch.
@main
enum MyNotchMain {
    static func main() {
        // NSApplication holds its delegate weakly; run() never returns, so this local keeps it alive.
        let appDelegate = AppDelegate()
        NSApplication.shared.delegate = appDelegate
        NSApplication.shared.run()
    }
}
