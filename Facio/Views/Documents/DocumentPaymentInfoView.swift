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
                let bankAccounts = document.paymentBankAccounts(from: company.bankAccounts)

                if bankAccounts.count > 1 {
                    bankAccountPicker(bankAccounts)
                    selectedBankAccountDetails(bankAccounts)
                } else if let account = bankAccounts.first {
                    bankAccountDetails(account)
                } else {
                    warningRow(L10n.noBankAccountConfigured(lang))
                }
            }
            .padding(8)
        }
    }

    private func bankAccountPicker(_ accounts: [BankAccountEntry]) -> some View {
        HStack {
            Label(L10n.bankAccount(lang), systemImage: "building.columns")
                .foregroundStyle(.secondary)
            Picker("", selection: Binding(
                get: {
                    accounts.first { $0.id == document.selectedBankAccountId }?.id ?? accounts.first?.id ?? UUID()
                },
                set: {
                    document.selectedBankAccountId = $0
                    document.paymentSnapshot = nil
                    onSave()
                }
            )) {
                ForEach(accounts) { account in
                    Text(account.displayName.isEmpty ? L10n.bankAccount(lang) : account.displayName)
                        .tag(account.id)
                }
            }
            .labelsHidden()
        }
    }

    @ViewBuilder
    private func selectedBankAccountDetails(_ accounts: [BankAccountEntry]) -> some View {
        if let selected = accounts.first(where: { $0.id == document.selectedBankAccountId }) ?? accounts.first {
            bankAccountDetails(selected)
        }
    }

    private func bankAccountDetails(_ account: BankAccountEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !account.trimmedBankName.isEmpty || !account.trimmedLabel.isEmpty {
                HStack {
                    Label(account.displayName.isEmpty ? L10n.bankAccount(lang) : account.displayName, systemImage: "building.columns")
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Label(L10n.iban(lang), systemImage: "number")
                    .foregroundStyle(.secondary)
                Text(account.trimmedIBAN)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }

            if !account.trimmedBIC.isEmpty {
                HStack {
                    Label(L10n.bic(lang), systemImage: "building.columns.fill")
                        .foregroundStyle(.secondary)
                    Text(account.trimmedBIC)
                        .font(.system(.body, design: .monospaced))
                }
            }

            if !account.trimmedAccountHolder.isEmpty {
                HStack {
                    Label(L10n.accountHolderLabel(lang), systemImage: "person")
                        .foregroundStyle(.secondary)
                    Text(account.trimmedAccountHolder)
                }
            }
        }
    }

    private var cryptoSection: some View {
        GroupBox(L10n.paymentCryptoSection(lang)) {
            VStack(alignment: .leading, spacing: 8) {
                if let chain = document.blockchain {
                    let walletsForChain = document.paymentWallets(from: company.wallets, for: chain)

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
                    wallets.first { $0.id == document.selectedWalletId }?.id ?? wallets.first?.id ?? UUID()
                },
                set: {
                    document.selectedWalletId = $0
                    document.paymentSnapshot = nil
                    onSave()
                }
            )) {
                ForEach(wallets) { wallet in
                    let address = document.paymentAddress(for: wallet)
                    Text(wallet.label.isEmpty ? "\(address.prefix(12))..." : wallet.label)
                        .tag(wallet.id)
                }
            }
            .labelsHidden()
        }
    }

    @ViewBuilder
    private func selectedWalletAddress(_ wallets: [WalletEntry]) -> some View {
        if let selected = wallets.first(where: { $0.id == document.selectedWalletId }) ?? wallets.first {
            Text(document.paymentAddress(for: selected))
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
            Text(document.paymentAddress(for: wallet))
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
