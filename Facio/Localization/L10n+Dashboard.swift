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
    // MARK: - Série mensuelle
    //
    // L'écran s'appelait « tableau de bord », son icône était un graphique, et
    // il n'y avait aucun graphique — alors que la donnée existait déjà : chaque
    // versement porte sa date.
    static func revenueCollected(_ l: AppLanguage) -> String { l == .fr ? "Encaissé" : "Collected" }
    static func revenueSeriesTitle(_ l: AppLanguage, count: Int) -> String {
        l == .fr ? "Encaissé · \(count) mois" : "Collected · \(count) months"
    }
    static func revenueSeriesAccessibility(_ l: AppLanguage, count: Int) -> String {
        l == .fr ? "Encaissements des \(count) derniers mois" : "Collections over the last \(count) months"
    }

    /// La base comptable était invisible : les tuiles de CA sont en ENCAISSÉ
    /// (versements reçus, datés au jour du paiement) tandis que « En attente »
    /// est en facturé — et rien ne disait dans quelle devise.
    static func basisCollected(_ l: AppLanguage, currency: String) -> String {
        l == .fr ? "Paiements reçus · \(currency)" : "Payments received · \(currency)"
    }
    static func basisOutstanding(_ l: AppLanguage, currency: String) -> String {
        l == .fr ? "Soldes restants · facturé · \(currency)" : "Remaining balances · invoiced · \(currency)"
    }

    static func vatCollected(_ l: AppLanguage, quarter: Int) -> String {
        l == .fr ? "TVA collectée · T\(quarter)" : "VAT collected · Q\(quarter)"
    }

    /// L'ancienneté en clair : la ligne montrait une date d'échéance brute, et
    /// l'utilisateur faisait le calcul de tête.
    static func overdueByDays(_ l: AppLanguage, days: Int) -> String {
        l == .fr ? "en retard de \(days) j" : "\(days) days overdue"
    }
}
