import Foundation

struct AccountingRevenueSummary: Equatable {
    var total: Decimal = 0
    var convertedCount: Int = 0
    var missingConversionCount: Int = 0
}

struct AccountingRevenueService {
    /// Agrège un montant comptable par document. `amount` choisit la part sommée
    /// (total complet par défaut, ou part encaissée / solde restant pour le suivi
    /// des paiements partiels) ; il renvoie `nil` quand la conversion manque.
    static func summary(
        for documents: [Document],
        referenceCurrency: CurrencyType,
        amount: (Document, CurrencyType) -> Decimal? = { document, ref in
            document.accountingTotal(referenceCurrency: ref)
        }
    ) -> AccountingRevenueSummary {
        documents.reduce(AccountingRevenueSummary()) { partial, document in
            var summary = partial
            if let converted = amount(document, referenceCurrency) {
                summary.total += converted
                summary.convertedCount += 1
            } else if document.needsAccountingConversion(referenceCurrency: referenceCurrency) {
                summary.missingConversionCount += 1
            }
            return summary
        }
    }
}
