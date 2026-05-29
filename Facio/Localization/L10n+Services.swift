import Foundation

// MARK: - Services, persistence, sync and exports

extension L10n {

    // Export CSV
    static func defaultCSVName(_ l: AppLanguage) -> String { l == .fr ? "temps-suivi" : "time-entries" }

    static func csvHeaders(_ l: AppLanguage) -> [String] {
        l == .fr
            ? [
                "date",
                "description",
                "client",
                "projet",
                "tâche",
                "tags",
                "début",
                "fin",
                "durée_brute",
                "durée_arrondie",
                "facturable",
                "taux_horaire",
                "montant",
                "devise",
                "facturé",
                "numéro_facture",
            ]
            : [
                "date",
                "description",
                "client",
                "project",
                "task",
                "tags",
                "start",
                "end",
                "duration_raw",
                "duration_rounded",
                "billable",
                "hourly_rate",
                "amount",
                "currency",
                "invoiced",
                "invoice_number",
            ]
    }

    // Persistence
    static func storageFolderCreationFailed(_ l: AppLanguage, error: String) -> String {
        l == .fr ? "Impossible de créer le dossier de stockage: \(error)" :
        "Could not create the storage folder: \(error)"
    }

    static func backupUnavailable(_ l: AppLanguage) -> String {
        l == .fr ? "backup indisponible" : "backup unavailable"
    }

    static func persistenceReadFailed(_ l: AppLanguage, fileName: String, error: String, backupPath: String) -> String {
        l == .fr ? "Lecture impossible de \(fileName): \(error). Fichier préservé: \(backupPath)" :
        "Could not read \(fileName): \(error). Preserved file: \(backupPath)"
    }

    static func persistenceSaveBlocked(_ l: AppLanguage, fileName: String) -> String {
        l == .fr ? "Sauvegarde bloquée pour \(fileName): le fichier local n'a pas pu être décodé au chargement." :
        "Save blocked for \(fileName): the local file could not be decoded during load."
    }

    static func persistenceSaveFailed(_ l: AppLanguage, fileName: String, error: String) -> String {
        l == .fr ? "Sauvegarde impossible de \(fileName): \(error)" :
        "Could not save \(fileName): \(error)"
    }

    static func persistenceBackupFailed(_ l: AppLanguage, fileName: String, error: String) -> String {
        l == .fr ? "Backup impossible de \(fileName): \(error)" :
        "Could not back up \(fileName): \(error)"
    }

    // Authentication
    static func authMissingSupabaseConfiguration(_ l: AppLanguage) -> String {
        l == .fr ? "Configuration Supabase manquante" : "Missing Supabase configuration"
    }

    static func authSendCodeFailed(_ l: AppLanguage, statusCode: Int) -> String {
        l == .fr ? "Erreur d'envoi du code (HTTP \(statusCode))" :
        "Could not send the code (HTTP \(statusCode))"
    }

    static func authInvalidOrExpiredCode(_ l: AppLanguage) -> String {
        l == .fr ? "Code invalide ou expiré" : "Invalid or expired code"
    }

    static func authInvalidSupabaseResponse(_ l: AppLanguage) -> String {
        l == .fr ? "Réponse Supabase invalide" : "Invalid Supabase response"
    }

    static func authRefreshSessionFailed(_ l: AppLanguage, statusCode: Int) -> String {
        l == .fr ? "Erreur de rafraîchissement de session (HTTP \(statusCode))" :
        "Could not refresh the session (HTTP \(statusCode))"
    }

    static func authSessionMigrationFailed(_ l: AppLanguage) -> String {
        l == .fr ? "Erreur de migration de la session" : "Could not migrate the session"
    }

    static func authSessionSaveFailed(_ l: AppLanguage) -> String {
        l == .fr ? "Erreur d'enregistrement de la session" : "Could not save the session"
    }

    static func authInvalidSupabaseURL(_ l: AppLanguage) -> String {
        l == .fr ? "URL Supabase invalide" : "Invalid Supabase URL"
    }

    static func authInsecureSupabaseURL(_ l: AppLanguage) -> String {
        l == .fr ? "URL Supabase non sécurisée" : "Insecure Supabase URL"
    }

    // Synchronization
    static func syncLocalReadFailed(_ l: AppLanguage, fileName: String) -> String {
        l == .fr ? "Lecture locale impossible: \(fileName)" : "Could not read local file: \(fileName)"
    }

    static func syncPartialLocalDataPending(_ l: AppLanguage) -> String {
        l == .fr ? "Synchronisation partielle: des données locales restent à envoyer." :
        "Partial sync: some local data still needs to be uploaded."
    }

    static func syncPartialLocalSaveFailed(_ l: AppLanguage) -> String {
        l == .fr ? "Synchronisation partielle: sauvegarde locale impossible." :
        "Partial sync: local save failed."
    }

    static func syncHTTPError(_ l: AppLanguage, statusCode: Int) -> String {
        l == .fr ? "Erreur HTTP \(statusCode)" : "HTTP error \(statusCode)"
    }

    static func syncRemoteIDsInvalidURL(_ l: AppLanguage, table: String) -> String {
        l == .fr ? "URL Supabase invalide pour \(table)." : "Invalid Supabase URL for \(table)."
    }

    static func syncRemoteIDsInvalidResponse(_ l: AppLanguage, table: String) -> String {
        l == .fr ? "Réponse Supabase invalide pendant la lecture des IDs \(table)." :
        "Invalid Supabase response while reading \(table) IDs."
    }

    static func syncRemoteIDsHTTPStatus(_ l: AppLanguage, table: String, statusCode: Int, message: String?) -> String {
        if let message, !message.isEmpty {
            return l == .fr ? "Lecture des IDs \(table) impossible: HTTP \(statusCode) - \(message)" :
                "Could not read \(table) IDs: HTTP \(statusCode) - \(message)"
        }
        return l == .fr ? "Lecture des IDs \(table) impossible: HTTP \(statusCode)" :
            "Could not read \(table) IDs: HTTP \(statusCode)"
    }

    static func syncRemoteIDsInvalidPayload(_ l: AppLanguage, table: String) -> String {
        l == .fr ? "Payload Supabase invalide pendant la lecture des IDs \(table)." :
        "Invalid Supabase payload while reading \(table) IDs."
    }

    static func syncRemoteIDsRequestFailed(_ l: AppLanguage, table: String, error: String) -> String {
        l == .fr ? "Lecture des IDs \(table) impossible: \(error)" :
        "Could not read \(table) IDs: \(error)"
    }
}
