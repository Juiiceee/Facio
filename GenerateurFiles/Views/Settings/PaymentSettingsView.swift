import SwiftUI

struct PaymentSettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    var body: some View {
        Form {
            Section("Paiement Fiat") {
                TextField("IBAN", text: Binding(
                    get: { company.iban },
                    set: { company.iban = $0; dataStore.save() }
                ))
                TextField("BIC", text: Binding(
                    get: { company.bic },
                    set: { company.bic = $0; dataStore.save() }
                ))
                TextField("Titulaire du compte", text: Binding(
                    get: { company.titulaireCompte },
                    set: { company.titulaireCompte = $0; dataStore.save() }
                ))
            }

            Section("Wallets Crypto") {
                if company.wallets.isEmpty {
                    Text("Aucun wallet configure")
                        .foregroundStyle(.secondary)
                        .italic()
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
        }
        .formStyle(.grouped)
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
        if let wallet = company.wallets.first(where: { $0.id == walletId }) {
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

                TextField("Adresse", text: Binding(
                    get: { company.wallets.first(where: { $0.id == walletId })?.address ?? "" },
                    set: { newVal in
                        if let i = safeIndex() { company.wallets[i].address = newVal; dataStore.save() }
                    }
                ))

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
