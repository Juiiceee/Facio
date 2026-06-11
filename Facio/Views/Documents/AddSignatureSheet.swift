import SwiftUI

struct AddSignatureSheet: View {
    let document: Document
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore

    @State private var signature = ""
    @State private var montant: Decimal = 0
    @State private var selectedBlockchain: Blockchain = .solana
    @State private var date = Date()

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var trimmedSignature: String {
        signature.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var compatibleBlockchains: [Blockchain] {
        if let documentBlockchain = document.blockchain {
            return [documentBlockchain]
        }
        let chains = Blockchain.compatibleBlockchains(for: document.currency)
        return chains.isEmpty ? Blockchain.allCases : chains
    }

    private var canAddProof: Bool {
        !trimmedSignature.isEmpty && montant > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            form
            actions
        }
        // Garde-fou minimal ; .form laisse la sheet suivre la taille de la fenêtre.
        .frame(minWidth: FacioLayout.sheetMinWidth, minHeight: 300)
        .presentationSizing(.form)
        .onAppear {
            selectedBlockchain = document.blockchain ?? compatibleBlockchains.first ?? .solana
            montant = document.totalTTC
        }
    }

    private var toolbar: some View {
        HStack {
            Text(L10n.addPaymentProof(lang))
                .font(FacioFont.sectionTitle)
            Spacer()
            Button(L10n.cancel(lang)) { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding()
    }

    private var form: some View {
        Form {
            Picker(L10n.blockchain(lang), selection: $selectedBlockchain) {
                ForEach(compatibleBlockchains) { chain in
                    Text(chain.label).tag(chain)
                }
            }

            TextField(L10n.txHash(lang), text: $signature)
                .font(FacioFont.mono)

            TextField(L10n.amount(lang), value: $montant, format: .number)

            DatePicker(L10n.date(lang), selection: $date, displayedComponents: .date)
        }
        .formStyle(.grouped)
        .padding(.horizontal)
    }

    private var actions: some View {
        HStack {
            Spacer()
            Button(L10n.add(lang)) {
                let tx = TransactionSignature(
                    signature: trimmedSignature,
                    date: date,
                    montant: montant,
                    blockchain: selectedBlockchain
                )
                document.transactionSignatures.append(tx)
                dataStore.documentUpdated(document)
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!canAddProof)
        }
        .padding()
    }
}
