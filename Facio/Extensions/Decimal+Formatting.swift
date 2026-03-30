import Foundation

extension Decimal {
    /// Formate en nombre français (ex: 2 897,39)
    var formatted2Decimals: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        return formatter.string(from: self as NSDecimalNumber) ?? "0,00"
    }

    /// Formate sans décimales
    var formattedNoDecimals: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = " "
        return formatter.string(from: self as NSDecimalNumber) ?? "0"
    }
}
