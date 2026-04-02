import SwiftUI

/// Vue parametres integree dans la fenetre principale
struct SettingsInlineView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(SyncService.self) private var syncService
    @Environment(AuthService.self) private var authService
    @State private var selectedTab = 0

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var tabs: [(label: String, icon: String)] {
        [
            (L10n.settingsCompany(lang), "building.2"),
            (L10n.settingsCustomisation(lang), "paintpalette"),
            (L10n.settingsPayment(lang), "creditcard"),
            (L10n.settingsDefaults(lang), "slider.horizontal.3"),
            (L10n.settingsServices(lang), "star"),
            (L10n.settingsLanguage(lang), "globe"),
            (L10n.settingsSync(lang), "arrow.triangle.2.circlepath"),
            (L10n.settingsAbout(lang), "info.circle")
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.settings(lang))
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
                case 1: CustomisationSettingsView()
                case 2: PaymentSettingsView()
                case 3: DefaultsSettingsView()
                case 4: PrestationsSettingsView()
                case 5: LanguageSettingsView()
                case 6: SyncSettingsView(syncService: syncService, authService: authService)
                case 7: AboutSettingsView()
                default: EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
