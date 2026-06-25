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
    static func filterAll(_ l: AppLanguage) -> String { l == .fr ? "Toutes" : "All" }
    static func filterPaid(_ l: AppLanguage) -> String { l == .fr ? "Payées" : "Paid" }
    static func filterUnpaid(_ l: AppLanguage) -> String { l == .fr ? "Impayées" : "Unpaid" }
    static func filterSent(_ l: AppLanguage) -> String { l == .fr ? "Envoyées" : "Sent" }
    static func filterOverdue(_ l: AppLanguage) -> String { l == .fr ? "En retard" : "Overdue" }
    static func filterDraft(_ l: AppLanguage) -> String { l == .fr ? "Brouillons" : "Drafts" }
    static func filterWithUnpaid(_ l: AppLanguage) -> String { l == .fr ? "Avec impayés" : "With unpaid" }
    static func clearFilters(_ l: AppLanguage) -> String { l == .fr ? "Effacer" : "Clear" }
}
