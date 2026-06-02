import SwiftUI

struct DefaultsSettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }

    private let tauxTVAOptions: [Decimal] = [0, 5.5, 10, 20]

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - TVA
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.vatRate(lang), systemImage: "percent")
                        .font(.headline)

                    LabeledField(L10n.defaultRate(lang)) {
                        Picker("", selection: Binding(
                            get: { company.tauxTVAParDefaut },
                            set: { company.tauxTVAParDefaut = $0; dataStore.companyUpdated() }
                        )) {
                            ForEach(tauxTVAOptions, id: \.self) { option in
                                Text(percentLabel(option)).tag(option)
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
                    Label(L10n.currency(lang), systemImage: "dollarsign.circle")
                        .font(.headline)

                    LabeledField(L10n.defaultCurrency(lang)) {
                        Picker("", selection: Binding(
                            get: { company.deviseParDefaut },
                            set: { newValue in
                                company.deviseParDefaut = newValue
                                normalizeDefaultBlockchain(for: newValue)
                                dataStore.companyUpdated()
                            }
                        )) {
                            ForEach(CurrencyType.allCases) { devise in
                                Text(devise.label).tag(devise)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 200)
                    }

                    LabeledField(L10n.accountingCurrencySetting(lang)) {
                        Picker("", selection: Binding(
                            get: { company.deviseComptable },
                            set: { company.deviseComptable = $0; dataStore.companyUpdated() }
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

                        LabeledField(L10n.defaultBlockchain(lang)) {
                            Picker("", selection: Binding(
                                get: { company.blockchainParDefaut ?? compatible.first ?? .solana },
                                set: { company.blockchainParDefaut = $0; dataStore.companyUpdated() }
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
                    Label(L10n.paymentDelay(lang), systemImage: "calendar.badge.clock")
                        .font(.headline)

                    HStack {
                        Text(L10n.defaultDelay(lang))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Stepper(
                            L10n.days(lang, count: company.delaiPaiementJours),
                            value: Binding(
                                get: { company.delaiPaiementJours },
                                set: { company.delaiPaiementJours = $0; dataStore.companyUpdated() }
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

    private func percentLabel(_ value: Decimal) -> String {
        "\(value.formattedDecimal(maxFractionDigits: 2, for: numberFormat)) %"
    }

    private func normalizeDefaultBlockchain(for currency: CurrencyType) {
        guard currency.requiresBlockchain else {
            company.blockchainParDefaut = nil
            return
        }

        let compatible = Blockchain.compatibleBlockchains(for: currency)
        if let current = company.blockchainParDefaut, compatible.contains(current) {
            return
        }
        company.blockchainParDefaut = compatible.first
    }
}
