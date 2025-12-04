import Cocoa
import SwiftUI

class MenuBarController: NSObject {
    var menu: NSMenu
    var audioService: AudioDeviceService
    var settingsManager: SettingsManager
    var deviceMenuItems: [AudioDevice: NSMenuItem] = [:]

    override init() {
        self.menu = NSMenu()
        self.audioService = AudioDeviceService()
        self.settingsManager = SettingsManager()

        super.init()

        setupMenu()

        // Start monitoring audio devices
        audioService.delegate = self
        audioService.startMonitoring()

        // Load saved settings
        settingsManager.loadSettings()
        applyStoredLimits()
    }

    func setupMenu() {
        // Enforcement mode section
        let enforcementItem = NSMenuItem(title: "Enforcement Mode", action: nil, keyEquivalent: "")
        enforcementItem.isEnabled = false
        menu.addItem(enforcementItem)

        let hardCapItem = NSMenuItem(title: "  Hard Cap (Enforce Limit)", action: #selector(setHardCapMode), keyEquivalent: "")
        hardCapItem.target = self
        hardCapItem.state = settingsManager.enforcementMode == .hardCap ? .on : .off
        menu.addItem(hardCapItem)

        let warningItem = NSMenuItem(title: "  Warning Only", action: #selector(setWarningMode), keyEquivalent: "")
        warningItem.target = self
        warningItem.state = settingsManager.enforcementMode == .warning ? .on : .off
        menu.addItem(warningItem)

        menu.addItem(NSMenuItem.separator())

        // Devices section
        let devicesHeader = NSMenuItem(title: "Audio Devices", action: nil, keyEquivalent: "")
        devicesHeader.isEnabled = false
        menu.addItem(devicesHeader)

        refreshDeviceList()

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc func setHardCapMode() {
        settingsManager.enforcementMode = .hardCap
        audioService.enforcementMode = .hardCap
        updateEnforcementMenuState()
        settingsManager.saveSettings()
    }

    @objc func setWarningMode() {
        settingsManager.enforcementMode = .warning
        audioService.enforcementMode = .warning
        updateEnforcementMenuState()
        settingsManager.saveSettings()
    }

    func updateEnforcementMenuState() {
        if let hardCapItem = menu.item(withTitle: "  Hard Cap (Enforce Limit)"),
           let warningItem = menu.item(withTitle: "  Warning Only") {
            hardCapItem.state = settingsManager.enforcementMode == .hardCap ? .on : .off
            warningItem.state = settingsManager.enforcementMode == .warning ? .on : .off
        }
    }

    func refreshDeviceList() {
        // Remove old device menu items
        deviceMenuItems.values.forEach { menu.removeItem($0) }
        deviceMenuItems.removeAll()

        let devices = audioService.getAllAudioDevices()
        let devicesHeaderIndex = menu.indexOfItem(withTitle: "Audio Devices")

        var insertIndex = devicesHeaderIndex + 1

        for device in devices {
            let deviceItem = NSMenuItem(title: "  \(device.name)", action: nil, keyEquivalent: "")

            let submenu = NSMenu()

            // Current volume
            let volumeInfo = NSMenuItem(title: "Current: \(Int(device.volume * 100))%", action: nil, keyEquivalent: "")
            volumeInfo.isEnabled = false
            submenu.addItem(volumeInfo)

            submenu.addItem(NSMenuItem.separator())

            // Set limit
            let setLimitItem = NSMenuItem(title: "Set Volume Limit...", action: #selector(showLimitDialog(_:)), keyEquivalent: "")
            setLimitItem.target = self
            setLimitItem.representedObject = device
            submenu.addItem(setLimitItem)

            // Show current limit if exists
            if let limit = settingsManager.getLimit(for: device.id) {
                let limitInfo = NSMenuItem(title: "Current Limit: \(Int(limit * 100))%", action: nil, keyEquivalent: "")
                limitInfo.isEnabled = false
                submenu.addItem(limitInfo)

                // Remove limit option
                let removeLimitItem = NSMenuItem(title: "Remove Limit", action: #selector(removeLimit(_:)), keyEquivalent: "")
                removeLimitItem.target = self
                removeLimitItem.representedObject = device
                submenu.addItem(removeLimitItem)
            }

            deviceItem.submenu = submenu
            menu.insertItem(deviceItem, at: insertIndex)
            deviceMenuItems[device] = deviceItem
            insertIndex += 1
        }
    }

    @objc func showLimitDialog(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioDevice else { return }

        let alert = NSAlert()
        alert.messageText = "Set Volume Limit for \(device.name)"
        alert.informativeText = "Enter the maximum volume percentage (0-100):"
        alert.alertStyle = .informational

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "e.g., 75"

        // Pre-fill with current limit if exists
        if let currentLimit = settingsManager.getLimit(for: device.id) {
            textField.stringValue = "\(Int(currentLimit * 100))"
        }

        alert.accessoryView = textField
        alert.addButton(withTitle: "Set")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            if let value = Int(textField.stringValue), value >= 0, value <= 100 {
                let limitValue = Float(value) / 100.0
                settingsManager.setLimit(for: device.id, limit: limitValue)
                audioService.setVolumeLimit(for: device.id, limit: limitValue)
                settingsManager.saveSettings()
                refreshDeviceList()

                // Show confirmation
                showNotification(title: "Limit Set", message: "Volume limit for \(device.name) set to \(value)%")
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Invalid Input"
                errorAlert.informativeText = "Please enter a number between 0 and 100."
                errorAlert.runModal()
            }
        }
    }

    @objc func removeLimit(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioDevice else { return }

        settingsManager.removeLimit(for: device.id)
        audioService.removeVolumeLimit(for: device.id)
        settingsManager.saveSettings()
        refreshDeviceList()

        showNotification(title: "Limit Removed", message: "Volume limit for \(device.name) has been removed")
    }

    func applyStoredLimits() {
        for (deviceId, limit) in settingsManager.deviceLimits {
            audioService.setVolumeLimit(for: deviceId, limit: limit)
        }
        audioService.enforcementMode = settingsManager.enforcementMode
    }

    func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }

    @objc func toggleMenu() {
        // Menu is automatically shown when status item is clicked
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

extension MenuBarController: AudioDeviceServiceDelegate {
    func devicesDidChange() {
        DispatchQueue.main.async {
            self.refreshDeviceList()
            self.applyStoredLimits()
        }
    }

    func volumeLimitExceeded(for device: AudioDevice, attemptedVolume: Float, limit: Float) {
        DispatchQueue.main.async {
            if self.settingsManager.enforcementMode == .warning {
                self.showNotification(
                    title: "Volume Limit Warning",
                    message: "\(device.name) volume (\(Int(attemptedVolume * 100))%) exceeds limit of \(Int(limit * 100))%"
                )
            } else {
                self.showNotification(
                    title: "Volume Limited",
                    message: "\(device.name) volume capped at \(Int(limit * 100))%"
                )
            }
            self.refreshDeviceList()
        }
    }
}
