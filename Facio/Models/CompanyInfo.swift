import AppKit
import Foundation
import Observation

// MARK: - Prestation favorite (designation pre-enregistree)

struct DesignationPreset: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var designation: String = ""
    var prixUnitaire: Decimal = 0
    var tauxTVA: Decimal = 0

    init(designation: String = "", prixUnitaire: Decimal = 0, tauxTVA: Decimal = 0) {
        self.id = UUID()
        self.designation = designation
        self.prixUnitaire = prixUnitaire
        self.tauxTVA = tauxTVA
    }

    enum CodingKeys: String, CodingKey {
        case id, designation, prixUnitaire, tauxTVA
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        designation = container.decodeOrDefault(String.self, forKey: .designation, default: "")
        prixUnitaire = container.decodeOrDefault(Decimal.self, forKey: .prixUnitaire, default: 0)
        tauxTVA = container.decodeOrDefault(Decimal.self, forKey: .tauxTVA, default: 0)
    }
}

// MARK: - Entree Wallet

struct WalletEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var label: String = ""
    var blockchainRawValue: String = "Solana"
    var address: String = ""

    var blockchain: Blockchain {
        get { Blockchain(rawValue: blockchainRawValue) ?? .solana }
        set { blockchainRawValue = newValue.rawValue }
    }

    init(blockchain: Blockchain = .solana, address: String = "", label: String = "") {
        self.id = UUID()
        self.label = label
        self.blockchainRawValue = blockchain.rawValue
        self.address = address
    }

    enum CodingKeys: String, CodingKey {
        case id, label, blockchainRawValue, address
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        label = container.decodeOrDefault(String.self, forKey: .label, default: "")
        blockchainRawValue = container.decodeOrDefault(String.self, forKey: .blockchainRawValue, default: Blockchain.solana.rawValue)
        address = container.decodeOrDefault(String.self, forKey: .address, default: "")
    }
}

// MARK: - Entree compte bancaire

