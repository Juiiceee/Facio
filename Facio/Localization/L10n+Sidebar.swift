import Foundation

// MARK: - Navigation laterale (sidebar)

extension L10n {

    static func sidebarInvoices(_ l: AppLanguage) -> String { l == .fr ? "Factures" : "Invoices" }
    static func sidebarQuotes(_ l: AppLanguage) -> String { l == .fr ? "Devis" : "Quotes" }
    static func sidebarClients(_ l: AppLanguage) -> String { "Clients" }
    static func sidebarTimeTracking(_ l: AppLanguage) -> String { l == .fr ? "Suivi des heures" : "Time tracking" }
    static func sidebarDashboard(_ l: AppLanguage) -> String { l == .fr ? "Tableau de bord" : "Dashboard" }
    static func sidebarSettings(_ l: AppLanguage) -> String { l == .fr ? "Parametres" : "Settings" }
    static func sidebarDocuments(_ l: AppLanguage) -> String { "Documents" }
    static func sidebarManagement(_ l: AppLanguage) -> String { l == .fr ? "Gestion" : "Management" }
}
