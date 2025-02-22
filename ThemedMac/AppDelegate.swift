import SwiftUI
import ServiceManagement

class ThemedMacAppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var preferencesWindow: NSWindow?
    var openPanel: NSOpenPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
            button.image?.isTemplate = true
        }
        
        setupMenus()
    }
    
    func setupMenus() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        
        // Open at Login menu item
        let openAtLoginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        openAtLoginItem.state = getLaunchAtLoginState()
        menu.addItem(openAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let currentState = getLaunchAtLoginState()
        if currentState == .on {
            setLaunchAtLogin(false)
            sender.state = .off
        } else {
            setLaunchAtLogin(true)
            sender.state = .on
        }
    }
    
    private func getLaunchAtLoginState() -> NSControl.StateValue {
        return SMAppService.mainApp.status == .enabled ? .on : .off
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set login item: \(error)")
        }
    }
    
    @objc func showPreferences() {
        if let preferencesWindow = preferencesWindow {
            preferencesWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "AutoWallX Preferences"
        window.contentView = NSHostingView(rootView: ContentView())
        window.center()
        window.level = .normal
        window.delegate = self
        
        self.preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // Update window delegate
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender == preferencesWindow {
            sender.orderOut(nil)
            return false
        }
        return true
    }
}

// Window delegate methods
extension ThemedMacAppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == preferencesWindow {
            preferencesWindow = nil
        }
    }
}
