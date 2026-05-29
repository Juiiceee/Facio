import Foundation

// MARK: - Tableau de bord

extension L10n {

    static func dashboard(_ l: AppLanguage) -> String { l == .fr ? "Tableau de bord" : "Dashboard" }
    static func dashboardSubtitle(_ l: AppLanguage) -> String {
        l == .fr ? "Priorités, revenus et activité récente." : "Priorities, revenue, and recent activity."
    }
    static func revenueThisMonth(_ l: AppLanguage) -> String { l == .fr ? "CA ce mois" : "Revenue this month" }
    static func revenueThisYear(_ l: AppLanguage) -> String { l == .fr ? "CA cette année" : "Revenue this year" }
    static func pending(_ l: AppLanguage) -> String { l == .fr ? "En attente" : "Pending" }
    static func pendingInvoices(_ l: AppLanguage, count: Int) -> String {
        l == .fr ? "\(count) facture\(count > 1 ? "s" : "")" : "\(count) invoice\(count == 1 ? "" : "s")"
    }
    static func missingConversions(_ l: AppLanguage, count: Int) -> String {
        l == .fr ? "\(count) conversion\(count > 1 ? "s" : "") manquante\(count > 1 ? "s" : "")" : "\(count) missing conversion\(count == 1 ? "" : "s")"
    }
    static func quotesInProgress(_ l: AppLanguage) -> String { l == .fr ? "Devis en cours" : "Quotes in progress" }
    static func latestInvoices(_ l: AppLanguage) -> String { l == .fr ? "Dernières factures" : "Latest invoices" }
    static func noInvoicesYet(_ l: AppLanguage) -> String { l == .fr ? "Aucune facture pour le moment." : "No invoices yet." }
    static func latestQuotes(_ l: AppLanguage) -> String { l == .fr ? "Derniers devis" : "Latest quotes" }
    static func noQuotesYet(_ l: AppLanguage) -> String { l == .fr ? "Aucun devis pour le moment." : "No quotes yet." }
    static func moreItems(_ l: AppLanguage, count: Int) -> String {
        l == .fr ? "+ \(count) autre\(count > 1 ? "s" : "")" : "+ \(count) more"
    }
}
