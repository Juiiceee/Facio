import Foundation

// MARK: - Tri & filtres des listes (factures, devis, clients)

extension L10n {
    // Tri
    static func sortBy(_ l: AppLanguage) -> String { l == .fr ? "Trier" : "Sort" }
    static func sortDirection(_ l: AppLanguage) -> String { l == .fr ? "Sens" : "Direction" }
    static func sortAscending(_ l: AppLanguage) -> String { l == .fr ? "Croissant" : "Ascending" }
    static func sortDescending(_ l: AppLanguage) -> String { l == .fr ? "Décroissant" : "Descending" }

    // Critères de tri — documents
    static func sortDate(_ l: AppLanguage) -> String { l == .fr ? "Date" : "Date" }
    static func sortAmount(_ l: AppLanguage) -> String { l == .fr ? "Montant" : "Amount" }
    static func sortClient(_ l: AppLanguage) -> String { l == .fr ? "Client" : "Client" }
    static func sortStatus(_ l: AppLanguage) -> String { l == .fr ? "Statut" : "Status" }
    static func sortNumber(_ l: AppLanguage) -> String { l == .fr ? "Numéro" : "Number" }

    // Critères de tri — clients
    static func sortName(_ l: AppLanguage) -> String { l == .fr ? "Nom" : "Name" }
    static func sortTotalInvoiced(_ l: AppLanguage) -> String { l == .fr ? "Total facturé" : "Total invoiced" }
    static func sortTotalPaid(_ l: AppLanguage) -> String { l == .fr ? "Total payé" : "Total paid" }
    static func sortDateAdded(_ l: AppLanguage) -> String { l == .fr ? "Date d'ajout" : "Date added" }

    // Filtres
    static func filterOverdue(_ l: AppLanguage) -> String { l == .fr ? "En retard" : "Overdue" }
    static func filterWithUnpaid(_ l: AppLanguage) -> String { l == .fr ? "Avec impayés" : "With unpaid" }

    // Panneau de filtres (style Notion)
    static func filterButton(_ l: AppLanguage) -> String { l == .fr ? "Filtrer" : "Filter" }
    static func filterReset(_ l: AppLanguage) -> String { l == .fr ? "Réinitialiser" : "Reset" }
    static func filterPeriod(_ l: AppLanguage) -> String { l == .fr ? "Période" : "Period" }
    static func filterAmount(_ l: AppLanguage) -> String { l == .fr ? "Montant" : "Amount" }
    static func filterMin(_ l: AppLanguage) -> String { l == .fr ? "Min" : "Min" }
    static func filterMax(_ l: AppLanguage) -> String { l == .fr ? "Max" : "Max" }
    static func filterFrom(_ l: AppLanguage) -> String { l == .fr ? "Du" : "From" }
    static func filterTo(_ l: AppLanguage) -> String { l == .fr ? "Au" : "To" }
    static func periodAll(_ l: AppLanguage) -> String { l == .fr ? "Toutes" : "All" }
    static func periodThisMonth(_ l: AppLanguage) -> String { l == .fr ? "Ce mois-ci" : "This month" }
    static func periodThisYear(_ l: AppLanguage) -> String { l == .fr ? "Cette année" : "This year" }
    static func periodCustom(_ l: AppLanguage) -> String { l == .fr ? "Personnalisée" : "Custom" }
    static func filterAllClients(_ l: AppLanguage) -> String { l == .fr ? "Tous les clients" : "All clients" }
    static func filterAllCurrencies(_ l: AppLanguage) -> String { l == .fr ? "Toutes les devises" : "All currencies" }
    static func filterCurrency(_ l: AppLanguage) -> String { l == .fr ? "Devise" : "Currency" }
}
