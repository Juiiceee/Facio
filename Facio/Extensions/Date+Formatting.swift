import Foundation

extension Date {
    func formattedDate(for format: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format == .fr ? "dd/MM/yyyy" : "MM/dd/yyyy"
        formatter.locale = Locale(identifier: format == .fr ? "fr_FR" : "en_US")
        return formatter.string(from: self)
    }

    /// Formate en date française (ex: 02/03/2026)
    var frenchFormatted: String {
        formattedDate(for: .fr)
    }

    /// Formate en mois/année (ex: 2026_03)
    var yearMonthFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM"
        return formatter.string(from: self)
    }
}
