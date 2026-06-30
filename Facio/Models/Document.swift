import Foundation
import Observation

struct DocumentPaymentSnapshot: Codable, Hashable {
    var paymentModeRawValue: String = PaymentMode.aucun.rawValue
    var blockchainRawValue: String?
    var walletAddress: String = ""
    var bankName: String = ""
    var iban: String = ""
    var bic: String = ""
    var accountHolder: String = ""
    var createdAt: Date = Date()
    var isTrustedForExport: Bool = true

    init(
        paymentModeRawValue: String = PaymentMode.aucun.rawValue,
        blockchainRawValue: String? = nil,
        walletAddress: String = "",
        bankName: String = "",
        iban: String = "",
        bic: String = "",
        accountHolder: String = "",
        createdAt: Date = Date(),
        isTrustedForExport: Bool = true
    ) {
        self.paymentModeRawValue = paymentModeRawValue
        self.blockchainRawValue = blockchainRawValue
        self.walletAddress = walletAddress
        self.bankName = bankName
        self.iban = iban
        self.bic = bic
        self.accountHolder = accountHolder
        self.createdAt = createdAt
        self.isTrustedForExport = isTrustedForExport
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        paymentModeRawValue = try container.decodeIfPresent(String.self, forKey: .paymentModeRawValue)
            ?? PaymentMode.aucun.rawValue
        blockchainRawValue = try container.decodeIfPresent(String.self, forKey: .blockchainRawValue)
        walletAddress = try container.decodeIfPresent(String.self, forKey: .walletAddress) ?? ""
        bankName = try container.decodeIfPresent(String.self, forKey: .bankName) ?? ""
        iban = try container.decodeIfPresent(String.self, forKey: .iban) ?? ""
        bic = try container.decodeIfPresent(String.self, forKey: .bic) ?? ""
        accountHolder = try container.decodeIfPresent(String.self, forKey: .accountHolder) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        isTrustedForExport = try container.decodeIfPresent(Bool.self, forKey: .isTrustedForExport) ?? true
    }

    private enum CodingKeys: String, CodingKey {
        case paymentModeRawValue
        case blockchainRawValue
        case walletAddress
        case bankName
        case iban
        case bic
        case accountHolder
        case createdAt
        case isTrustedForExport
    }

    var paymentMode: PaymentMode {
        PaymentMode(rawValue: paymentModeRawValue) ?? .aucun
    }

    var blockchain: Blockchain? {
        guard let blockchainRawValue else { return nil }
        return Blockchain(rawValue: blockchainRawValue)
    }

