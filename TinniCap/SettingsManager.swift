import Foundation
import CoreAudio

class SettingsManager {
    private let defaults = UserDefaults.standard
    private let deviceLimitsKey = "deviceLimits"
    private let enforcementModeKey = "enforcementMode"
    private let notificationCooldownKey = "notificationCooldown"

    var deviceLimits: [String: Float] = [:]
    var enforcementMode: EnforcementMode = .hardCap
    var notificationCooldownPeriod: TimeInterval = 30.0 // Default: 30 seconds

    func loadSettings() {
        // Load device limits
        if let data = defaults.data(forKey: deviceLimitsKey),
           let decoded = try? JSONDecoder().decode([String: Float].self, from: data) {
            deviceLimits = decoded
        }

        // Load enforcement mode
        if let modeString = defaults.string(forKey: enforcementModeKey),
           let mode = EnforcementMode(rawValue: modeString) {
            enforcementMode = mode
        }

        // Load notification cooldown period
        let cooldown = defaults.double(forKey: notificationCooldownKey)
        if cooldown > 0 {
            notificationCooldownPeriod = cooldown
        }
    }

    func saveSettings() {
        // Save device limits
        if let encoded = try? JSONEncoder().encode(deviceLimits) {
            defaults.set(encoded, forKey: deviceLimitsKey)
        }

        // Save enforcement mode
        defaults.set(enforcementMode.rawValue, forKey: enforcementModeKey)

        // Save notification cooldown period
        defaults.set(notificationCooldownPeriod, forKey: notificationCooldownKey)

        defaults.synchronize()
    }

    func setLimit(for device: AudioDevice, limit: Float) {
        deviceLimits[device.stableIdentifier] = limit
    }

    func getLimit(for device: AudioDevice) -> Float? {
        return deviceLimits[device.stableIdentifier]
    }

    func removeLimit(for device: AudioDevice) {
        deviceLimits.removeValue(forKey: device.stableIdentifier)
    }
}
