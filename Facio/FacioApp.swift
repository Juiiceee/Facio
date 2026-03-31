import SwiftUI
import AppKit

@main
struct FacioApp: App {
    @State private var dataStore = DataStore()
    @State private var syncService = SyncService()
    @State private var authService = AuthService()
    @State private var networkMonitor = NetworkMonitor()
    @State private var showFirstLaunch = false

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataStore)
                .environment(syncService)
                .environment(authService)
                .environment(networkMonitor)
                .frame(minWidth: 1100, minHeight: 650)
                .alert("Bienvenue sur Facio !", isPresented: $showFirstLaunch) {
                    Button("Compris") {
                        UserDefaults.standard.set(true, forKey: "facio_has_launched")
                    }
                } message: {
                    Text("Vous pouvez supprimer le fichier DMG de vos telechargements, Facio est installe.")
                }
                .onAppear {
                    if !UserDefaults.standard.bool(forKey: "facio_has_launched") {
                        showFirstLaunch = true
                    }
                    dataStore.syncService = syncService
                    syncService.authService = authService

                    Task {
                        if SyncConfig.isEnabled && authService.isAuthenticated {
                            await authService.refreshSession()
                            await syncService.fullSync(dataStore: dataStore)
                        }
                    }
                }
                .onChange(of: networkMonitor.isConnected) { _, isConnected in
                    if isConnected && SyncConfig.isEnabled {
                        Task {
                            await authService.refreshSession()
                            await syncService.pushAllDirty()
                        }
                    }
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)

        Settings {
            SettingsView()
                .environment(dataStore)
                .environment(syncService)
                .environment(authService)
        }
    }
}
