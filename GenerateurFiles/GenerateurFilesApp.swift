import SwiftUI
import AppKit

@main
struct GenerateurFilesApp: App {
    @State private var dataStore = DataStore()

    init() {
        // Activer l'app en tant qu'app GUI (necessaire pour swift run)
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataStore)
                .frame(minWidth: 1100, minHeight: 650)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)

        Settings {
            SettingsView()
                .environment(dataStore)
        }
    }
}
