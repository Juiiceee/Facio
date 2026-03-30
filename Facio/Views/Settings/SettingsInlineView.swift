import SwiftUI

/// Vue parametres integree dans la fenetre principale
struct SettingsInlineView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(SyncService.self) private var syncService
    @Environment(AuthService.self) private var authService
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Parametres")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 10)

            Picker("", selection: $selectedTab) {
                Label("Entreprise", systemImage: "building.2").tag(0)
                Label("Paiement", systemImage: "creditcard").tag(1)
                Label("Valeurs par defaut", systemImage: "slider.horizontal.3").tag(2)
                Label("Prestations", systemImage: "star").tag(3)
                Label("Synchronisation", systemImage: "arrow.triangle.2.circlepath").tag(4)
                Label("A propos", systemImage: "info.circle").tag(5)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                switch selectedTab {
                case 0: CompanySettingsView()
                case 1: PaymentSettingsView()
                case 2: DefaultsSettingsView()
                case 3: PrestationsSettingsView()
                case 4: SyncSettingsView(syncService: syncService, authService: authService)
                case 5: AboutSettingsView()
                default: EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
