import Foundation

struct LineItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var designation: String = ""
    var quantite: Decimal = 0
    var prixUnitaire: Decimal = 0
    var tauxTVA: Decimal = 0
    var ordre: Int = 0

    // MARK: - Computed

    var totalLigne: Decimal {
        quantite * prixUnitaire
    }

    var montantTVA: Decimal {
        totalLigne * tauxTVA / 100
    }

    var totalTTC: Decimal {
        totalLigne + montantTVA
    }

    // MARK: - Init

    init(
        designation: String = "",
        quantite: Decimal = 0,
        prixUnitaire: Decimal = 0,
        tauxTVA: Decimal = 0,
        ordre: Int = 0
    ) {
        self.id = UUID()
        self.designation = designation
        self.quantite = quantite
        self.prixUnitaire = prixUnitaire
        self.tauxTVA = tauxTVA
        self.ordre = ordre
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, designation, quantite, prixUnitaire, tauxTVA, ordre
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        designation = try container.decodeOrDefault(String.self, forKey: .designation, default: "")
        quantite = try container.decodeOrDefault(Decimal.self, forKey: .quantite, default: 0)
        prixUnitaire = try container.decodeOrDefault(Decimal.self, forKey: .prixUnitaire, default: 0)
        tauxTVA = try container.decodeOrDefault(Decimal.self, forKey: .tauxTVA, default: 0)
        ordre = try container.decodeOrDefault(Int.self, forKey: .ordre, default: 0)
    }
}
