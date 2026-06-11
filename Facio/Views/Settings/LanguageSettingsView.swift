import SwiftUI

struct LanguageSettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    private var lang: AppLanguage { company.langueParDefaut }

    var body: some View {
        VStack(spacing: FacioLayout.space20) {
            // MARK: - Langue par defaut
            SectionPanel(L10n.language(lang), systemImage: "globe") {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    LabeledField(L10n.defaultLanguage(lang)) {
                        Picker("", selection: Binding(
                            get: { company.langueParDefaut },
                            set: { company.langueParDefaut = $0; dataStore.companyUpdated() }
                        )) {
                            ForEach(AppLanguage.allCases) { l in
                                Text(l.label).tag(l)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 200)
                    }

                    Text(L10n.defaultLanguageHint(lang))
                        .font(FacioFont.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Format de date
            SectionPanel(L10n.dateFormat(lang), systemImage: "calendar") {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    LabeledField(L10n.dateFormat(lang)) {
                        Picker("", selection: Binding(
                            get: { company.formatDate },
                            set: { company.formatDate = $0; dataStore.companyUpdated() }
                        )) {
                            Text(L10n.frenchDateFormatSample(lang)).tag(AppLanguage.fr)
                            Text(L10n.englishDateFormatSample(lang)).tag(AppLanguage.en)
                        }
                        .labelsHidden()
                        .frame(maxWidth: 300)
                    }
                }
            }

            // MARK: - Format des nombres
            SectionPanel(L10n.numberFormat(lang), systemImage: "textformat.123") {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    LabeledField(L10n.numberFormat(lang)) {
                        Picker("", selection: Binding(
                            get: { company.formatNombre },
                            set: { company.formatNombre = $0; dataStore.companyUpdated() }
                        )) {
                            Text(L10n.frenchNumberFormatSample(lang)).tag(AppLanguage.fr)
                            Text(L10n.englishNumberFormatSample(lang)).tag(AppLanguage.en)
                        }
                        .labelsHidden()
                        .frame(maxWidth: 300)
                    }
                }
            }

            Spacer()
        }
        .padding(FacioLayout.screenPadding)
    }

}
