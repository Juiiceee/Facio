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
    @State private var privacyMode = PrivacyMode()
    @State private var appLock = AppLock()
    @State private var showFirstLaunch = false

    init() {
        #if FACIO_REGRESSION_TESTS
        FacioRegressionSuite.emitFacturXSampleIfRequested()
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
            ZStack {
                ContentView()
                    // Ceinture et bretelles : l'écran de verrouillage couvre déjà
                    // tout, mais la barre d'outils vit hors de cette pile.
                    .disabled(appLock.isLocked)
                if appLock.isLocked {
                    AppLockView()
                }
            }
                .environment(dataStore)
                .environment(syncService)
                .environment(authService)
                .environment(networkMonitor)
                .environment(toastCenter)
                .environment(privacyMode)
                .environment(appLock)
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
                    appLock.start()
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
        .commands {
            CommandGroup(after: .appVisibility) {
                Button(L10n.lockNow(dataStore.companyInfo.langueParDefaut)) {
                    appLock.lockNow()
                }
                .keyboardShortcut("l", modifiers: [.command, .control])
                .disabled(!appLock.isEnabled || appLock.isLocked)
            }
        }

        Settings {
            // Cmd-, ouvre cette scène même quand la fenêtre principale est
            // verrouillée : sans ce garde, les réglages (dont la suppression du
            // code) resteraient joignables sans avoir saisi le code.
            Group {
                if appLock.isLocked {
                    AppLockView()
                        .frame(minWidth: FacioLayout.sheetMinWidth, minHeight: FacioLayout.sheetIdealHeight)
                } else {
                    SettingsView()
                }
            }
                .environment(dataStore)
                .environment(syncService)
                .environment(authService)
                .environment(toastCenter)
                .environment(privacyMode)
                .environment(appLock)
                .environment(\.facioAccent, Color.appPrimary(from: dataStore.companyInfo))
                .tint(Color.appPrimary(from: dataStore.companyInfo))
        }
    }
}
