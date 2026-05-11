import Foundation

extension Decimal {
    func formattedDecimal(
        minFractionDigits: Int = 0,
        maxFractionDigits: Int = 2,
        for format: AppLanguage
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: format == .fr ? "fr_FR" : "en_US")
        formatter.minimumFractionDigits = minFractionDigits
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = format == .fr ? " " : ","
        formatter.decimalSeparator = format == .fr ? "," : "."
        return formatter.string(from: self as NSDecimalNumber) ?? (format == .fr ? "0,00" : "0.00")
    }

    func formatted2Decimals(for format: AppLanguage) -> String {
        formattedDecimal(minFractionDigits: 2, maxFractionDigits: 2, for: format)
    }

    func formattedNoDecimals(for format: AppLanguage) -> String {
        formattedDecimal(maxFractionDigits: 0, for: format)
    }

    /// Formate en nombre français (ex: 2 897,39)
    var formatted2Decimals: String {
        formatted2Decimals(for: .fr)
    }

    /// Formate sans décimales
    var formattedNoDecimals: String {
        formattedNoDecimals(for: .fr)
    }
}
