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

    // Wallets crypto (modulaire)
    var wallets: [WalletEntry] = []

    // Prestations favorites
    var prestations: [DesignationPreset] = []

    // Valeurs par defaut
    var tauxTVAParDefaut: Decimal = 0
    var delaiPaiementJours: Int = 30
    var deviseParDefautRawValue: String = "USDC"
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
        case nomBanque, iban, bic, titulaireCompte, wallets, prestations
        case tauxTVAParDefaut, delaiPaiementJours, deviseParDefautRawValue, blockchainParDefautRawValue
        case updatedAt
        case langueParDefautRawValue, formatDateRawValue, formatNombreRawValue
        case couleurAccentHex
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        nom = try container.decode(String.self, forKey: .nom)
        adresse = try container.decode(String.self, forKey: .adresse)
        codePostal = try container.decode(String.self, forKey: .codePostal)
        ville = try container.decode(String.self, forKey: .ville)
        siret = try container.decode(String.self, forKey: .siret)
        telephone = try container.decode(String.self, forKey: .telephone)
        email = try container.decode(String.self, forKey: .email)
        logoData = try container.decodeIfPresent(Data.self, forKey: .logoData)
        nomBanque = (try? container.decode(String.self, forKey: .nomBanque)) ?? ""
        iban = try container.decode(String.self, forKey: .iban)
        bic = try container.decode(String.self, forKey: .bic)
        titulaireCompte = try container.decode(String.self, forKey: .titulaireCompte)
        wallets = try container.decode([WalletEntry].self, forKey: .wallets)
        prestations = (try? container.decode([DesignationPreset].self, forKey: .prestations)) ?? []
        tauxTVAParDefaut = try container.decode(Decimal.self, forKey: .tauxTVAParDefaut)
        delaiPaiementJours = try container.decode(Int.self, forKey: .delaiPaiementJours)
        deviseParDefautRawValue = try container.decode(String.self, forKey: .deviseParDefautRawValue)
        blockchainParDefautRawValue = try container.decodeIfPresent(String.self, forKey: .blockchainParDefautRawValue)
        updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? Date()
        langueParDefautRawValue = (try? container.decode(String.self, forKey: .langueParDefautRawValue)) ?? "fr"
        formatDateRawValue = (try? container.decode(String.self, forKey: .formatDateRawValue)) ?? "fr"
        formatNombreRawValue = (try? container.decode(String.self, forKey: .formatNombreRawValue)) ?? "fr"
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
        try container.encode(nomBanque, forKey: .nomBanque)
        try container.encode(iban, forKey: .iban)
        try container.encode(bic, forKey: .bic)
        try container.encode(titulaireCompte, forKey: .titulaireCompte)
        try container.encode(wallets, forKey: .wallets)
        try container.encode(prestations, forKey: .prestations)
        try container.encode(tauxTVAParDefaut, forKey: .tauxTVAParDefaut)
        try container.encode(delaiPaiementJours, forKey: .delaiPaiementJours)
        try container.encode(deviseParDefautRawValue, forKey: .deviseParDefautRawValue)
        try container.encodeIfPresent(blockchainParDefautRawValue, forKey: .blockchainParDefautRawValue)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(langueParDefautRawValue, forKey: .langueParDefautRawValue)
        try container.encode(formatDateRawValue, forKey: .formatDateRawValue)
        try container.encode(formatNombreRawValue, forKey: .formatNombreRawValue)
        try container.encodeIfPresent(couleurAccentHex, forKey: .couleurAccentHex)
    }
}
