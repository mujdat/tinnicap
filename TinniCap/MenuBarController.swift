import Cocoa
import SwiftUI
import UserNotifications

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

        // Load saved settings first
        settingsManager.loadSettings()
        applyStoredLimits()

        // Load launch at login preference
        LaunchAtLoginManager.shared.loadSavedPreference()

        // Request notification permissions
        requestNotificationPermissions()

        setupMenu()

        // Start monitoring audio devices
        audioService.delegate = self
        audioService.startMonitoring()
    }

    func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
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

        // Launch at Login (with toggle switch)
        let launchAtLoginItem = createLaunchAtLoginMenuItem()
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())

        // About
        let aboutItem = NSMenuItem(title: "About TinniCap", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

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
            let volumeInfo = NSMenuItem(title: "Current Volume: \(Int(device.volume * 100))%", action: nil, keyEquivalent: "")
            volumeInfo.isEnabled = false
            submenu.addItem(volumeInfo)

            submenu.addItem(NSMenuItem.separator())

            // Set limit
            let setLimitItem = NSMenuItem(title: "Set Volume Limit", action: #selector(showLimitDialog(_:)), keyEquivalent: "")
            setLimitItem.target = self
            setLimitItem.representedObject = device
            submenu.addItem(setLimitItem)

            // Show current limit if exists
            if let limit = settingsManager.getLimit(for: device) {
                let limitInfo = NSMenuItem(title: "Current Volume Limit: \(Int(limit * 100))%", action: nil, keyEquivalent: "")
                limitInfo.isEnabled = false
                submenu.addItem(limitInfo)

                // Remove limit option
                let removeLimitItem = NSMenuItem(title: "Remove Volume Limit", action: #selector(removeLimit(_:)), keyEquivalent: "")
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
        alert.informativeText = "Adjust the slider to set the maximum volume percentage:"
        alert.alertStyle = .informational

        // Create container view for slider and label
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 40))

        // Create slider
        let slider = NSSlider(frame: NSRect(x: 0, y: 10, width: 240, height: 24))
        slider.minValue = 0
        slider.maxValue = 100
        slider.isContinuous = true

        // Pre-fill with current limit if exists, otherwise default to 75
        let initialValue: Int
        if let currentLimit = settingsManager.getLimit(for: device) {
            initialValue = Int(currentLimit * 100)
        } else {
            initialValue = 75
        }
        slider.integerValue = initialValue

        // Create label to show percentage
        let percentageLabel = NSTextField(frame: NSRect(x: 250, y: 10, width: 50, height: 24))
        percentageLabel.stringValue = "\(initialValue)%"
        percentageLabel.isEditable = false
        percentageLabel.isBordered = false
        percentageLabel.backgroundColor = .clear
        percentageLabel.alignment = .left

        // Update label when slider changes
        slider.target = self
        slider.action = #selector(sliderValueChanged(_:))
        slider.tag = percentageLabel.hash // Store label reference in tag for callback

        // Store label in a way we can access it from the action
        objc_setAssociatedObject(slider, "percentageLabel", percentageLabel, .OBJC_ASSOCIATION_RETAIN)

        containerView.addSubview(slider)
        containerView.addSubview(percentageLabel)

        alert.accessoryView = containerView
        alert.addButton(withTitle: "Set")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let value = slider.integerValue
            let limitValue = Float(value) / 100.0
            settingsManager.setLimit(for: device, limit: limitValue)
            audioService.setVolumeLimit(for: device, limit: limitValue)
            settingsManager.saveSettings()
            refreshDeviceList()

            // Show confirmation
            showNotification(title: "Limit Set", message: "Volume limit for \(device.name) set to \(value)%")
        }
    }

    @objc func sliderValueChanged(_ sender: NSSlider) {
        if let label = objc_getAssociatedObject(sender, "percentageLabel") as? NSTextField {
            label.stringValue = "\(sender.integerValue)%"
        }
    }

    @objc func removeLimit(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioDevice else { return }

        settingsManager.removeLimit(for: device)
        audioService.removeVolumeLimit(for: device)
        settingsManager.saveSettings()
        refreshDeviceList()

        showNotification(title: "Limit Removed", message: "Volume limit for \(device.name) has been removed")
    }

    func applyStoredLimits() {
        let devices = audioService.getAllAudioDevices()
        for device in devices {
            if let limit = settingsManager.getLimit(for: device) {
                audioService.setVolumeLimit(for: device, limit: limit)
            }
        }
        audioService.enforcementMode = settingsManager.enforcementMode
    }

    func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        // No sound for notifications

        // Create a trigger that fires immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        // Create unique identifier for the notification
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Add the notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }

            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
            }
        }
    }

    @objc func toggleMenu() {
        // Menu is automatically shown when status item is clicked
    }

    func createLaunchAtLoginMenuItem() -> NSMenuItem {
        let menuItem = NSMenuItem()

        // Create SwiftUI toggle view
        let toggleView = LaunchAtLoginToggleView()
        let hostingView = NSHostingView(rootView: toggleView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 250, height: 24)

        menuItem.view = hostingView
        return menuItem
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "TinniCap"
        alert.informativeText = """
        Version: 1.0.4

        TinniCap is a native macOS menubar application that can limit volume on individual audio devices.

        Author: Müjdat Korkmaz
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Visit GitHub")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            // Open GitHub link
            if let url = URL(string: "https://github.com/mujdat/tinnicap") {
                NSWorkspace.shared.open(url)
            }
        }
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
            // Just refresh the device list to show current volume, no notification
            self.refreshDeviceList()
        }
    }
}

// Custom blue switch toggle style
struct BlueSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 9)
                .fill(configuration.isOn ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 32, height: 18)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .offset(x: configuration.isOn ? 7 : -7)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// SwiftUI view for the toggle
struct LaunchAtLoginToggleView: View {
    @State private var isEnabled = LaunchAtLoginManager.shared.isEnabled

    var body: some View {
        Toggle("Launch at Login", isOn: $isEnabled)
            .toggleStyle(BlueSwitchToggleStyle())
            .font(.system(size: 13))
            .onChange(of: isEnabled) { newValue in
                LaunchAtLoginManager.shared.setEnabled(newValue)
            }
            .padding(.leading, 20)
            .padding(.trailing, 10)
            .frame(width: 250, height: 24, alignment: .leading)
    }
}
