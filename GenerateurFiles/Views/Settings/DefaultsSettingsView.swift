import SwiftUI

struct DefaultsSettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    private let tauxTVAOptions: [(label: String, value: Decimal)] = [
        ("0 %", 0),
        ("5,5 %", 5.5),
        ("10 %", 10),
        ("20 %", 20)
    ]

    var body: some View {
        Form {
            Section("Taux de TVA") {
                Picker("Taux par defaut", selection: Binding(
                    get: { company.tauxTVAParDefaut },
                    set: { company.tauxTVAParDefaut = $0; dataStore.save() }
                )) {
                    ForEach(tauxTVAOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
            }

            Section("Devise") {
                Picker("Devise par defaut", selection: Binding(
                    get: { company.deviseParDefaut },
                    set: { newValue in
                        company.deviseParDefaut = newValue
                        if !newValue.requiresBlockchain {
                            company.blockchainParDefaut = nil
                        } else if company.blockchainParDefaut == nil {
                            let compatible = Blockchain.compatibleBlockchains(for: newValue)
                            company.blockchainParDefaut = compatible.first
                        }
                        dataStore.save()
                    }
                )) {
                    ForEach(CurrencyType.allCases) { devise in
                        Text(devise.label).tag(devise)
                    }
                }

                if company.deviseParDefaut.requiresBlockchain {
                    let compatible = Blockchain.compatibleBlockchains(for: company.deviseParDefaut)

                    Picker("Blockchain par defaut", selection: Binding(
                        get: { company.blockchainParDefaut ?? compatible.first ?? .solana },
                        set: { company.blockchainParDefaut = $0; dataStore.save() }
                    )) {
                        ForEach(compatible) { chain in
                            Text(chain.label).tag(chain)
                        }
                    }
                }
            }

            Section("Delai de paiement") {
                Stepper(
                    "Delai : \(company.delaiPaiementJours) jours",
                    value: Binding(
                        get: { company.delaiPaiementJours },
                        set: { company.delaiPaiementJours = $0; dataStore.save() }
                    ),
                    in: 0...120,
                    step: 5
                )
            }
        }
        .formStyle(.grouped)
    }
}
