import SwiftUI

struct SettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        TabView {
            CompanySettingsView()
                .tabItem {
                    Label(L10n.settingsCompany(lang), systemImage: "building.2")
                }

            PaymentSettingsView()
                .tabItem {
                    Label(L10n.settingsPayment(lang), systemImage: "creditcard")
                }

            DefaultsSettingsView()
                .tabItem {
                    Label(L10n.settingsDefaults(lang), systemImage: "slider.horizontal.3")
                }

            LanguageSettingsView()
                .tabItem {
                    Label(L10n.settingsLanguage(lang), systemImage: "globe")
                }
        }
        .frame(width: 500, height: 480)
    }
}
