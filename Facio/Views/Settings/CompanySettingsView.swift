import SwiftUI

struct CompanySettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Identite
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.identity(lang), systemImage: "building.2")
                        .font(.headline)

                    settingsRow(L10n.name(lang)) {
                        TextField(L10n.companyName(lang), text: Binding(
                            get: { company.nom },
                            set: { company.nom = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    settingsRow(L10n.address(lang)) {
                        TextField(L10n.postalAddress(lang), text: Binding(
                            get: { company.adresse },
                            set: { company.adresse = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    HStack(alignment: .top, spacing: 12) {
                        settingsRow(L10n.postalCode(lang)) {
                            TextField("54000", text: Binding(
                                get: { company.codePostal },
                                set: { company.codePostal = $0; dataStore.save() }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 120)
                        }

                        settingsRow(L10n.city(lang)) {
                            TextField(L10n.city(lang), text: Binding(
                                get: { company.ville },
                                set: { company.ville = $0; dataStore.save() }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }

                    settingsRow("SIRET") {
                        TextField("000 000 000 00000", text: Binding(
                            get: { company.siret },
                            set: { company.siret = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(12)
            }

            // MARK: - Contact
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.contact(lang), systemImage: "phone")
                        .font(.headline)

                    settingsRow(L10n.phone(lang)) {
                        TextField("06 00 00 00 00", text: Binding(
                            get: { company.telephone },
                            set: { company.telephone = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    settingsRow(L10n.email(lang)) {
                        TextField("contact@entreprise.fr", text: Binding(
                            get: { company.email },
                            set: { company.email = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(12)
            }

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Helpers

    /// Ligne label + champ alignee
    private func settingsRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content()
        }
    }

}
