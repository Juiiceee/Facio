import SwiftUI

struct PaymentSettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Paiement Fiat
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.fiatPayment(lang), systemImage: "building.columns")
                        .font(.headline)

                    settingsRow(L10n.bankName(lang)) {
                        TextField(L10n.bankNamePlaceholder(lang), text: Binding(
                            get: { company.nomBanque },
                            set: { company.nomBanque = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    settingsRow(L10n.iban(lang)) {
                        TextField("FR76 0000 0000 0000 0000 0000 000", text: Binding(
                            get: { company.iban },
                            set: { company.iban = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    settingsRow(L10n.bic(lang)) {
                        TextField("BNPAFRPP", text: Binding(
                            get: { company.bic },
                            set: { company.bic = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    settingsRow(L10n.accountHolderLabel(lang)) {
                        TextField(L10n.accountHolderPlaceholder(lang), text: Binding(
                            get: { company.titulaireCompte },
                            set: { company.titulaireCompte = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(12)
            }

            // MARK: - Wallets Crypto
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.cryptoWallets(lang), systemImage: "wallet.pass")
                        .font(.headline)

                    if company.wallets.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text(L10n.noWalletConfiguredShort(lang))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    ForEach(company.wallets) { wallet in
                        WalletRow(walletId: wallet.id, company: company, dataStore: dataStore)
                    }

                    Button {
                        addWallet()
                    } label: {
                        Label(L10n.addWallet(lang), systemImage: "plus.circle")
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

    private func addWallet() {
        let entry = WalletEntry(blockchain: .solana, address: "")
        company.wallets.append(entry)
        dataStore.save()
    }
}

/// Ligne wallet avec acces securise par ID (pas par index)
private struct WalletRow: View {
    let walletId: UUID
    let company: CompanyInfo
    let dataStore: DataStore

    private var lang: AppLanguage { company.langueParDefaut }

    private func safeIndex() -> Int? {
        company.wallets.firstIndex(where: { $0.id == walletId })
    }

    var body: some View {
        if company.wallets.contains(where: { $0.id == walletId }) {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Picker(L10n.blockchain(lang), selection: Binding(
                        get: { company.wallets.first(where: { $0.id == walletId })?.blockchain ?? .solana },
                        set: { newVal in
                            if let i = safeIndex() { company.wallets[i].blockchain = newVal; dataStore.save() }
                        }
                    )) {
                        ForEach(Blockchain.allCases) { chain in
                            Text(chain.label).tag(chain)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 130)

                    TextField(L10n.walletNamePlaceholder(lang), text: Binding(
                        get: { company.wallets.first(where: { $0.id == walletId })?.label ?? "" },
                        set: { newVal in
                            if let i = safeIndex() { company.wallets[i].label = newVal; dataStore.save() }
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)

                    Button {
                        company.wallets.removeAll { $0.id == walletId }
                        dataStore.save()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }

                TextField(L10n.walletAddressPlaceholder(lang), text: Binding(
                    get: { company.wallets.first(where: { $0.id == walletId })?.address ?? "" },
                    set: { newVal in
                        if let i = safeIndex() { company.wallets[i].address = newVal; dataStore.save() }
                    }
                ))
                .textFieldStyle(.roundedBorder)
            }
            .padding(10)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
