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
}
