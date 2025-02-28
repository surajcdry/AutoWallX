import SwiftUI

class ImageCache: ObservableObject {
    private let cache = NSCache<NSURL, NSImage>()
    
    func object(forKey key: NSURL) -> NSImage? {
        return cache.object(forKey: key)
    }
    
    func setObject(_ obj: NSImage, forKey key: NSURL) {
        cache.setObject(obj, forKey: key)
    }
}

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
    
    // Image cache
    @StateObject private var imageCache = ImageCache()
    
    // Get current wallpaper based on system theme
    private var currentWallpaperURL: URL? {
        colorScheme == .dark ? darkModeWallpaper : lightModeWallpaper
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let bookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                
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
                let url = try URL(
                    resolvingBookmarkData: bookmark,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                
                if url.startAccessingSecurityScopedResource() {
                    lightModeWallpaper = url
                    if isStale {
                        if let newBookmark = try? url.bookmarkData(
                            options: .withSecurityScope,
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
    
    // File picker function
    private func showFilePicker() {
        // Stop accessing current wallpapers before showing picker
        if let url = lightModeWallpaper {
            url.stopAccessingSecurityScopedResource()
        }
        if let url = darkModeWallpaper {
            url.stopAccessingSecurityScopedResource()
        }
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.jpeg, .png, .tiff, .heic]
        panel.treatsFilePackagesAsDirectories = false
        
        NSApp.activate(ignoringOtherApps: true)
        panel.begin { [self] result in
            if result == .OK {
                self.handlePanelResponse(panel)
            }
        }
    }

    private func handlePanelResponse(_ panel: NSOpenPanel) {
        guard let url = panel.url else { return }
        
        do {
            // Create security scoped bookmark
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            // Verify we can resolve and access the bookmark
            var isStale = false
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if resolvedURL.startAccessingSecurityScopedResource() {
                // Store the bookmark and URL
                if selectingForMode == .dark {
                    darkBookmark = bookmarkData
                    storedDarkBookmark = bookmarkData
                    darkModeWallpaper = resolvedURL
                    if colorScheme == .dark {
                        applyCurrentWallpaper()
                    }
                } else {
                    lightBookmark = bookmarkData
                    storedLightBookmark = bookmarkData
                    lightModeWallpaper = resolvedURL
                    if colorScheme == .light {
                        applyCurrentWallpaper()
                    }
                }
                
                // Only stop accessing if we're not going to use it immediately
                if (selectingForMode == .dark && colorScheme != .dark) ||
                   (selectingForMode == .light && colorScheme != .light) {
                    resolvedURL.stopAccessingSecurityScopedResource()
                }
            } else {
                throw NSError(domain: "com.app.ThemedMac", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Unable to access the selected file"])
            }
        } catch {
            errorMessage = "Failed to access the selected file: \(error.localizedDescription)"
            showError = true
        }
    }

    private func applyCurrentWallpaper() {
        guard let url = currentWallpaperURL else { return }
        
        // Dispatch wallpaper setting to background thread
        DispatchQueue.global(qos: .userInitiated).async {
            if url.startAccessingSecurityScopedResource() {
                do {
                    // Apply wallpaper to all available screens
                    for screen in NSScreen.screens {
                        try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
                    }
                } catch {
                    DispatchQueue.main.async {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
    
    private var isWallpaperInUse: Bool {
        (selectingForMode == .dark && colorScheme == .dark) ||
        (selectingForMode == .light && colorScheme == .light)
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
                .environmentObject(imageCache)
                
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
                .environmentObject(imageCache)
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
            
            Button("About Developer") {
                if let url = URL(string: "https://www.surajc.com/") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)
            .font(.footnote)
        }
        .frame(width: 400, height: 500)
        .padding()
 
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
    @EnvironmentObject private var imageCache: ImageCache
    
    let title: String
    let icon: String
    let iconColor: Color
    let wallpaperURL: URL?
    let isActive: Bool
    let onSelect: () -> Void
    
    private func loadImage(from url: URL) -> NSImage? {
        // Try to get from cache first
        if let cachedImage = imageCache.object(forKey: url as NSURL) {
            return cachedImage
        }
        
        // Load from disk and cache it
        if let image = NSImage(contentsOf: url) {
            imageCache.setObject(image, forKey: url as NSURL)
            return image
        }
        return nil
    }
    
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
                    Text("Change")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
            
            if let url = wallpaperURL {
                Group {
                    if let image = loadImage(from: url) {
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
                }
                .transition(.opacity)
                .animation(.easeInOut, value: url)
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
