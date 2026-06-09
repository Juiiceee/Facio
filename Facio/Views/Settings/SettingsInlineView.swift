import SwiftUI

/// Vue parametres integree dans la fenetre principale
struct SettingsInlineView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(SyncService.self) private var syncService
    @Environment(AuthService.self) private var authService
    @Binding var selectedTab: Int

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var tabs: [(label: String, icon: String, help: String)] {
        [
            (L10n.settingsCompany(lang), "building.2", L10n.settingsCompanyHelp(lang)),
            (L10n.settingsCustomisation(lang), "paintpalette", L10n.settingsCustomisationHelp(lang)),
            (L10n.settingsPayment(lang), "creditcard", L10n.settingsPaymentHelp(lang)),
            (L10n.settingsEmail(lang), "paperplane", L10n.settingsEmailHelp(lang)),
            (L10n.settingsDefaults(lang), "slider.horizontal.3", L10n.settingsDefaultsHelp(lang)),
            (L10n.settingsServices(lang), "star", L10n.settingsServicesHelp(lang)),
            (L10n.settingsLanguage(lang), "globe", L10n.settingsLanguageHelp(lang)),
            (L10n.settingsSync(lang), "arrow.triangle.2.circlepath", L10n.settingsSyncHelp(lang)),
            (L10n.settingsAbout(lang), "info.circle", L10n.settingsAboutHelp(lang))
        ]
    }

    private var selectedTabInfo: (label: String, icon: String, help: String) {
        tabs.indices.contains(selectedTab) ? tabs[selectedTab] : tabs[0]
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
                VStack(alignment: .leading, spacing: 0) {
                    settingsHeader
                    selectedSettingsView
                }
                .frame(maxWidth: 760, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .frame(minWidth: 700, maxWidth: .infinity, maxHeight: .infinity)
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(selectedTabInfo.label, systemImage: selectedTabInfo.icon)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(selectedTabInfo.help)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var selectedSettingsView: some View {
        switch selectedTab {
        case 0: CompanySettingsView()
        case 1: CustomisationSettingsView()
        case 2: PaymentSettingsView()
        case 3: EmailSettingsView()
        case 4: DefaultsSettingsView()
        case 5: PrestationsSettingsView()
        case 6: LanguageSettingsView()
        case 7: SyncSettingsView(syncService: syncService, authService: authService)
        case 8: AboutSettingsView()
        default: EmptyView()
        }
    }
}
