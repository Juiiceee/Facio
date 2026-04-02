import Foundation

// MARK: - Tableau de bord

extension L10n {

    static func dashboard(_ l: AppLanguage) -> String { l == .fr ? "Tableau de bord" : "Dashboard" }
    static func revenueThisMonth(_ l: AppLanguage) -> String { l == .fr ? "CA ce mois" : "Revenue this month" }
    static func revenueThisYear(_ l: AppLanguage) -> String { l == .fr ? "CA cette annee" : "Revenue this year" }
    static func pending(_ l: AppLanguage) -> String { l == .fr ? "En attente" : "Pending" }
    static func pendingInvoices(_ l: AppLanguage, count: Int) -> String { l == .fr ? "\(count) facture(s)" : "\(count) invoice(s)" }
    static func quotesInProgress(_ l: AppLanguage) -> String { l == .fr ? "Devis en cours" : "Quotes in progress" }
    static func latestInvoices(_ l: AppLanguage) -> String { l == .fr ? "Dernieres factures" : "Latest invoices" }
    static func noInvoicesYet(_ l: AppLanguage) -> String { l == .fr ? "Aucune facture pour le moment." : "No invoices yet." }
    static func latestQuotes(_ l: AppLanguage) -> String { l == .fr ? "Derniers devis" : "Latest quotes" }
    static func noQuotesYet(_ l: AppLanguage) -> String { l == .fr ? "Aucun devis pour le moment." : "No quotes yet." }
}
