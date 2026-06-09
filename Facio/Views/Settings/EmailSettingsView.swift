import SwiftUI

/// Réglages d'envoi : modèle d'email (objet + message) personnalisable par
/// langue, avec variables substituées à l'envoi.
struct EmailSettingsView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var templateLang: AppLanguage = .fr

    private var company: CompanyInfo { dataStore.companyInfo }
    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        VStack(spacing: FacioLayout.space20) {
            SectionPanel(L10n.emailTemplateSection(lang), systemImage: "paperplane") {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    LabeledField(L10n.emailTemplateLanguage(lang)) {
                        Picker("", selection: $templateLang) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.label).tag(language)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 240)
                    }

                    LabeledField(L10n.emailSubjectLabel(lang)) {
                        TextField("", text: subjectBinding)
                            .textFieldStyle(.roundedBorder)
                    }

                    LabeledField(L10n.emailBodyLabel(lang)) {
                        TextEditor(text: bodyBinding)
                            .font(.body)
                            .frame(minHeight: 160)
                            .padding(FacioLayout.space4)
                            .overlay(
                                RoundedRectangle(cornerRadius: FacioLayout.radiusField)
                                    .strokeBorder(Color.borderSubtle, lineWidth: 1)
                            )
                    }

                    Text(L10n.emailPlaceholdersHelp(lang))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(L10n.emailResetTemplate(lang)) {
                        resetTemplate()
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(FacioLayout.screenPadding)
    }

    // Le champ affiche le modèle par défaut tant qu'il n'est pas personnalisé.

    private var subjectBinding: Binding<String> {
        Binding(
            get: { company.emailSubjectTemplate(for: templateLang) },
            set: { newValue in
                if templateLang == .fr {
                    company.emailSubjectTemplateFR = newValue
                } else {
                    company.emailSubjectTemplateEN = newValue
                }
                dataStore.companyUpdated()
            }
        )
    }

    private var bodyBinding: Binding<String> {
        Binding(
            get: { company.emailBodyTemplate(for: templateLang) },
            set: { newValue in
                if templateLang == .fr {
                    company.emailBodyTemplateFR = newValue
                } else {
                    company.emailBodyTemplateEN = newValue
                }
                dataStore.companyUpdated()
            }
        )
    }

    private func resetTemplate() {
        if templateLang == .fr {
            company.emailSubjectTemplateFR = ""
            company.emailBodyTemplateFR = ""
        } else {
            company.emailSubjectTemplateEN = ""
            company.emailBodyTemplateEN = ""
        }
        dataStore.companyUpdated()
    }
}
