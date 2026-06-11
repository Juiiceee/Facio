import SwiftUI
import AppKit

@main
struct FacioApp: App {
    @State private var dataStore: DataStore
    @State private var syncService: SyncService
    @State private var authService: AuthService
    @State private var networkMonitor: NetworkMonitor
    @State private var updateService: UpdateService
    @State private var toastCenter = ToastCenter()
    @State private var showFirstLaunch = false

    init() {
        #if FACIO_REGRESSION_TESTS
        FacioRegressionSuite.runIfRequested()
        #endif

        _dataStore = State(initialValue: DataStore())
        _syncService = State(initialValue: SyncService())
        _authService = State(initialValue: AuthService())
        _networkMonitor = State(initialValue: NetworkMonitor())
        _updateService = State(initialValue: UpdateService())

        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            let lang = dataStore.companyInfo.langueParDefaut
            ContentView()
                .environment(dataStore)
                .environment(syncService)
                .environment(authService)
                .environment(networkMonitor)
                .environment(toastCenter)
                .environment(\.facioAccent, Color.appPrimary(from: dataStore.companyInfo))
                .tint(Color.appPrimary(from: dataStore.companyInfo))
                .frame(minWidth: FacioLayout.windowMinWidth, minHeight: FacioLayout.windowMinHeight)
                .alert(L10n.firstLaunchTitle(lang), isPresented: $showFirstLaunch) {
                    Button(L10n.understood(lang)) {
                        UserDefaults.standard.set(true, forKey: "facio_has_launched")
                    }
                } message: {
                    Text(L10n.firstLaunchMessage(lang))
                }
                .alert(
                    L10n.updateAvailableTitle(lang),
                    isPresented: Binding(
                        get: { updateService.isUpdateAvailable },
                        set: { _ in }
                    )
                ) {
                    if let url = updateService.releaseURL {
                        Link(L10n.download(lang), destination: url)
                    }
                    Button(L10n.later(lang), role: .cancel) {}
                } message: {
                    Text(L10n.updateAvailableMessage(lang, version: updateService.latestVersion ?? ""))
                }
                .onAppear {
                    authService.language = lang
                    syncService.language = lang
                    if !UserDefaults.standard.bool(forKey: "facio_has_launched") {
                        showFirstLaunch = true
                    }
                    dataStore.syncService = syncService
                    syncService.authService = authService

                    Task {
                        await updateService.checkForUpdates()
                        if SyncConfig.isEnabled && authService.isAuthenticated {
                            await authService.refreshSession()
                            await syncService.fullSync(dataStore: dataStore)
                        }
                    }
                }
                .onChange(of: lang) { _, newLanguage in
                    authService.language = newLanguage
                    syncService.language = newLanguage
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
        .defaultSize(width: FacioLayout.windowIdealWidth, height: FacioLayout.windowIdealHeight)

        Settings {
            SettingsView()
                .environment(dataStore)
                .environment(syncService)
                .environment(authService)
                .environment(toastCenter)
                .environment(\.facioAccent, Color.appPrimary(from: dataStore.companyInfo))
                .tint(Color.appPrimary(from: dataStore.companyInfo))
        }
    }
}
