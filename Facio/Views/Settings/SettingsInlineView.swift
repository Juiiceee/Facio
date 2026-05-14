import SwiftUI

/// Vue parametres integree dans la fenetre principale
struct SettingsInlineView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(SyncService.self) private var syncService
    @Environment(AuthService.self) private var authService
    @Binding var selectedTab: Int

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
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.settings(lang))
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.top, 18)

                List(selection: Binding<Int?>(
                    get: { selectedTab },
                    set: { selectedTab = $0 ?? selectedTab }
                )) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                        Label(tab.label, systemImage: tab.icon)
                            .tag(index)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(width: 230)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            ScrollView {
                selectedSettingsView
                    .frame(maxWidth: 760, alignment: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .frame(minWidth: 700, maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var selectedSettingsView: some View {
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