    var hasUsablePaymentDetails: Bool {
        switch paymentMode {
        case .aucun:
            return false
        case .crypto:
            return !walletAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .virement:
            return !iban.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

@Observable
final class Document: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var typeRawValue: String = "Facture"
    var number: String = ""
    var dateCreation: Date = Date()
    var dateEcheance: Date = Date()
    /// Date d'encaissement de la facture soldée (statut « Payée »). Sert à
    /// rattacher le CA au bon mois. Nil tant que la facture n'est pas payée. Les
    /// factures partielles datent chaque versement via `paiementsPartiels`.
    var datePaiement: Date?
    /// Journal des versements partiels (statut « Partiel ») : chaque versement
    /// porte son montant et sa date. Vide hors statut partiel.
    var paiementsPartiels: [PartialPayment] = []
    var statusRawValue: String = "Brouillon"
    var currencyRawValue: String = "EUR"
    var blockchainRawValue: String?
    var paymentModeRawValue: String = "Aucun"
    var accountingCurrencyRawValue: String?
    var accountingExchangeRate: Decimal?
    var accountingExchangeRateDate: Date?

    // Client embarque (copie figee)
    var clientNom: String = ""
    var clientAdresse: String = ""
    var clientCodePostal: String = ""
    var clientVille: String = ""
    var clientSiret: String = ""
    var clientTva: String = ""
    var clientApe: String = ""
    var clientEmail: String = ""

    // Relations
    var lignes: [LineItem] = []
    var transactionSignatures: [TransactionSignature] = []
    /// Justificatifs joints (métadonnées ; fichiers stockés localement par DataStore).
    var attachments: [DocumentAttachment] = []
    var sourceTimesheetId: UUID?
    var timesheetAutoSyncSignature: String?

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Notes optionnelles
    var notes: String = ""

    // Langue du document (FR/EN)
    var langueRawValue: String = "fr"

    var langue: AppLanguage {
        get { AppLanguage(rawValue: langueRawValue) ?? .fr }
        set { langueRawValue = newValue.rawValue }
    }

    // Wallet selectionne (quand plusieurs sur le meme reseau)
    var selectedWalletId: UUID?

    // Compte bancaire selectionne (quand plusieurs comptes sont configures)
    var selectedBankAccountId: UUID?

    // Copie figee des informations de paiement utilisees pour les exports officiels.
    var paymentSnapshot: DocumentPaymentSnapshot?

    // MARK: - Hashable

    static func == (lhs: Document, rhs: Document) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Computed enums

    var type: DocumentType {
        get { DocumentType(rawValue: typeRawValue) ?? .facture }
        set { typeRawValue = newValue.rawValue }
    }

    var status: DocumentStatus {
        get { DocumentStatus(rawValue: statusRawValue) ?? .brouillon }
        set {
            let previous = DocumentStatus(rawValue: statusRawValue) ?? .brouillon
            switch newValue {
            case .payee:
                if previous == .partiel {
                    // Solder depuis « Partiel » : on enregistre le reliquat éventuel
                    // comme dernier versement daté du jour et on CONSERVE le journal
                    // daté — le CA garde l'attribution mois par mois des encaissements
                    // (re-dater l'ensemble effacerait l'historique des versements).
                    paiementsPartiels.removeAll { $0.montant == 0 }
                    let collected = min(max(montantPaye, 0), totalTTC)
                    let remaining = totalTTC - collected
                    if remaining > 0 {
                        paiementsPartiels.append(PartialPayment(montant: remaining, date: Date()))
                    }
                    datePaiement = paiementsPartiels.map(\.date).max()
                } else {
                    // Encaissement en une fois : on horodate le règlement.
                    if datePaiement == nil { datePaiement = Date() }
                    paiementsPartiels = []
                }
            case .partiel:
                // Les dates d'encaissement vivent dans le journal des versements.
                datePaiement = nil
            default:
                datePaiement = nil
                paiementsPartiels = []
            }
            statusRawValue = newValue.rawValue
        }
    }

    /// Date rattachant le CA au bon mois : la date de paiement si renseignée,
    /// sinon la date de création (rétro-compatibilité avec les factures payées
    /// avant l'ajout du champ).
    var revenueDate: Date { datePaiement ?? dateCreation }

    /// Somme brute des versements partiels saisis (devise du document).
    var montantPaye: Decimal { paiementsPartiels.reduce(Decimal.zero) { $0 + $1.montant } }

    /// Versements datés effectivement comptés, plafonnés **cumulativement** à
    /// [0, TTC] dans l'ordre chronologique : un trop-perçu ne gonfle pas le CA et
    /// un versement nul/négatif est ignoré. Chaque versement conserve sa date.
    /// Source unique de l'encaissement (montant + ventilation mensuelle).
    private var datedCashContributions: [(date: Date, amount: Decimal)] {
        var remaining = totalTTC
        var result: [(date: Date, amount: Decimal)] = []
        for payment in paiementsPartiels.sorted(by: { $0.date < $1.date }) {
            guard remaining > 0 else { break }
            guard payment.montant > 0 else { continue }
            let amount = min(payment.montant, remaining)
            remaining -= amount
            result.append((date: payment.date, amount: amount))
        }
        return result
    }

    /// Montant réellement encaissé pour le CA : le total pour une facture payée
    /// en une fois, sinon la somme (plafonnée à TTC) des versements enregistrés.
    var montantEncaisse: Decimal {
        switch status {
        case .payee where paiementsPartiels.isEmpty:
            return totalTTC
        case .payee, .partiel:
            return datedCashContributions.reduce(Decimal.zero) { $0 + $1.amount }
        default:
            return 0
        }
    }

    /// Solde restant dû. Complémentaire de `montantEncaisse` (borné à [0, TTC]),
    /// donc toujours dans [0, TTC] : encaissé + restant == TTC.
    var resteAPayer: Decimal { totalTTC - montantEncaisse }

    /// Montant encore attendu pour le « Montant en attente » du tableau de bord :
    /// le total pour une facture envoyée, le solde restant pour une partielle.
    private var montantEnAttente: Decimal {
        switch status {
        case .envoyee: return totalTTC
        case .partiel: return resteAPayer
        default: return 0
        }
    }

    /// Encaissements datés convertis en devise comptable, pour ventiler le CA par
    /// mois : une facture soldée par versements (ou partielle) compte chaque
    /// versement à sa propre date ; une facture payée en une fois compte son total
    /// à sa date de paiement. `amount` vaut `nil` quand la conversion manque.
    func accountingCashEvents(referenceCurrency: CurrencyType) -> [(date: Date, amount: Decimal?)] {
        switch status {
        case .payee where paiementsPartiels.isEmpty:
            return [(revenueDate, convertedToAccounting(totalTTC, referenceCurrency: referenceCurrency))]
        case .payee, .partiel:
            return datedCashContributions.map {
                (date: $0.date, amount: convertedToAccounting($0.amount, referenceCurrency: referenceCurrency))
            }
        default:
            return []
        }
    }

    var currency: CurrencyType {
        get { decodedCurrency }
        set {
            let previousCurrency = decodedCurrency
            currencyRawValue = newValue.rawValue
            paymentSnapshot = nil
            normalizePaymentConfiguration()
            if previousCurrency != newValue {
                clearAccountingConversion()
            }
        }
    }

    var accountingCurrency: CurrencyType? {
        get {
            guard let raw = accountingCurrencyRawValue else { return nil }
            return CurrencyType(rawValue: raw)
        }
        set { accountingCurrencyRawValue = newValue?.rawValue }
    }

    var paymentMode: PaymentMode {
        get {
            let mode = decodedPaymentMode
            return mode == .crypto && !decodedCurrency.isCrypto ? .aucun : mode
        }
        set {
            paymentModeRawValue = newValue.rawValue
            paymentSnapshot = nil
            normalizePaymentConfiguration()
        }
    }

    var blockchain: Blockchain? {
        get {
            guard let chain = decodedBlockchain else { return nil }
            return Blockchain.compatibleBlockchains(for: decodedCurrency).contains(chain) ? chain : nil
        }
        set {
            blockchainRawValue = newValue?.rawValue
            paymentSnapshot = nil
            normalizePaymentConfiguration()
        }
    }

    private var decodedCurrency: CurrencyType {
        CurrencyType(rawValue: currencyRawValue) ?? .eur
    }

    private var decodedPaymentMode: PaymentMode {
        PaymentMode(rawValue: paymentModeRawValue) ?? .aucun
    }

    private var decodedBlockchain: Blockchain? {
        guard let raw = blockchainRawValue else { return nil }
        return Blockchain(rawValue: raw)
    }

    func normalizePaymentConfiguration(
        availableWallets wallets: [WalletEntry] = [],
        availableBankAccounts bankAccounts: [BankAccountEntry] = []
    ) {
        if CurrencyType(rawValue: currencyRawValue) == nil {
            currencyRawValue = CurrencyType.eur.rawValue
        }
        if PaymentMode(rawValue: paymentModeRawValue) == nil {
            paymentModeRawValue = PaymentMode.aucun.rawValue
        }

        let currency = decodedCurrency
        if !currency.isCrypto {
            blockchainRawValue = nil
            selectedWalletId = nil
            if decodedPaymentMode == .crypto {
                paymentModeRawValue = PaymentMode.aucun.rawValue
            }
            normalizeBankTransferSelection(availableBankAccounts: bankAccounts)
            return
        }

        let compatibleChains = Blockchain.compatibleBlockchains(for: currency)
        guard !compatibleChains.isEmpty else {
            blockchainRawValue = nil
            selectedWalletId = nil
            return
        }

        if let chain = decodedBlockchain {
            if !compatibleChains.contains(chain) {
                blockchainRawValue = nil
                selectedWalletId = nil
            }
        } else if blockchainRawValue != nil {
            blockchainRawValue = nil
            selectedWalletId = nil
        }

        guard decodedPaymentMode == .crypto else {
            selectedWalletId = nil
            normalizeBankTransferSelection(availableBankAccounts: bankAccounts)
            return
        }
        selectedBankAccountId = nil
        guard let chain = blockchain, !wallets.isEmpty else { return }

        let walletIds = Set(paymentWallets(from: wallets, for: chain).map(\.id))
        if let selectedWalletId, !walletIds.contains(selectedWalletId) {
            self.selectedWalletId = nil
        }
    }

    private func normalizeBankTransferSelection(availableBankAccounts bankAccounts: [BankAccountEntry]) {
        guard decodedPaymentMode == .virement else {
            selectedBankAccountId = nil
            return
        }

        guard !bankAccounts.isEmpty else { return }

        let accountIds = Set(paymentBankAccounts(from: bankAccounts).map(\.id))
        if let selectedBankAccountId, !accountIds.contains(selectedBankAccountId) {
            self.selectedBankAccountId = nil
        }
    }

    func paymentAddress(for wallet: WalletEntry) -> String {
        wallet.address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func paymentWallets(from wallets: [WalletEntry], for chain: Blockchain? = nil) -> [WalletEntry] {
        guard let chain = chain ?? blockchain else { return [] }
        return wallets.filter {
            $0.blockchain == chain && !paymentAddress(for: $0).isEmpty
        }
    }

    func selectedPaymentWallet(from wallets: [WalletEntry]) -> WalletEntry? {
        guard paymentMode == .crypto else { return nil }
        let walletsForChain = paymentWallets(from: wallets)
        return walletsForChain.first { $0.id == selectedWalletId } ?? walletsForChain.first
    }

    func selectedPaymentWalletAddress(from wallets: [WalletEntry]) -> String? {
        guard let wallet = selectedPaymentWallet(from: wallets) else { return nil }
        return paymentAddress(for: wallet)
    }

    func paymentBankAccounts(from accounts: [BankAccountEntry]) -> [BankAccountEntry] {
        guard paymentMode == .virement else { return [] }
        return accounts.filter(\.canReceiveBankTransfer)
    }

    func selectedPaymentBankAccount(from accounts: [BankAccountEntry]) -> BankAccountEntry? {
        guard paymentMode == .virement else { return nil }
        let accountsForTransfer = paymentBankAccounts(from: accounts)
        return accountsForTransfer.first { $0.id == selectedBankAccountId } ?? accountsForTransfer.first
    }

    var isSolanaPayEligible: Bool {
        paymentMode == .crypto && blockchain == .solana && currency.supportsSolanaPay
    }

    var shouldRenderPaymentRequest: Bool {
        type == .facture && status != .payee && status != .annulee
    }

    var isOverdue: Bool {
        guard type == .facture, status == .envoyee else { return false }
        let calendar = Calendar.current
        return calendar.startOfDay(for: dateEcheance) < calendar.startOfDay(for: Date())
    }

    var trustedPaymentSnapshot: DocumentPaymentSnapshot? {
        guard let paymentSnapshot, paymentSnapshot.isTrustedForExport else { return nil }
        return paymentSnapshot
    }

    func solanaPayWalletAddress(from wallets: [WalletEntry]) -> String? {
        guard shouldRenderPaymentRequest, isSolanaPayEligible, totalTTC > 0 else { return nil }
        if let paymentSnapshot = trustedPaymentSnapshot,
           paymentSnapshot.paymentMode == .crypto,
           paymentSnapshot.blockchain == .solana {
            let snapshotAddress = paymentSnapshot.walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            return snapshotAddress.isEmpty ? nil : snapshotAddress
        }
        return selectedPaymentWalletAddress(from: wallets)
    }

    @discardableResult
    func freezePaymentSnapshot(from company: CompanyInfo, at date: Date = Date()) -> Bool {
        switch paymentMode {
        case .aucun:
            if paymentSnapshot == nil { return false }
            paymentSnapshot = nil
            return true

        case .crypto:
            guard let address = selectedPaymentWalletAddress(from: company.wallets) else {
                if paymentSnapshot == nil { return false }
                paymentSnapshot = nil
                return true
            }
            let snapshot = DocumentPaymentSnapshot(
                paymentModeRawValue: PaymentMode.crypto.rawValue,
                blockchainRawValue: blockchain?.rawValue,
                walletAddress: address,
                createdAt: date
            )
            guard paymentSnapshot != snapshot else { return false }
            paymentSnapshot = snapshot
            return true

        case .virement:
            guard let account = selectedPaymentBankAccount(from: company.bankAccounts) else {
                if paymentSnapshot == nil { return false }
                paymentSnapshot = nil
                return true
            }
            let snapshot = DocumentPaymentSnapshot(
                paymentModeRawValue: PaymentMode.virement.rawValue,
                bankName: account.trimmedBankName,
                iban: account.trimmedIBAN,
                bic: account.trimmedBIC,
                accountHolder: account.trimmedAccountHolder,
                createdAt: date
            )
            guard paymentSnapshot != snapshot else { return false }
            paymentSnapshot = snapshot
            return true
        }
    }

    // MARK: - Computed totaux

    var lignesTriees: [LineItem] {
        lignes.sorted { $0.ordre < $1.ordre }
    }

    var totalHT: Decimal {
        lignes.reduce(Decimal.zero) { $0 + $1.totalLigne }
    }

    var totalTVA: Decimal {
        lignes.reduce(Decimal.zero) { $0 + $1.montantTVA }
    }

    var totalTTC: Decimal {
        totalHT + totalTVA
    }

    /// Convertit un montant (devise du document) vers la devise comptable de
    /// référence : tel quel si même devise, sinon via le taux comptable saisi, ou
    /// `nil` si le taux manque. Source unique des montants du CA.
    private func convertedToAccounting(_ amount: Decimal, referenceCurrency: CurrencyType) -> Decimal? {
        if currency == referenceCurrency {
            return amount
        }

        guard accountingCurrency == referenceCurrency,
              let accountingExchangeRate,
              accountingExchangeRate > 0 else {
            return nil
        }
        return amount * accountingExchangeRate
    }

    func accountingTotal(referenceCurrency: CurrencyType) -> Decimal? {
        convertedToAccounting(totalTTC, referenceCurrency: referenceCurrency)
    }

    /// Part encaissée convertie en devise comptable (acompte pour les partielles).
    func accountingPaidTotal(referenceCurrency: CurrencyType) -> Decimal? {
        convertedToAccounting(montantEncaisse, referenceCurrency: referenceCurrency)
    }

    /// Solde en attente converti en devise comptable (reste à payer des partielles).
    func accountingOutstandingTotal(referenceCurrency: CurrencyType) -> Decimal? {
        convertedToAccounting(montantEnAttente, referenceCurrency: referenceCurrency)
    }

    func needsAccountingConversion(referenceCurrency: CurrencyType) -> Bool {
        currency != referenceCurrency
    }

    func setAccountingExchangeRate(_ rate: Decimal?, referenceCurrency: CurrencyType) {
        accountingCurrency = referenceCurrency
        guard let rate, rate > 0 else {
            accountingExchangeRate = nil
            accountingExchangeRateDate = nil
            return
        }
        accountingExchangeRate = rate
        accountingExchangeRateDate = Date()
    }

    func clearAccountingConversion() {
        accountingCurrencyRawValue = nil
        accountingExchangeRate = nil
        accountingExchangeRateDate = nil
    }

    /// Resume formate du total
    var totalFormatted: String {
        currency.formatAccounting(totalTTC, lang: .fr)
    }

    // MARK: - Init

    init(
        type: DocumentType = .facture,
        number: String = "",
        dateCreation: Date = Date(),
        dateEcheance: Date? = nil,
        currency: CurrencyType = .eur,
        blockchain: Blockchain? = nil
    ) {
        self.id = UUID()
        self.typeRawValue = type.rawValue
        self.number = number
        self.dateCreation = dateCreation
        self.dateEcheance = dateEcheance ?? Calendar.current.date(byAdding: .day, value: 30, to: dateCreation) ?? dateCreation
        self.statusRawValue = DocumentStatus.brouillon.rawValue
        self.currencyRawValue = currency.rawValue
        self.blockchainRawValue = blockchain?.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        normalizePaymentConfiguration()
    }

    // MARK: - Actions

    /// Ajoute une ligne au document
    func ajouterLigne(_ ligne: LineItem) {
        var newLigne = ligne
        newLigne.ordre = lignes.count
        lignes.append(newLigne)
        updatedAt = Date()
    }

    /// Supprime une ligne du document
    func supprimerLigne(_ ligne: LineItem) {
        lignes.removeAll { $0.id == ligne.id }
        // Reordonner
        for index in lignes.indices {
            lignes[index].ordre = index
        }
        updatedAt = Date()
    }

    /// Duplique ce document
    func dupliquer() -> Document {
        let copie = Document(
            type: type,
            number: "",
            dateCreation: Date(),
            currency: currency,
            blockchain: blockchain
        )
        copie.clientNom = clientNom
        copie.clientAdresse = clientAdresse
        copie.clientCodePostal = clientCodePostal
        copie.clientVille = clientVille
        copie.clientSiret = clientSiret
        copie.clientTva = clientTva
        copie.clientApe = clientApe
        copie.clientEmail = clientEmail
        copie.notes = notes
        copie.langueRawValue = langueRawValue
        copie.paymentModeRawValue = paymentModeRawValue
        copie.selectedWalletId = selectedWalletId
        copie.selectedBankAccountId = selectedBankAccountId
        copie.paymentSnapshot = nil
        copie.normalizePaymentConfiguration()

        for ligne in lignesTriees {
            let nouvelleLigne = LineItem(
                designation: ligne.designation,
                quantite: ligne.quantite,
                prixUnitaire: ligne.prixUnitaire,
                tauxTVA: ligne.tauxTVA,
                ordre: ligne.ordre
            )
            copie.lignes.append(nouvelleLigne)
        }

        return copie
    }

    /// Convertit un devis en facture
    func convertirEnFacture() -> Document {
        let facture = dupliquer()
        facture.type = .facture
        return facture
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, typeRawValue, number, dateCreation, dateEcheance, datePaiement, paiementsPartiels, statusRawValue
        case currencyRawValue, blockchainRawValue, paymentModeRawValue
        case accountingCurrencyRawValue, accountingExchangeRate, accountingExchangeRateDate
        case clientNom, clientAdresse, clientCodePostal, clientVille
        case clientSiret, clientTva, clientApe, clientEmail
        case lignes, transactionSignatures, attachments, sourceTimesheetId, timesheetAutoSyncSignature
        case createdAt, updatedAt, notes, selectedWalletId, selectedBankAccountId, langueRawValue
        case paymentSnapshot
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        typeRawValue = try container.decodeOrDefault(String.self, forKey: .typeRawValue, default: DocumentType.facture.rawValue)
        number = try container.decodeOrDefault(String.self, forKey: .number, default: "")
        dateCreation = try container.decodeOrDefault(Date.self, forKey: .dateCreation, default: Date())
        dateEcheance = try container.decodeOrDefault(
            Date.self,
            forKey: .dateEcheance,
            default: Calendar.current.date(byAdding: .day, value: 30, to: dateCreation) ?? dateCreation
        )
        statusRawValue = try container.decodeOrDefault(String.self, forKey: .statusRawValue, default: DocumentStatus.brouillon.rawValue)
        datePaiement = try container.decodeIfPresent(Date.self, forKey: .datePaiement)
        paiementsPartiels = try container.decodeOrDefault([PartialPayment].self, forKey: .paiementsPartiels, default: [])
        currencyRawValue = try container.decodeOrDefault(String.self, forKey: .currencyRawValue, default: CurrencyType.eur.rawValue)
        blockchainRawValue = try container.decodeIfPresent(String.self, forKey: .blockchainRawValue)
        paymentModeRawValue = try container.decodeOrDefault(String.self, forKey: .paymentModeRawValue, default: PaymentMode.aucun.rawValue)
        accountingCurrencyRawValue = try container.decodeIfPresent(String.self, forKey: .accountingCurrencyRawValue)
        accountingExchangeRate = try container.decodeIfPresent(Decimal.self, forKey: .accountingExchangeRate)
        accountingExchangeRateDate = try container.decodeIfPresent(Date.self, forKey: .accountingExchangeRateDate)
        clientNom = try container.decodeOrDefault(String.self, forKey: .clientNom, default: "")
        clientAdresse = try container.decodeOrDefault(String.self, forKey: .clientAdresse, default: "")
        clientCodePostal = try container.decodeOrDefault(String.self, forKey: .clientCodePostal, default: "")
        clientVille = try container.decodeOrDefault(String.self, forKey: .clientVille, default: "")
        clientSiret = try container.decodeOrDefault(String.self, forKey: .clientSiret, default: "")
        clientTva = try container.decodeOrDefault(String.self, forKey: .clientTva, default: "")
        clientApe = try container.decodeOrDefault(String.self, forKey: .clientApe, default: "")
        clientEmail = try container.decodeOrDefault(String.self, forKey: .clientEmail, default: "")
        lignes = try container.decodeOrDefault([LineItem].self, forKey: .lignes, default: [])
        transactionSignatures = try container.decodeOrDefault([TransactionSignature].self, forKey: .transactionSignatures, default: [])
        attachments = try container.decodeOrDefault([DocumentAttachment].self, forKey: .attachments, default: [])
        sourceTimesheetId = try? container.decode(UUID.self, forKey: .sourceTimesheetId)
        timesheetAutoSyncSignature = try? container.decode(String.self, forKey: .timesheetAutoSyncSignature)
        createdAt = try container.decodeOrDefault(Date.self, forKey: .createdAt, default: dateCreation)
        updatedAt = try container.decodeOrDefault(Date.self, forKey: .updatedAt, default: createdAt)
        notes = try container.decodeOrDefault(String.self, forKey: .notes, default: "")
        selectedWalletId = try? container.decode(UUID.self, forKey: .selectedWalletId)
        selectedBankAccountId = try? container.decode(UUID.self, forKey: .selectedBankAccountId)
        langueRawValue = try container.decodeOrDefault(String.self, forKey: .langueRawValue, default: AppLanguage.fr.rawValue)
        paymentSnapshot = try? container.decode(DocumentPaymentSnapshot.self, forKey: .paymentSnapshot)
        normalizePaymentConfiguration()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(typeRawValue, forKey: .typeRawValue)
        try container.encode(number, forKey: .number)
        try container.encode(dateCreation, forKey: .dateCreation)
        try container.encode(dateEcheance, forKey: .dateEcheance)
        try container.encode(statusRawValue, forKey: .statusRawValue)
        try container.encodeIfPresent(datePaiement, forKey: .datePaiement)
        try container.encode(paiementsPartiels, forKey: .paiementsPartiels)
        try container.encode(currencyRawValue, forKey: .currencyRawValue)
        try container.encodeIfPresent(blockchainRawValue, forKey: .blockchainRawValue)
        try container.encode(paymentModeRawValue, forKey: .paymentModeRawValue)
        try container.encodeIfPresent(accountingCurrencyRawValue, forKey: .accountingCurrencyRawValue)
        try container.encodeIfPresent(accountingExchangeRate, forKey: .accountingExchangeRate)
        try container.encodeIfPresent(accountingExchangeRateDate, forKey: .accountingExchangeRateDate)
        try container.encode(clientNom, forKey: .clientNom)
        try container.encode(clientAdresse, forKey: .clientAdresse)
        try container.encode(clientCodePostal, forKey: .clientCodePostal)
        try container.encode(clientVille, forKey: .clientVille)
        try container.encode(clientSiret, forKey: .clientSiret)
        try container.encode(clientTva, forKey: .clientTva)
        try container.encode(clientApe, forKey: .clientApe)
        try container.encode(clientEmail, forKey: .clientEmail)
        try container.encode(lignes, forKey: .lignes)
        try container.encode(transactionSignatures, forKey: .transactionSignatures)
        try container.encode(attachments, forKey: .attachments)
        try container.encodeIfPresent(sourceTimesheetId, forKey: .sourceTimesheetId)
        try container.encodeIfPresent(timesheetAutoSyncSignature, forKey: .timesheetAutoSyncSignature)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(notes, forKey: .notes)
        try container.encodeIfPresent(selectedWalletId, forKey: .selectedWalletId)
        try container.encodeIfPresent(selectedBankAccountId, forKey: .selectedBankAccountId)
        try container.encode(langueRawValue, forKey: .langueRawValue)
        try container.encodeIfPresent(paymentSnapshot, forKey: .paymentSnapshot)
    }
}
