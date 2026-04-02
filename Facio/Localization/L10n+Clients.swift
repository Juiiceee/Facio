import Foundation

// MARK: - Gestion des clients

extension L10n {

    static func noClientSelected(_ l: AppLanguage) -> String { l == .fr ? "Aucun client selectionne" : "No client selected" }
    static func selectOrCreateClient(_ l: AppLanguage) -> String { l == .fr ? "Selectionnez un client ou creez-en un nouveau." : "Select a client or create a new one." }
    static func searchClientPrompt(_ l: AppLanguage) -> String { l == .fr ? "Rechercher un client..." : "Search client..." }
    static func information(_ l: AppLanguage) -> String { l == .fr ? "Informations" : "Information" }
}
