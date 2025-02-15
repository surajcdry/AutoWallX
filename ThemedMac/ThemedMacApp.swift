//
//  ThemedMacApp.swift
//  ThemedMac
//
//  Created by Suraj Chaudhary on 06/02/2025.
//

import SwiftUI

@main
struct ThemedMacApp: App {
    @NSApplicationDelegateAdaptor(ThemedMacAppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .defaultSize(width: 0, height: 0)
        .commands {
            // Remove default menu items
            CommandGroup(replacing: .appInfo) {}
            CommandGroup(replacing: .systemServices) {}
            CommandGroup(replacing: .newItem) {}
        }
    }
}

