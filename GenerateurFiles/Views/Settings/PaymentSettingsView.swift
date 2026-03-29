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

                ForEach(Array(company.wallets.enumerated()), id: \.element.id) { index, wallet in
                    HStack(spacing: 12) {
                        Picker("Blockchain", selection: Binding(
                            get: { company.wallets[index].blockchain },
                            set: { company.wallets[index].blockchain = $0; dataStore.save() }
                        )) {
                            ForEach(Blockchain.allCases) { chain in
                                Text(chain.label).tag(chain)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 130)

                        TextField("Adresse", text: Binding(
                            get: { company.wallets[index].address },
                            set: { company.wallets[index].address = $0; dataStore.save() }
                        ))

                        Button {
                            removeWallet(wallet)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
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

    private func removeWallet(_ wallet: WalletEntry) {
        company.wallets.removeAll { $0.id == wallet.id }
        dataStore.save()
    }
}
