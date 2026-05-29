import Foundation

// MARK: - Gestion des clients

extension L10n {

    static func noClientSelected(_ l: AppLanguage) -> String { l == .fr ? "Aucun client sélectionné" : "No client selected" }
    static func selectOrCreateClient(_ l: AppLanguage) -> String { l == .fr ? "Sélectionnez un client ou créez-en un nouveau." : "Select a client or create one." }
    static func searchClientPrompt(_ l: AppLanguage) -> String { l == .fr ? "Rechercher un client..." : "Search client..." }
    static func information(_ l: AppLanguage) -> String { l == .fr ? "Informations" : "Information" }
    static func noClientsYet(_ l: AppLanguage) -> String { l == .fr ? "Aucun client" : "No clients" }
    static func deleteClientConfirmTitle(_ l: AppLanguage) -> String {
        l == .fr ? "Supprimer ce client ?" : "Delete this client?"
    }
    static func deleteClientConfirmMessage(_ l: AppLanguage, name: String) -> String {
        l == .fr ? "Le client « \(name) » sera supprimé du carnet. Les documents existants ne seront pas effacés." :
        "Client “\(name)” will be removed from the directory. Existing documents will not be deleted."
    }
}
