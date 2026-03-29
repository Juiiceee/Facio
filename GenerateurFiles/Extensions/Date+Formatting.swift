import Foundation

extension Date {
    /// Formate en date française (ex: 02/03/2026)
    var frenchFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }

    /// Formate en mois/année (ex: 2026_03)
    var yearMonthFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM"
        return formatter.string(from: self)
    }
}
