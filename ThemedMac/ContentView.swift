import SwiftUI

/// Main view for the wallpaper manager application
struct ContentView: View {
    // MARK: - Properties
    
    /// Current system color scheme (light/dark mode)
    @Environment(\.colorScheme) var colorScheme
    
    /// Controls visibility of the file picker
    @State private var showFileImporter = false
    
    /// Stores error message text when something goes wrong
    @State private var errorMessage: String?
    
    /// Controls visibility of error alert
    @State private var showError = false
    
    /// Stores the URL for light mode wallpaper
    @State private var lightModeWallpaper: URL?
    
    /// Stores the URL for dark mode wallpaper
    @State private var darkModeWallpaper: URL?
    
    /// Tracks which mode we're currently selecting wallpaper for
    @State private var selectingForMode: ColorScheme = .light
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Display current system appearance mode
            Text("Current Mode: \(colorScheme == .dark ? "Dark" : "Light")")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                // Light mode wallpaper selector
                WallpaperSelector(
                    title: "Light Mode Wallpaper",
                    selectedURL: lightModeWallpaper?.path ?? "Not set",
                    action: {
                        selectingForMode = .light
                        showFileImporter = true
                    }
                )
                
                // Dark mode wallpaper selector
                WallpaperSelector(
                    title: "Dark Mode Wallpaper",
                    selectedURL: darkModeWallpaper?.path ?? "Not set",
                    action: {
                        selectingForMode = .dark
                        showFileImporter = true
                    }
                )
            }
            .padding()
            
            // Apply wallpaper button
            Button("Apply Wallpaper") {
                applyCurrentWallpaper()
            }
            .disabled(currentWallpaperURL == nil)
        }
        .frame(minWidth: 250, minHeight: 200)
        .padding()
        // File picker for selecting wallpaper images
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.jpeg, .png, .tiff]
        ) { result in
            handleFileImport(result)
        }
        // Error alert
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        // Handle system appearance changes
        .onChange(of: colorScheme) { oldValue, newValue in
            applyCurrentWallpaper()
        }
    }
    
    // MARK: - Helper Properties
    
    /// Returns the appropriate wallpaper URL based on current color scheme
    private var currentWallpaperURL: URL? {
        colorScheme == .dark ? darkModeWallpaper : lightModeWallpaper
    }
    
    // MARK: - Helper Methods
    
    /// Handles the result of file selection
    /// - Parameter result: The result from the file picker
    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            // Update the wallpaper URL based on which mode we're selecting for
            if selectingForMode == .dark {
                darkModeWallpaper = url
                // Only apply immediately if we're currently in dark mode
                if colorScheme == .dark {
                    applyCurrentWallpaper()
                }
            } else {
                lightModeWallpaper = url
                // Only apply immediately if we're currently in light mode
                if colorScheme == .light {
                    applyCurrentWallpaper()
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    /// Applies the current wallpaper based on system appearance
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
    }
}

/// A reusable view for selecting wallpapers
struct WallpaperSelector: View {
    // MARK: - Properties
    
    /// Title text for the selector
    let title: String
    
    /// Currently selected wallpaper URL string
    let selectedURL: String
    
    /// Action to perform when select button is tapped
    let action: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            HStack {
                Text(selectedURL)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Select") {
                    action()
                }
            }
        }
    }
}

/// Preview provider for ContentView
#Preview {
    ContentView()
}
