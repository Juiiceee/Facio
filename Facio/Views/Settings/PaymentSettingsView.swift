import SwiftUI

struct PaymentSettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Paiement Fiat
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Paiement Fiat", systemImage: "building.columns")
                        .font(.headline)

                    settingsRow("IBAN") {
                        TextField("FR76 0000 0000 0000 0000 0000 000", text: Binding(
                            get: { company.iban },
                            set: { company.iban = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    settingsRow("BIC") {
                        TextField("BNPAFRPP", text: Binding(
                            get: { company.bic },
                            set: { company.bic = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    settingsRow("Titulaire du compte") {
                        TextField("Nom du titulaire", text: Binding(
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
                    Label("Wallets Crypto", systemImage: "wallet.pass")
                        .font(.headline)

                    if company.wallets.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("Aucun wallet configure")
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
                        Label("Ajouter un wallet", systemImage: "plus.circle")
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

    private func safeIndex() -> Int? {
        company.wallets.firstIndex(where: { $0.id == walletId })
    }

    var body: some View {
        if company.wallets.contains(where: { $0.id == walletId }) {
            HStack(spacing: 12) {
                Picker("Blockchain", selection: Binding(
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

                TextField("Adresse du wallet", text: Binding(
                    get: { company.wallets.first(where: { $0.id == walletId })?.address ?? "" },
                    set: { newVal in
                        if let i = safeIndex() { company.wallets[i].address = newVal; dataStore.save() }
                    }
                ))
                .textFieldStyle(.roundedBorder)

                Button {
                    company.wallets.removeAll { $0.id == walletId }
                    dataStore.save()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
