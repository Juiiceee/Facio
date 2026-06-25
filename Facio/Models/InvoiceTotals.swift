import Foundation

/// Totaux d'une facture **arrondis par ligne puis sommés**, à la précision
/// monétaire (2 décimales). C'est la règle de calcul EN 16931 (BR-CO) et la base
/// de la facture électronique : chaque montant de ligne affiché est arrondi, et
/// les totaux sont la somme de ces montants arrondis (donc le total affiché égale
/// toujours la somme des lignes affichées).
///
/// Source **unique** partagée par le PDF (`PDFGenerator`) et le XML Factur-X
/// (`FacturXXMLBuilder`) pour qu'ils affichent exactement les mêmes montants.
/// `Document.totalHT/totalTVA/totalTTC` (somme non arrondie) restent utilisés
/// par le dashboard, la comptabilité et les paiements et ne sont pas modifiés.
struct InvoiceTotals {
    /// Ventilation par taux de TVA (un groupe par taux, dans l'ordre d'apparition).
    struct RateGroup {
        let rate: Decimal
        /// Base HT du groupe = Σ des montants de ligne arrondis de ce taux.
        let basis: Decimal
        /// Montant de TVA du groupe = arrondi(base × taux / 100).
        let calculated: Decimal
    }

    let groups: [RateGroup]

    var totalHT: Decimal { groups.reduce(Decimal.zero) { $0 + $1.basis } }
    var totalTVA: Decimal { groups.reduce(Decimal.zero) { $0 + $1.calculated } }
    var totalTTC: Decimal { totalHT + totalTVA }

    static func canonical(for lines: [LineItem]) -> InvoiceTotals {
        var order: [Decimal] = []
        var basisByRate: [Decimal: Decimal] = [:]
        for line in lines {
            let rate = line.tauxTVA
            if basisByRate[rate] == nil { order.append(rate) }
            basisByRate[rate, default: 0] += rounded2(line.totalLigne)
        }
        let groups = order.map { rate -> RateGroup in
            let basis = basisByRate[rate] ?? 0
            return RateGroup(rate: rate, basis: basis, calculated: rounded2(basis * rate / 100))
        }
        return InvoiceTotals(groups: groups)
    }

    /// Arrondi commercial à 2 décimales (jamais via Double).
    static func rounded2(_ value: Decimal) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 2, .plain)
        return result
    }
}
