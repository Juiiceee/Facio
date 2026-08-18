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
            // Le verrou REMPLACE le contenu, il ne le recouvre pas.
            //
            // Un simple calque au-dessus de `ContentView` laissait passer deux
            // choses : les `.sheet` de macOS, qui sont des fenêtres attachées
            // dessinées au-dessus de la vue racine (aperçu PDF, justificatifs,
            // palette… restaient lisibles après le verrouillage), et l'arbre
            // d'accessibilité, que `.disabled()` ne vide pas — VoiceOver lisait
            // encore montants et coordonnées bancaires derrière l'écran.
            // Démonter la vue ferme ses feuilles et la sort de l'arbre, et
            // aucune feuille ajoutée plus tard ne pourra rouvrir la brèche.
            Group {
                if appLock.isLocked {
                    AppLockView()
                } else {
                    ContentView()
                }
            }
                .environment(dataStore)
                .environment(syncService)
                .environment(authService)
                .environment(networkMonitor)
                .environment(toastCenter)
                .environment(privacyMode)
                .environment(appLock)
                .environment(\.facioAccent, Color.accent(from: dataStore.companyInfo))
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
                    // PAS un second écran de verrouillage : deux écrans complets
                    // s'affichaient, chacun avec son capteur clavier réclamant le
                    // premier répondant à chaque rendu, sans rien pour dire lequel
                    // recevait la frappe. Les réglages se contentent de renvoyer
                    // vers la fenêtre principale, qui porte la saisie.
                    FacioEmptyState(
                        title: L10n.lockedSubtitle(dataStore.companyInfo.langueParDefaut),
                        systemImage: "lock.fill",
                        message: L10n.settingsLockedMessage(dataStore.companyInfo.langueParDefaut)
                    )
                    .frame(minWidth: FacioLayout.sheetMinWidth, minHeight: FacioLayout.sheetMinHeight)
                    .background(Color.surfaceCanvas)
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
                .environment(\.facioAccent, Color.accent(from: dataStore.companyInfo))
                .tint(Color.appPrimary(from: dataStore.companyInfo))
        }
    }
}