struct BankAccountEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var label: String = ""
    var bankName: String = ""
    var iban: String = ""
    var bic: String = ""
    var accountHolder: String = ""

    var trimmedLabel: String { label.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedBankName: String { bankName.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedIBAN: String { iban.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedBIC: String { bic.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedAccountHolder: String { accountHolder.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isEmpty: Bool {
        [
            trimmedLabel,
            trimmedBankName,
            trimmedIBAN,
            trimmedBIC,
            trimmedAccountHolder,
        ].allSatisfy(\.isEmpty)
    }

    var canReceiveBankTransfer: Bool {
        !trimmedIBAN.isEmpty
    }

    var displayName: String {
        if !trimmedLabel.isEmpty { return trimmedLabel }
        if !trimmedBankName.isEmpty { return trimmedBankName }
        if !trimmedAccountHolder.isEmpty { return trimmedAccountHolder }
        if !trimmedIBAN.isEmpty {
            return String(trimmedIBAN.suffix(min(8, trimmedIBAN.count)))
        }
        return ""
    }

    init(label: String = "", bankName: String = "", iban: String = "", bic: String = "", accountHolder: String = "") {
        self.id = UUID()
        self.label = label
        self.bankName = bankName
        self.iban = iban
        self.bic = bic
        self.accountHolder = accountHolder
    }

    enum CodingKeys: String, CodingKey {
        case id, label, bankName, iban, bic, accountHolder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        label = container.decodeOrDefault(String.self, forKey: .label, default: "")
        bankName = container.decodeOrDefault(String.self, forKey: .bankName, default: "")
        iban = container.decodeOrDefault(String.self, forKey: .iban, default: "")
        bic = container.decodeOrDefault(String.self, forKey: .bic, default: "")
        accountHolder = container.decodeOrDefault(String.self, forKey: .accountHolder, default: "")
    }
}

// MARK: - Infos Entreprise (singleton)

@Observable
final class CompanyInfo: Identifiable, Codable {
    var id: UUID = UUID()
    var nom: String = ""
    var adresse: String = ""
    var codePostal: String = ""
    var ville: String = ""
    var siret: String = ""
    var telephone: String = ""
    var email: String = ""
    var logoData: Data?

    // Paiement fiat
    var nomBanque: String = ""
    var iban: String = ""
    var bic: String = ""
    var titulaireCompte: String = ""

    // Comptes bancaires (modulaire)
    var bankAccounts: [BankAccountEntry] = []

    // Wallets crypto (modulaire)
    var wallets: [WalletEntry] = []

    // Prestations favorites
    var prestations: [DesignationPreset] = []

    // Valeurs par defaut
    var tauxTVAParDefaut: Decimal = 0
    var delaiPaiementJours: Int = 30
    var deviseParDefautRawValue: String = "USDC"
    var deviseComptableRawValue: String = "EUR"
    var blockchainParDefautRawValue: String? = "Solana"
    var updatedAt: Date = Date()

    // Langue & Format
    var langueParDefautRawValue: String = "fr"
    var formatDateRawValue: String = "fr"
    var formatNombreRawValue: String = "fr"

    // Personnalisation visuelle
    var couleurAccentHex: String?

    /// Couleur d'accent resolue (defaut: vert olive #6B8E3A)
    var accentNSColor: NSColor {
        guard let hex = couleurAccentHex else {
            return NSColor(red: 0.42, green: 0.56, blue: 0.23, alpha: 1.0)
        }
        return NSColor.fromHex(hex) ?? NSColor(red: 0.42, green: 0.56, blue: 0.23, alpha: 1.0)
    }

    var langueParDefaut: AppLanguage {
        get { AppLanguage(rawValue: langueParDefautRawValue) ?? .fr }
        set { langueParDefautRawValue = newValue.rawValue }
    }

    var formatDate: AppLanguage {
        get { AppLanguage(rawValue: formatDateRawValue) ?? .fr }
        set { formatDateRawValue = newValue.rawValue }
    }

    var formatNombre: AppLanguage {
        get { AppLanguage(rawValue: formatNombreRawValue) ?? .fr }
        set { formatNombreRawValue = newValue.rawValue }
    }

    var deviseParDefaut: CurrencyType {
        get { CurrencyType(rawValue: deviseParDefautRawValue) ?? .eur }
        set { deviseParDefautRawValue = newValue.rawValue }
    }

    var deviseComptable: CurrencyType {
        get { CurrencyType(rawValue: deviseComptableRawValue) ?? .eur }
        set { deviseComptableRawValue = newValue.rawValue }
    }

    var blockchainParDefaut: Blockchain? {
        get {
            guard let raw = blockchainParDefautRawValue else { return nil }
            return Blockchain(rawValue: raw)
        }
        set { blockchainParDefautRawValue = newValue?.rawValue }
    }

    init() {
        self.id = UUID()
    }

    func syncLegacyBankFieldsFromPrimaryAccount() {
        guard let primary = bankAccounts.first else {
            nomBanque = ""
            iban = ""
            bic = ""
            titulaireCompte = ""
            return
        }

        nomBanque = primary.bankName
        iban = primary.iban
        bic = primary.bic
        titulaireCompte = primary.accountHolder
    }

    func normalizeBankAccountsFromLegacyFields() {
        let legacyValues = [
            nomBanque,
            iban,
            bic,
            titulaireCompte,
        ].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if bankAccounts.isEmpty && legacyValues.contains(where: { !$0.isEmpty }) {
            bankAccounts = [
                BankAccountEntry(
                    label: nomBanque,
                    bankName: nomBanque,
                    iban: iban,
                    bic: bic,
                    accountHolder: titulaireCompte
                )
            ]
        }

        if !bankAccounts.isEmpty {
            syncLegacyBankFieldsFromPrimaryAccount()
        }
    }

    /// Recupere le wallet pour un reseau donne
    func wallet(pour blockchain: Blockchain) -> WalletEntry? {
        wallets.first { $0.blockchain == blockchain }
    }

    /// Ajoute ou met a jour un wallet
    func setWallet(blockchain: Blockchain, address: String) {
        if let index = wallets.firstIndex(where: { $0.blockchain == blockchain }) {
            wallets[index].address = address
        } else {
            let entry = WalletEntry(blockchain: blockchain, address: address)
            wallets.append(entry)
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, nom, adresse, codePostal, ville, siret, telephone, email, logoData
        case nomBanque, iban, bic, titulaireCompte, bankAccounts, wallets, prestations
        case tauxTVAParDefaut, delaiPaiementJours, deviseParDefautRawValue, deviseComptableRawValue, blockchainParDefautRawValue
        case updatedAt
        case langueParDefautRawValue, formatDateRawValue, formatNombreRawValue
        case couleurAccentHex
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        nom = container.decodeOrDefault(String.self, forKey: .nom, default: "")
        adresse = container.decodeOrDefault(String.self, forKey: .adresse, default: "")
        codePostal = container.decodeOrDefault(String.self, forKey: .codePostal, default: "")
        ville = container.decodeOrDefault(String.self, forKey: .ville, default: "")
        siret = container.decodeOrDefault(String.self, forKey: .siret, default: "")
        telephone = container.decodeOrDefault(String.self, forKey: .telephone, default: "")
        email = container.decodeOrDefault(String.self, forKey: .email, default: "")
        logoData = try container.decodeIfPresent(Data.self, forKey: .logoData)
        nomBanque = container.decodeOrDefault(String.self, forKey: .nomBanque, default: "")
        iban = container.decodeOrDefault(String.self, forKey: .iban, default: "")
        bic = container.decodeOrDefault(String.self, forKey: .bic, default: "")
        titulaireCompte = container.decodeOrDefault(String.self, forKey: .titulaireCompte, default: "")
        bankAccounts = container.decodeOrDefault([BankAccountEntry].self, forKey: .bankAccounts, default: [])
        normalizeBankAccountsFromLegacyFields()
        wallets = container.decodeOrDefault([WalletEntry].self, forKey: .wallets, default: [])
        prestations = container.decodeOrDefault([DesignationPreset].self, forKey: .prestations, default: [])
        tauxTVAParDefaut = container.decodeOrDefault(Decimal.self, forKey: .tauxTVAParDefaut, default: 0)
        delaiPaiementJours = container.decodeOrDefault(Int.self, forKey: .delaiPaiementJours, default: 30)
        deviseParDefautRawValue = container.decodeOrDefault(String.self, forKey: .deviseParDefautRawValue, default: CurrencyType.usdc.rawValue)
        deviseComptableRawValue = container.decodeOrDefault(String.self, forKey: .deviseComptableRawValue, default: CurrencyType.eur.rawValue)
        let defaultBlockchain = container
            .decodeOrDefault(String.self, forKey: .blockchainParDefautRawValue, default: Blockchain.solana.rawValue)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        blockchainParDefautRawValue = defaultBlockchain.isEmpty ? Blockchain.solana.rawValue : defaultBlockchain
        updatedAt = container.decodeOrDefault(Date.self, forKey: .updatedAt, default: Date())
        langueParDefautRawValue = container.decodeOrDefault(String.self, forKey: .langueParDefautRawValue, default: AppLanguage.fr.rawValue)
        formatDateRawValue = container.decodeOrDefault(String.self, forKey: .formatDateRawValue, default: AppLanguage.fr.rawValue)
        formatNombreRawValue = container.decodeOrDefault(String.self, forKey: .formatNombreRawValue, default: AppLanguage.fr.rawValue)
        couleurAccentHex = try? container.decode(String.self, forKey: .couleurAccentHex)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nom, forKey: .nom)
        try container.encode(adresse, forKey: .adresse)
        try container.encode(codePostal, forKey: .codePostal)
        try container.encode(ville, forKey: .ville)
        try container.encode(siret, forKey: .siret)
        try container.encode(telephone, forKey: .telephone)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(logoData, forKey: .logoData)
        let primaryBankAccount = bankAccounts.first
        try container.encode(primaryBankAccount?.bankName ?? nomBanque, forKey: .nomBanque)
        try container.encode(primaryBankAccount?.iban ?? iban, forKey: .iban)
        try container.encode(primaryBankAccount?.bic ?? bic, forKey: .bic)
        try container.encode(primaryBankAccount?.accountHolder ?? titulaireCompte, forKey: .titulaireCompte)
        try container.encode(bankAccounts, forKey: .bankAccounts)
        try container.encode(wallets, forKey: .wallets)
        try container.encode(prestations, forKey: .prestations)
        try container.encode(tauxTVAParDefaut, forKey: .tauxTVAParDefaut)
        try container.encode(delaiPaiementJours, forKey: .delaiPaiementJours)
        try container.encode(deviseParDefautRawValue, forKey: .deviseParDefautRawValue)
        try container.encode(deviseComptableRawValue, forKey: .deviseComptableRawValue)
        try container.encodeIfPresent(blockchainParDefautRawValue, forKey: .blockchainParDefautRawValue)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(langueParDefautRawValue, forKey: .langueParDefautRawValue)
        try container.encode(formatDateRawValue, forKey: .formatDateRawValue)
        try container.encode(formatNombreRawValue, forKey: .formatNombreRawValue)
        try container.encodeIfPresent(couleurAccentHex, forKey: .couleurAccentHex)
    }
}
