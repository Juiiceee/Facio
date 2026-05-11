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

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            form
            actions
        }
        .frame(minWidth: 500, minHeight: 300)
        .onAppear {
            if let chain = document.blockchain {
                selectedBlockchain = chain
            }
            montant = document.totalTTC
        }
    }

    private var toolbar: some View {
        HStack {
            Text(L10n.addPaymentProof(lang))
                .font(.headline)
            Spacer()
            Button(L10n.cancel(lang)) { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding()
    }

    private var form: some View {
        Form {
            Picker(L10n.blockchain(lang), selection: $selectedBlockchain) {
                ForEach(Blockchain.allCases) { chain in
                    Text(chain.label).tag(chain)
                }
            }

            TextField(L10n.txHash(lang), text: $signature)
                .font(.system(.body, design: .monospaced))

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
                    signature: signature,
                    date: date,
                    montant: montant,
                    blockchain: selectedBlockchain
                )
                document.transactionSignatures.append(tx)
                dataStore.save()
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(signature.isEmpty)
        }
        .padding()
    }
}
