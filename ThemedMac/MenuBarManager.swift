import SwiftUI
import ServiceManagement

class MenuBarManager: NSObject {
    // Make menu a strong reference to prevent deallocation
    private var menu: NSMenu?
    private var statusItem: NSStatusItem!
    private var preferencesWindow: NSWindow?
    
    override init() {
        super.init()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Themed")
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        menu = NSMenu()
        
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu?.addItem(preferencesItem)
        
        let loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu?.addItem(loginItem)
        
        menu?.addItem(NSMenuItem.separator())
        menu?.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc private func toggleLoginItem(_ sender: NSMenuItem) {
        let isEnabled = !LaunchAtLogin.isEnabled
        LaunchAtLogin.isEnabled = isEnabled
        sender.state = isEnabled ? .on : .off
    }
    
    @objc private func openPreferences() {
        if preferencesWindow == nil {
            let contentView = ContentView()
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            preferencesWindow?.title = "Preferences"
            preferencesWindow?.center()
            preferencesWindow?.contentView = NSHostingView(rootView: contentView)
        }
        
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// Helper to manage launch at login
private enum LaunchAtLogin {
    static var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
    }
}