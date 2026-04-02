import Foundation
import Observation

@Observable
final class Document: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var typeRawValue: String = "Facture"
    var number: String = ""
    var dateCreation: Date = Date()
    var dateEcheance: Date = Date()
    var statusRawValue: String = "Brouillon"
    var currencyRawValue: String = "EUR"
    var blockchainRawValue: String?
    var paymentModeRawValue: String = "Aucun"

    // Client embarque (copie figee)
    var clientNom: String = ""
    var clientAdresse: String = ""
    var clientCodePostal: String = ""
    var clientVille: String = ""

    // Relations
    var lignes: [LineItem] = []
    var transactionSignatures: [TransactionSignature] = []

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
        set { statusRawValue = newValue.rawValue }
    }

    var currency: CurrencyType {
        get { CurrencyType(rawValue: currencyRawValue) ?? .eur }
        set { currencyRawValue = newValue.rawValue }
    }

    var paymentMode: PaymentMode {
        get { PaymentMode(rawValue: paymentModeRawValue) ?? .aucun }
        set { paymentModeRawValue = newValue.rawValue }
    }

    var blockchain: Blockchain? {
        get {
            guard let raw = blockchainRawValue else { return nil }
            return Blockchain(rawValue: raw)
        }
        set { blockchainRawValue = newValue?.rawValue }
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

    /// Resume formate du total
    var totalFormatted: String {
        currency.format(totalTTC)
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
        copie.notes = notes
        copie.langueRawValue = langueRawValue

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
        case id, typeRawValue, number, dateCreation, dateEcheance, statusRawValue
        case currencyRawValue, blockchainRawValue, paymentModeRawValue
        case clientNom, clientAdresse, clientCodePostal, clientVille
        case lignes, transactionSignatures
        case createdAt, updatedAt, notes, selectedWalletId, langueRawValue
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        typeRawValue = try container.decode(String.self, forKey: .typeRawValue)
        number = try container.decode(String.self, forKey: .number)
        dateCreation = try container.decode(Date.self, forKey: .dateCreation)
        dateEcheance = try container.decode(Date.self, forKey: .dateEcheance)
        statusRawValue = try container.decode(String.self, forKey: .statusRawValue)
        currencyRawValue = try container.decode(String.self, forKey: .currencyRawValue)
        blockchainRawValue = try container.decodeIfPresent(String.self, forKey: .blockchainRawValue)
        paymentModeRawValue = (try? container.decode(String.self, forKey: .paymentModeRawValue)) ?? "Aucun"
        clientNom = try container.decode(String.self, forKey: .clientNom)
        clientAdresse = try container.decode(String.self, forKey: .clientAdresse)
        clientCodePostal = try container.decode(String.self, forKey: .clientCodePostal)
        clientVille = try container.decode(String.self, forKey: .clientVille)
        lignes = try container.decode([LineItem].self, forKey: .lignes)
        transactionSignatures = try container.decode([TransactionSignature].self, forKey: .transactionSignatures)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        notes = try container.decode(String.self, forKey: .notes)
        selectedWalletId = try? container.decode(UUID.self, forKey: .selectedWalletId)
        langueRawValue = (try? container.decode(String.self, forKey: .langueRawValue)) ?? "fr"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(typeRawValue, forKey: .typeRawValue)
        try container.encode(number, forKey: .number)
        try container.encode(dateCreation, forKey: .dateCreation)
        try container.encode(dateEcheance, forKey: .dateEcheance)
        try container.encode(statusRawValue, forKey: .statusRawValue)
        try container.encode(currencyRawValue, forKey: .currencyRawValue)
        try container.encodeIfPresent(blockchainRawValue, forKey: .blockchainRawValue)
        try container.encode(paymentModeRawValue, forKey: .paymentModeRawValue)
        try container.encode(clientNom, forKey: .clientNom)
        try container.encode(clientAdresse, forKey: .clientAdresse)
        try container.encode(clientCodePostal, forKey: .clientCodePostal)
        try container.encode(clientVille, forKey: .clientVille)
        try container.encode(lignes, forKey: .lignes)
        try container.encode(transactionSignatures, forKey: .transactionSignatures)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(notes, forKey: .notes)
        try container.encodeIfPresent(selectedWalletId, forKey: .selectedWalletId)
        try container.encode(langueRawValue, forKey: .langueRawValue)
    }
}
