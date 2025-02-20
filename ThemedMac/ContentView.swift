import SwiftUI

// Main view that manages wallpapers for light and dark mode
struct ContentView: View {
    // Environment and UI state
    @Environment(\.colorScheme) var colorScheme
    @State private var showFileImporter = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Wallpaper URLs and mode selection
    @State private var lightModeWallpaper: URL?
    @State private var darkModeWallpaper: URL?
    @State private var selectingForMode: ColorScheme = .light
    
    // File access data
    @State private var lightBookmark: Data?
    @State private var darkBookmark: Data?
    
    // Persistent storage
    @AppStorage("lightModeBookmark") private var storedLightBookmark: Data?
    @AppStorage("darkModeBookmark") private var storedDarkBookmark: Data?
    
    // Get current wallpaper based on system theme
    private var currentWallpaperURL: URL? {
        colorScheme == .dark ? darkModeWallpaper : lightModeWallpaper
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                      includingResourceValuesForKeys: nil,
                                                      relativeTo: nil)
                
                if selectingForMode == .dark {
                    darkBookmark = bookmarkData
                    storedDarkBookmark = bookmarkData
                    darkModeWallpaper = url
                    if colorScheme == .dark {
                        applyCurrentWallpaper()
                    }
                } else {
                    lightBookmark = bookmarkData
                    storedLightBookmark = bookmarkData
                    lightModeWallpaper = url
                    if colorScheme == .light {
                        applyCurrentWallpaper()
                    }
                }
            } catch {
                errorMessage = "Failed to access the selected file"
                showError = true
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func loadStoredWallpapers() {
        if let bookmark = storedLightBookmark {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmark,
                                options: .withSecurityScope,
                                relativeTo: nil,
                                bookmarkDataIsStale: &isStale)
                
                if url.startAccessingSecurityScopedResource() {
                    lightModeWallpaper = url
                    if isStale {
                        if let newBookmark = try? url.bookmarkData(options: .withSecurityScope,
                                                                 includingResourceValuesForKeys: nil,
                                                                 relativeTo: nil) {
                            storedLightBookmark = newBookmark
                        }
                    }
                }
            } catch {
                print("Failed to resolve light mode wallpaper: \(error)")
                storedLightBookmark = nil
            }
        }
        
        if let bookmark = storedDarkBookmark {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmark,
                                options: .withSecurityScope,
                                relativeTo: nil,
                                bookmarkDataIsStale: &isStale)
                
                if url.startAccessingSecurityScopedResource() {
                    darkModeWallpaper = url
                    if isStale {
                        if let newBookmark = try? url.bookmarkData(options: .withSecurityScope,
                                                                 includingResourceValuesForKeys: nil,
                                                                 relativeTo: nil) {
                            storedDarkBookmark = newBookmark
                        }
                    }
                }
            } catch {
                print("Failed to resolve dark mode wallpaper: \(error)")
                storedDarkBookmark = nil
            }
        }
    }

    private func applyCurrentWallpaper() {
        guard let url = currentWallpaperURL else { return }
        
        do {
            if let screen = NSScreen.main {
                try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        url.stopAccessingSecurityScopedResource()
    }
    
    // Add showFilePicker function here in ContentView
    private func showFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.jpeg, .png, .tiff, .heic]
        
        // Run the panel as a modal
        NSApp.activate(ignoringOtherApps: true)
        let response = panel.runModal()
        
        if response == .OK {
            self.handlePanelResponse(response, panel: panel)
        }
        panel.close()
    }

    private func handlePanelResponse(_ response: NSApplication.ModalResponse, panel: NSOpenPanel) {
        if response == .OK, let url = panel.urls.first {
            do {
                let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                      includingResourceValuesForKeys: nil,
                                                      relativeTo: nil)
                
                if selectingForMode == .dark {
                    darkBookmark = bookmarkData
                    storedDarkBookmark = bookmarkData
                    darkModeWallpaper = url
                    if colorScheme == .dark {
                        applyCurrentWallpaper()
                    }
                } else {
                    lightBookmark = bookmarkData
                    storedLightBookmark = bookmarkData
                    lightModeWallpaper = url
                    if colorScheme == .light {
                        applyCurrentWallpaper()
                    }
                }
            } catch {
                errorMessage = "Failed to access the selected file"
                showError = true
            }
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                WallpaperSection(
                    title: "Light Mode",
                    icon: "sun.max.fill",
                    iconColor: colorScheme == .light ? .orange : .secondary,
                    wallpaperURL: lightModeWallpaper,
                    isActive: colorScheme == .light,
                    onSelect: {
                        selectingForMode = .light
                        showFilePicker()
                    }
                )
                
                Divider()
                
                WallpaperSection(
                    title: "Dark Mode",
                    icon: "moon.fill",
                    iconColor: colorScheme == .dark ? .purple : .secondary,
                    wallpaperURL: darkModeWallpaper,
                    isActive: colorScheme == .dark,
                    onSelect: {
                        selectingForMode = .dark
                        showFilePicker()
                    }
                )
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            VStack(spacing: 8) {
                
                Button(role: .destructive) {
                    // Clear all stored data
                    lightModeWallpaper = nil
                    darkModeWallpaper = nil
                    storedLightBookmark = nil
                    storedDarkBookmark = nil
                    
                    // Reset wallpaper to system default
                    if let screen = NSScreen.main {
                        try? NSWorkspace.shared.setDesktopImageURL(
                            URL(fileURLWithPath: "/System/Library/Desktop Pictures/Monterey Graphic.heic"),
                            for: screen,
                            options: [:]
                        )
                    }
                } label: {
                    Text("Clear wallpapers")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            Button("Learn more") {
                if let url = URL(string: "https://www.themedmac.com/") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)
            .font(.footnote)
            .padding(.bottom)
        }
        .frame(width: 400, height: 500)
        .padding()
        // Remove .fileImporter modifier since we're using NSOpenPanel
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: colorScheme) { oldValue, newValue in
            applyCurrentWallpaper()
        }
        .onAppear {
            loadStoredWallpapers()
        }
    }
} // End of ContentView

// Component for displaying wallpaper preview and selection
struct WallpaperSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let wallpaperURL: URL?
    let isActive: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label {
                    Text(title)
                        .font(.headline)
                } icon: {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                }
                if isActive {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onSelect) {
                    Text("Pick")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
            
            if let url = wallpaperURL {
                if let image = NSImage(contentsOf: url) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    Color.gray.opacity(0.2)
                        .frame(height: 120)
                        .cornerRadius(8)
                        .overlay(
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Failed to load preview")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}

#Preview {
    ContentView()
}
