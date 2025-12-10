import Foundation
import CoreAudio

class SettingsManager {
    private let defaults = UserDefaults.standard
    private let deviceLimitsKey = "deviceLimits"
    private let enforcementModeKey = "enforcementMode"

    var deviceLimits: [String: Float] = [:]
    var enforcementMode: EnforcementMode = .hardCap

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
    }

    func saveSettings() {
        // Save device limits
        if let encoded = try? JSONEncoder().encode(deviceLimits) {
            defaults.set(encoded, forKey: deviceLimitsKey)
        }

        // Save enforcement mode
        defaults.set(enforcementMode.rawValue, forKey: enforcementModeKey)

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
