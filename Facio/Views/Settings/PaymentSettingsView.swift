import SwiftUI

struct PaymentSettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        VStack(spacing: FacioLayout.space20) {
            // MARK: - Paiement Fiat
            SectionPanel(L10n.bankAccounts(lang), systemImage: "building.columns") {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    if company.bankAccounts.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text(L10n.noBankAccountConfiguredShort(lang))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, FacioLayout.space4)
                    }

                    ForEach(company.bankAccounts) { account in
                        BankAccountRow(accountId: account.id, company: company, dataStore: dataStore)
                    }

                    Button {
                        addBankAccount()
                    } label: {
                        Label(L10n.addBankAccount(lang), systemImage: "plus.circle")
                    }
                }
            }

            // MARK: - Wallets Crypto
            SectionPanel(L10n.cryptoWallets(lang), systemImage: "wallet.pass") {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    if company.wallets.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text(L10n.noWalletConfiguredShort(lang))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, FacioLayout.space4)
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
            }

            Spacer()
        }
        .padding(FacioLayout.screenPadding)
    }

    private func addWallet() {
        let entry = WalletEntry(blockchain: .solana, address: "")
        company.wallets.append(entry)
        dataStore.companyUpdated()
    }

    private func addBankAccount() {
        company.bankAccounts.append(BankAccountEntry())
        company.syncLegacyBankFieldsFromPrimaryAccount()
        dataStore.companyUpdated()
    }
}

/// Ligne compte bancaire avec acces securise par ID (pas par index)
private struct BankAccountRow: View {
    let accountId: UUID
    let company: CompanyInfo
    let dataStore: DataStore

    private var lang: AppLanguage { company.langueParDefaut }

    private func safeIndex() -> Int? {
        company.bankAccounts.firstIndex(where: { $0.id == accountId })
    }

    private var account: BankAccountEntry? {
        company.bankAccounts.first(where: { $0.id == accountId })
    }

    private var iban: String {
        account?.iban ?? ""
    }

    var body: some View {
        if company.bankAccounts.contains(where: { $0.id == accountId }) {
            VStack(alignment: .leading, spacing: FacioLayout.space10) {
                HStack(spacing: FacioLayout.space12) {
                    TextField(L10n.bankAccountNamePlaceholder(lang), text: Binding(
                        get: { account?.label ?? "" },
                        set: { setAccountValue(\.label, to: $0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 220)

                    TextField(L10n.bankNamePlaceholder(lang), text: Binding(
                        get: { account?.bankName ?? "" },
                        set: { setAccountValue(\.bankName, to: $0) }
                    ))
                    .textFieldStyle(.roundedBorder)

                    Button {
                        company.bankAccounts.removeAll { $0.id == accountId }
                        company.syncLegacyBankFieldsFromPrimaryAccount()
                        dataStore.companyUpdated()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Color.intentDanger)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(L10n.removeBankAccount(lang))
                    .accessibilityLabel(L10n.removeBankAccount(lang))
                }

                LabeledField(L10n.iban(lang)) {
                    TextField(L10n.ibanPlaceholder(lang), text: Binding(
                        get: { account?.iban ?? "" },
                        set: { setAccountValue(\.iban, to: $0) }
                    ))
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: FacioLayout.space12) {
                    LabeledField(L10n.bic(lang)) {
                        TextField(L10n.bicPlaceholder(lang), text: Binding(
                            get: { account?.bic ?? "" },
                            set: { setAccountValue(\.bic, to: $0) }
                        ))
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                    }

                    LabeledField(L10n.accountHolderLabel(lang)) {
                        TextField(L10n.accountHolderPlaceholder(lang), text: Binding(
                            get: { account?.accountHolder ?? "" },
                            set: { setAccountValue(\.accountHolder, to: $0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }

                if iban.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(spacing: FacioLayout.space6) {
                        Image(systemName: "exclamationmark.triangle")
                        Text(L10n.bankAccountIbanRequired(lang))
                    }
                    .font(.caption)
                    .foregroundStyle(Color.intentWarning)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(FacioLayout.space10)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
        }
    }

    private func setAccountValue(_ keyPath: WritableKeyPath<BankAccountEntry, String>, to newValue: String) {
        if let i = safeIndex() {
            company.bankAccounts[i][keyPath: keyPath] = newValue
            company.syncLegacyBankFieldsFromPrimaryAccount()
            dataStore.companyUpdated()
        }
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

    private var walletAddress: String {
        company.wallets.first(where: { $0.id == walletId })?.address ?? ""
    }

    var body: some View {
        if company.wallets.contains(where: { $0.id == walletId }) {
            VStack(spacing: FacioLayout.space8) {
                HStack(spacing: FacioLayout.space12) {
                    Picker(L10n.blockchain(lang), selection: Binding(
                        get: { company.wallets.first(where: { $0.id == walletId })?.blockchain ?? .solana },
                        set: { newVal in
                            if let i = safeIndex() { company.wallets[i].blockchain = newVal; dataStore.companyUpdated() }
                        }
                    )) {
                        ForEach(Blockchain.allCases) { chain in
                            Text(chain.label).tag(chain)
                        }
                    }
                    .labelsHidden()
                    .accessibilityLabel(L10n.blockchain(lang))
                    .frame(width: 130)

                    TextField(L10n.walletNamePlaceholder(lang), text: Binding(
                        get: { company.wallets.first(where: { $0.id == walletId })?.label ?? "" },
                        set: { newVal in
                            if let i = safeIndex() { company.wallets[i].label = newVal; dataStore.companyUpdated() }
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)

                    Button {
                        company.wallets.removeAll { $0.id == walletId }
                        dataStore.companyUpdated()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Color.intentDanger)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(L10n.removeWallet(lang))
                    .accessibilityLabel(L10n.removeWallet(lang))
                }

                TextField(L10n.walletAddressPlaceholder(lang), text: Binding(
                    get: { company.wallets.first(where: { $0.id == walletId })?.address ?? "" },
                    set: { newVal in
                        if let i = safeIndex() { company.wallets[i].address = newVal; dataStore.companyUpdated() }
                    }
                ))
                .textFieldStyle(.roundedBorder)

                if walletAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(spacing: FacioLayout.space6) {
                        Image(systemName: "exclamationmark.triangle")
                        Text(L10n.walletAddressRequired(lang))
                    }
                    .font(.caption)
                    .foregroundStyle(Color.intentWarning)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(FacioLayout.space10)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
        }
    }
}
