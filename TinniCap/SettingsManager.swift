import Foundation
import CoreAudio

class SettingsManager {
    private let defaults = UserDefaults.standard
    private let deviceLimitsKey = "deviceLimits"
    private let enforcementModeKey = "enforcementMode"

    var deviceLimits: [AudioDeviceID: Float] = [:]
    var enforcementMode: EnforcementMode = .hardCap

    func loadSettings() {
        // Load device limits
        if let data = defaults.data(forKey: deviceLimitsKey),
           let decoded = try? JSONDecoder().decode([String: Float].self, from: data) {
            deviceLimits = decoded.reduce(into: [:]) { result, pair in
                if let deviceID = AudioDeviceID(pair.key) {
                    result[deviceID] = pair.value
                }
            }
        }

        // Load enforcement mode
        if let modeString = defaults.string(forKey: enforcementModeKey),
           let mode = EnforcementMode(rawValue: modeString) {
            enforcementMode = mode
        }
    }

    func saveSettings() {
        // Save device limits (convert AudioDeviceID keys to strings)
        let limitsDict = deviceLimits.reduce(into: [String: Float]()) { result, pair in
            result[String(pair.key)] = pair.value
        }

        if let encoded = try? JSONEncoder().encode(limitsDict) {
            defaults.set(encoded, forKey: deviceLimitsKey)
        }

        // Save enforcement mode
        defaults.set(enforcementMode.rawValue, forKey: enforcementModeKey)

        defaults.synchronize()
    }

    func setLimit(for deviceID: AudioDeviceID, limit: Float) {
        deviceLimits[deviceID] = limit
    }

    func getLimit(for deviceID: AudioDeviceID) -> Float? {
        return deviceLimits[deviceID]
    }

    func removeLimit(for deviceID: AudioDeviceID) {
        deviceLimits.removeValue(forKey: deviceID)
    }
}
