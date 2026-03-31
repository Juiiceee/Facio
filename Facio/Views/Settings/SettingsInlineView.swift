import SwiftUI

/// Vue parametres integree dans la fenetre principale
struct SettingsInlineView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(SyncService.self) private var syncService
    @Environment(AuthService.self) private var authService
    @State private var selectedTab = 0

    private let tabs: [(label: String, icon: String)] = [
        ("Entreprise", "building.2"),
        ("Paiement", "creditcard"),
        ("Valeurs par defaut", "slider.horizontal.3"),
        ("Prestations", "star"),
        ("Synchronisation", "arrow.triangle.2.circlepath"),
        ("A propos", "info.circle")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Parametres")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Tab bar — wraps on narrow windows
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedTab = index
                            }
                        } label: {
                            Label(tab.label, systemImage: tab.icon)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    selectedTab == index
                                        ? Color.accentColor.opacity(0.12)
                                        : Color.clear
                                )
                                .foregroundStyle(selectedTab == index ? .primary : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)

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
