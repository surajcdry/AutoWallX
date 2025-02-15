//
//  ThemedMacApp.swift
//  ThemedMac
//
//  Created by Suraj Chaudhary on 06/02/2025.
//

import SwiftUI

@main
struct ThemedMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarManager = MenuBarManager()
    }
}
