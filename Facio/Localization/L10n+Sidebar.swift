import Foundation

// MARK: - Navigation laterale (sidebar)

extension L10n {

    static func sidebarInvoices(_ l: AppLanguage) -> String { l == .fr ? "Factures" : "Invoices" }
    static func sidebarQuotes(_ l: AppLanguage) -> String { l == .fr ? "Devis" : "Quotes" }
    static func sidebarClients(_ l: AppLanguage) -> String { "Clients" }
    static func sidebarDashboard(_ l: AppLanguage) -> String { l == .fr ? "Tableau de bord" : "Dashboard" }
    static func sidebarSettings(_ l: AppLanguage) -> String { l == .fr ? "Paramètres" : "Settings" }

    // Cinq destinations — « Documents » et « Gestion » disparaissent : un client
    // n'est pas plus de la « gestion » qu'une facture n'est un « document », et
    // « Gestion » ne veut rien dire pour l'utilisateur.
    static func sidebarSales(_ l: AppLanguage) -> String { l == .fr ? "Ventes" : "Sales" }
    static func sidebarTime(_ l: AppLanguage) -> String { l == .fr ? "Temps" : "Time" }

    static func sidebarSalesHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Factures et devis." : "Invoices and quotes."
    }
    static func sidebarTimeHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Périodes, minuteur et agrégations." : "Periods, timer and aggregates."
    }

    /// Entrée de tête de la liste des périodes : l'agrégation, tous clients
    /// confondus, qui vivait dans une seconde section de la barre latérale.
    static func allActivity(_ l: AppLanguage) -> String {
        l == .fr ? "Toute l'activité" : "All activity"
    }

    // Compteurs de la barre latérale — trois seulement, chacun rattaché à une
    // action réelle.
    static func sidebarOverdueBadge(_ l: AppLanguage, count: Int) -> String {
        l == .fr
            ? "\(count) facture\(count > 1 ? "s" : "") en retard"
            : "\(count) overdue invoice\(count > 1 ? "s" : "")"
    }
    static func sidebarToBillBadge(_ l: AppLanguage, count: Int) -> String {
        l == .fr
            ? "\(count) période\(count > 1 ? "s" : "") à facturer"
            : "\(count) period\(count > 1 ? "s" : "") to invoice"
    }
    static func sidebarSettingsBadge(_ l: AppLanguage, count: Int) -> String {
        l == .fr
            ? "\(count) mention légale manquante\(count > 1 ? "s" : "")"
            : "\(count) legal detail\(count > 1 ? "s" : "") missing"
    }

    // État de synchronisation, horodaté à la minute.
    static func sidebarSyncing(_ l: AppLanguage) -> String {
        l == .fr ? "Synchronisation…" : "Syncing…"
    }
    static func sidebarSyncedAt(_ l: AppLanguage, time: String) -> String {
        l == .fr ? "Synchronisé · \(time)" : "Synced · \(time)"
    }
    static func sidebarSyncNever(_ l: AppLanguage) -> String {
        l == .fr ? "Jamais synchronisé" : "Never synced"
    }
    static func sidebarSyncOff(_ l: AppLanguage) -> String {
        l == .fr ? "Sauvegarde en ligne désactivée" : "Cloud backup off"
    }
    /// Le bloc d'identité de la barre latérale mène à la fiche entreprise.
    static func openCompanySettings(_ l: AppLanguage) -> String {
        l == .fr ? "Ouvrir la fiche entreprise" : "Open company details"
    }
}
