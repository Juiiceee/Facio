import SwiftUI

struct LanguageSettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    private var lang: AppLanguage { company.langueParDefaut }

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Langue par defaut
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.language(lang), systemImage: "globe")
                        .font(.headline)

                    settingsRow(L10n.defaultLanguage(lang)) {
                        Picker("", selection: Binding(
                            get: { company.langueParDefaut },
                            set: { company.langueParDefaut = $0; dataStore.save() }
                        )) {
                            ForEach(AppLanguage.allCases) { l in
                                Text(l.label).tag(l)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 200)
                    }

                    Text(L10n.defaultLanguageHint(lang))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
            }

            // MARK: - Format de date
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.dateFormat(lang), systemImage: "calendar")
                        .font(.headline)

                    settingsRow(L10n.dateFormat(lang)) {
                        Picker("", selection: Binding(
                            get: { company.formatDate },
                            set: { company.formatDate = $0; dataStore.save() }
                        )) {
                            Text("dd/MM/yyyy (02/04/2026)").tag(AppLanguage.fr)
                            Text("MM/dd/yyyy (04/02/2026)").tag(AppLanguage.en)
                        }
                        .labelsHidden()
                        .frame(maxWidth: 300)
                    }
                }
                .padding(12)
            }

            // MARK: - Format des nombres
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.numberFormat(lang), systemImage: "textformat.123")
                        .font(.headline)

                    settingsRow(L10n.numberFormat(lang)) {
                        Picker("", selection: Binding(
                            get: { company.formatNombre },
                            set: { company.formatNombre = $0; dataStore.save() }
                        )) {
                            Text("1 234,56 (FR)").tag(AppLanguage.fr)
                            Text("1,234.56 (EN)").tag(AppLanguage.en)
                        }
                        .labelsHidden()
                        .frame(maxWidth: 300)
                    }
                }
                .padding(12)
            }

            Spacer()
        }
        .padding(24)
    }

    private func settingsRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content()
        }
    }
}
