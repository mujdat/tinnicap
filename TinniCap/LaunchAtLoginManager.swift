import Foundation
import ServiceManagement

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private let service = SMAppService.mainApp
    private let launchAtLoginKey = "launchAtLogin"

    private init() {}

    var isEnabled: Bool {
        return service.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if service.status != .enabled {
                    try service.register()
                }
            } else {
                if service.status == .enabled {
                    try service.unregister()
                }
            }
            // Save preference
            UserDefaults.standard.set(enabled, forKey: launchAtLoginKey)
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error.localizedDescription)")
        }
    }

    func loadSavedPreference() {
        let savedPreference = UserDefaults.standard.bool(forKey: launchAtLoginKey)
        // Only apply if it differs from current state
        if savedPreference != isEnabled {
            setEnabled(savedPreference)
        }
    }
}
