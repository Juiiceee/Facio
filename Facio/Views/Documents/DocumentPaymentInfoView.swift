import SwiftUI

struct DocumentPaymentInfoView: View {
    let document: Document
    let company: CompanyInfo
    let lang: AppLanguage
    let onSave: () -> Void

    var body: some View {
        switch document.paymentMode {
        case .aucun:
            EmptyView()

        case .virement:
            bankTransferSection

        case .crypto:
            cryptoSection
        }
    }

    private var bankTransferSection: some View {
        GroupBox(L10n.paymentBankSection(lang)) {
            VStack(alignment: .leading, spacing: 8) {
                if !company.iban.isEmpty {
                    HStack {
                        Label(L10n.iban(lang), systemImage: "building.columns")
                            .foregroundStyle(.secondary)
                        Text(company.iban)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    if !company.bic.isEmpty {
                        HStack {
                            Label(L10n.bic(lang), systemImage: "building.columns.fill")
                                .foregroundStyle(.secondary)
                            Text(company.bic)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    if !company.titulaireCompte.isEmpty {
                        HStack {
                            Label(L10n.accountHolderLabel(lang), systemImage: "person")
                                .foregroundStyle(.secondary)
                            Text(company.titulaireCompte)
                        }
                    }
                } else {
                    warningRow(L10n.noIBANConfigured(lang))
                }
            }
            .padding(8)
        }
    }

    private var cryptoSection: some View {
        GroupBox(L10n.paymentCryptoSection(lang)) {
            VStack(alignment: .leading, spacing: 8) {
                if let chain = document.blockchain {
                    let walletsForChain = company.wallets.filter { $0.blockchain == chain }

                    HStack {
                        Label(L10n.network(lang), systemImage: "link")
                            .foregroundStyle(.secondary)
                        Text(chain.label)
                            .fontWeight(.medium)
                    }

                    if walletsForChain.count > 1 {
                        walletPicker(walletsForChain)
                        selectedWalletAddress(walletsForChain)
                    } else if let wallet = walletsForChain.first {
                        walletAddressRow(wallet)
                    } else {
                        warningRow(L10n.noWalletConfigured(lang, chain: chain.label))
                    }
                } else {
                    warningRow(L10n.selectNetwork(lang))
                }
            }
            .padding(8)
        }
    }

    private func walletPicker(_ wallets: [WalletEntry]) -> some View {
        HStack {
            Label(L10n.wallet(lang), systemImage: "wallet.pass")
                .foregroundStyle(.secondary)
            Picker("", selection: Binding(
                get: {
                    document.selectedWalletId ?? wallets.first?.id ?? UUID()
                },
                set: {
                    document.selectedWalletId = $0
                    onSave()
                }
            )) {
                ForEach(wallets) { wallet in
                    Text(wallet.label.isEmpty ? wallet.address.prefix(12) + "..." : wallet.label)
                        .tag(wallet.id)
                }
            }
            .labelsHidden()
        }
    }

    @ViewBuilder
    private func selectedWalletAddress(_ wallets: [WalletEntry]) -> some View {
        if let selected = wallets.first(where: { $0.id == (document.selectedWalletId ?? wallets.first?.id) }) {
            Text(selected.address)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .foregroundStyle(.secondary)
        }
    }

    private func walletAddressRow(_ wallet: WalletEntry) -> some View {
        HStack {
            Label(wallet.label.isEmpty ? L10n.wallet(lang) : wallet.label, systemImage: "wallet.pass")
                .foregroundStyle(.secondary)
            Text(wallet.address)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
    }

    private func warningRow(_ text: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
            Text(text)
                .foregroundStyle(.orange)
        }
    }
}
