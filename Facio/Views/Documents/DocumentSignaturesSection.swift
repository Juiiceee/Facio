import SwiftUI

struct DocumentSignaturesSection: View {
    let document: Document
    let lang: AppLanguage
    let onAdd: () -> Void
    let onDelete: (TransactionSignature) -> Void

    var body: some View {
        GroupBox(L10n.paymentProofsSection(lang)) {
            VStack(alignment: .leading, spacing: 8) {
                content
                Button {
                    onAdd()
                } label: {
                    Label(L10n.addSignature(lang), systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
            }
            .padding(8)
        }
    }

    private var content: some View {
        Group {
            if document.transactionSignatures.isEmpty {
                Text(L10n.noSignatures(lang))
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(document.transactionSignatures) { signature in
                    SignatureRowView(document: document, signature: signature, lang: lang) {
                        onDelete(signature)
                    }
                    Divider()
                }
            }
        }
    }
}

private struct SignatureRowView: View {
    let document: Document
    let signature: TransactionSignature
    let lang: AppLanguage
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(signature.signature)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 8) {
                    Text(signature.blockchain.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.appPrimary.opacity(0.1))
                        .clipShape(Capsule())
                    Text(signature.date.frenchFormatted)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(document.currency.format(signature.montant))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let url = signature.explorerURL {
                Link(destination: url) {
                    Label(L10n.viewOn(lang, explorer: signature.explorerName), systemImage: "arrow.up.right.square")
                        .font(.caption)
                }
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .frame(width: 32, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}
