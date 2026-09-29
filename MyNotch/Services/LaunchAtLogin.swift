import ServiceManagement

/// The login-item state lives in the system (System Settings > General > Login Items), not in UserDefaults,
/// so it is always read from SMAppService instead of being cached.
struct LaunchAtLogin {
    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
    var needsApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    func enable() throws {
        try SMAppService.mainApp.register()
    }

    func disable() throws {
        try SMAppService.mainApp.unregister()
    }
}
