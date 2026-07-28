import Foundation

/// Un versement partiel encaissé sur une facture (statut « Partiel ») : un
/// montant reçu à une date donnée. La somme des versements donne le montant
/// encaissé ; le reste à payer en découle. Chaque versement porte sa propre date
/// pour rattacher le CA au bon mois (encaissement).
struct PartialPayment: Codable, Identifiable, Hashable {
    var id: UUID
    var montant: Decimal
    var date: Date

    init(id: UUID = UUID(), montant: Decimal = 0, date: Date = Date()) {
        self.id = id
        self.montant = montant
        self.date = date
    }
}
