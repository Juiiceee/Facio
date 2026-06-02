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

                    LabeledField(L10n.name(lang)) {
                        TextField(L10n.companyName(lang), text: Binding(
                            get: { company.nom },
                            set: { company.nom = $0; dataStore.companyUpdated() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    LabeledField(L10n.address(lang)) {
                        TextField(L10n.postalAddress(lang), text: Binding(
                            get: { company.adresse },
                            set: { company.adresse = $0; dataStore.companyUpdated() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    HStack(alignment: .top, spacing: 12) {
                        LabeledField(L10n.postalCode(lang)) {
                            TextField(L10n.postalCodePlaceholder(lang), text: Binding(
                                get: { company.codePostal },
                                set: { company.codePostal = $0; dataStore.companyUpdated() }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 120)
                        }

                        LabeledField(L10n.city(lang)) {
                            TextField(L10n.city(lang), text: Binding(
                                get: { company.ville },
                                set: { company.ville = $0; dataStore.companyUpdated() }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }

                    LabeledField(L10n.siret(lang)) {
                        TextField(L10n.siretPlaceholder(lang), text: Binding(
                            get: { company.siret },
                            set: { company.siret = $0; dataStore.companyUpdated() }
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

                    LabeledField(L10n.phone(lang)) {
                        TextField(L10n.phonePlaceholder(lang), text: Binding(
                            get: { company.telephone },
                            set: { company.telephone = $0; dataStore.companyUpdated() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    LabeledField(L10n.email(lang)) {
                        TextField(L10n.contactEmailPlaceholder(lang), text: Binding(
                            get: { company.email },
                            set: { company.email = $0; dataStore.companyUpdated() }
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
}
