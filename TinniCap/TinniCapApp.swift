import SwiftUI

@main
struct TinniCapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - we only want a menubar app
        NSApp.setActivationPolicy(.accessory)

        // Initialize the menubar controller
        menuBarController = MenuBarController()

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: "TinniCap")
            button.action = #selector(menuBarController?.toggleMenu)
            button.target = menuBarController
        }

        statusItem?.menu = menuBarController?.menu
    }
}
