import Foundation

struct AccountingRevenueSummary: Equatable {
    var total: Decimal = 0
    var convertedCount: Int = 0
    var missingConversionCount: Int = 0
}

struct AccountingRevenueService {
    static func summary(
        for documents: [Document],
        referenceCurrency: CurrencyType
    ) -> AccountingRevenueSummary {
        documents.reduce(AccountingRevenueSummary()) { partial, document in
            var summary = partial
            if let converted = document.accountingTotal(referenceCurrency: referenceCurrency) {
                summary.total += converted
                summary.convertedCount += 1
            } else if document.needsAccountingConversion(referenceCurrency: referenceCurrency) {
                summary.missingConversionCount += 1
            }
            return summary
        }
    }
}
