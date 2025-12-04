import Foundation
import CoreAudio
import AudioToolbox

protocol AudioDeviceServiceDelegate: AnyObject {
    func devicesDidChange()
    func volumeLimitExceeded(for device: AudioDevice, attemptedVolume: Float, limit: Float)
}

class AudioDeviceService {
    weak var delegate: AudioDeviceServiceDelegate?
    var enforcementMode: EnforcementMode = .hardCap

    private var volumeLimits: [AudioDeviceID: Float] = [:]
    private var monitoringTimer: Timer?
    private var currentDevices: [AudioDevice] = []

    init() {
        setupDeviceListener()
    }

    deinit {
        stopMonitoring()
        removeDeviceListener()
    }

    // MARK: - Device Discovery

    func getAllAudioDevices() -> [AudioDevice] {
        var devices: [AudioDevice] = []

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )

        guard status == kAudioHardwareNoError else {
            print("Error getting device list size: \(status)")
            return devices
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var audioDevices = [AudioDeviceID](repeating: 0, count: deviceCount)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &audioDevices
        )

        guard status == kAudioHardwareNoError else {
            print("Error getting device list: \(status)")
            return devices
        }

        for deviceID in audioDevices {
            // Only include output devices
            if isOutputDevice(deviceID) {
                if let device = getDeviceInfo(deviceID) {
                    devices.append(device)
                }
            }
        }

        currentDevices = devices
        return devices
    }

    private func isOutputDevice(_ deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )

        guard status == kAudioHardwareNoError else { return false }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(dataSize))
        defer { bufferList.deallocate() }

        let getStatus = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            bufferList
        )

        guard getStatus == kAudioHardwareNoError else { return false }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        return buffers.count > 0
    }

    private func getDeviceInfo(_ deviceID: AudioDeviceID) -> AudioDevice? {
        guard let name = getDeviceName(deviceID) else { return nil }
        let transportType = getTransportType(deviceID)
        let volume = getVolume(for: deviceID) ?? 0.0

        return AudioDevice(id: deviceID, name: name, transportType: transportType, volume: volume)
    }

    private func getDeviceName(_ deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceName: CFString = "" as CFString
        var dataSize = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceName
        )

        guard status == kAudioHardwareNoError else { return nil }
        return deviceName as String
    }

    private func getTransportType(_ deviceID: AudioDeviceID) -> AudioDevice.TransportType {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var transportType: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &transportType
        )

        guard status == kAudioHardwareNoError else { return .other }

        switch transportType {
        case kAudioDeviceTransportTypeBuiltIn:
            return .builtIn
        case kAudioDeviceTransportTypeBluetooth:
            return .bluetooth
        case kAudioDeviceTransportTypeUSB:
            return .usb
        case kAudioDeviceTransportTypeDisplayPort:
            return .displayPort
        case kAudioDeviceTransportTypeHDMI:
            return .hdmi
        case kAudioDeviceTransportTypeThunderbolt:
            return .thunderbolt
        default:
            return .other
        }
    }

    // MARK: - Volume Control

    func getVolume(for deviceID: AudioDeviceID) -> Float? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // Check if device has volume control
        if !AudioObjectHasProperty(deviceID, &propertyAddress) {
            return nil
        }

        var volume: Float32 = 0.0
        var dataSize = UInt32(MemoryLayout<Float32>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &volume
        )

        guard status == kAudioHardwareNoError else { return nil }
        return volume
    }

    func setVolume(for deviceID: AudioDeviceID, volume: Float) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var vol = volume
        let dataSize = UInt32(MemoryLayout<Float32>.size)

        let status = AudioObjectSetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            dataSize,
            &vol
        )

        return status == kAudioHardwareNoError
    }

    // MARK: - Volume Limiting

    func setVolumeLimit(for deviceID: AudioDeviceID, limit: Float) {
        volumeLimits[deviceID] = limit
    }

    func removeVolumeLimit(for deviceID: AudioDeviceID) {
        volumeLimits.removeValue(forKey: deviceID)
    }

    func getVolumeLimit(for deviceID: AudioDeviceID) -> Float? {
        return volumeLimits[deviceID]
    }

    // MARK: - Monitoring

    func startMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkVolumeLimits()
        }
    }

    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    private func checkVolumeLimits() {
        for device in currentDevices {
            guard let limit = volumeLimits[device.id],
                  let currentVolume = getVolume(for: device.id) else {
                continue
            }

            if currentVolume > limit {
                // Trigger delegate callback
                delegate?.volumeLimitExceeded(for: device, attemptedVolume: currentVolume, limit: limit)

                // Enforce limit if in hard cap mode
                if enforcementMode == .hardCap {
                    _ = setVolume(for: device.id, volume: limit)
                }
            }
        }
    }

    // MARK: - Device Change Listener

    private func setupDeviceListener() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            audioDeviceChangeCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    private func removeDeviceListener() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectRemovePropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            audioDeviceChangeCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    fileprivate func handleDeviceChange() {
        _ = getAllAudioDevices()
        delegate?.devicesDidChange()
    }
}

private func audioDeviceChangeCallback(
    _ inObjectID: AudioObjectID,
    _ inNumberAddresses: UInt32,
    _ inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
    _ inClientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData = inClientData else { return kAudioHardwareNoError }

    let service = Unmanaged<AudioDeviceService>.fromOpaque(clientData).takeUnretainedValue()
    DispatchQueue.main.async {
        service.handleDeviceChange()
    }

    return kAudioHardwareNoError
}
