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
        VStack(spacing: 20) {
            // MARK: - TVA
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Taux de TVA", systemImage: "percent")
                        .font(.headline)

                    settingsRow("Taux par defaut") {
                        Picker("", selection: Binding(
                            get: { company.tauxTVAParDefaut },
                            set: { company.tauxTVAParDefaut = $0; dataStore.save() }
                        )) {
                            ForEach(tauxTVAOptions, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 200)
                    }
                }
                .padding(12)
            }

            // MARK: - Devise
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Devise", systemImage: "dollarsign.circle")
                        .font(.headline)

                    settingsRow("Devise par defaut") {
                        Picker("", selection: Binding(
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
                        .labelsHidden()
                        .frame(maxWidth: 200)
                    }

                    if company.deviseParDefaut.requiresBlockchain {
                        let compatible = Blockchain.compatibleBlockchains(for: company.deviseParDefaut)

                        settingsRow("Blockchain par defaut") {
                            Picker("", selection: Binding(
                                get: { company.blockchainParDefaut ?? compatible.first ?? .solana },
                                set: { company.blockchainParDefaut = $0; dataStore.save() }
                            )) {
                                ForEach(compatible) { chain in
                                    Text(chain.label).tag(chain)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: 200)
                        }
                    }
                }
                .padding(12)
            }

            // MARK: - Delai de paiement
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Delai de paiement", systemImage: "calendar.badge.clock")
                        .font(.headline)

                    HStack {
                        Text("Delai par defaut")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Stepper(
                            "\(company.delaiPaiementJours) jours",
                            value: Binding(
                                get: { company.delaiPaiementJours },
                                set: { company.delaiPaiementJours = $0; dataStore.save() }
                            ),
                            in: 0...120,
                            step: 5
                        )
                        .frame(maxWidth: 200)
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
