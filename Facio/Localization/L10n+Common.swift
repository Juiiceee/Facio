import Foundation

// MARK: - Labels partages (utilises dans plusieurs ecrans)

extension L10n {

    // Actions
    static func new(_ l: AppLanguage) -> String { l == .fr ? "Nouveau" : "New" }
    static func add(_ l: AppLanguage) -> String { l == .fr ? "Ajouter" : "Add" }
    static func create(_ l: AppLanguage) -> String { l == .fr ? "Creer" : "Create" }
    static func delete(_ l: AppLanguage) -> String { l == .fr ? "Supprimer" : "Delete" }
    static func cancel(_ l: AppLanguage) -> String { l == .fr ? "Annuler" : "Cancel" }
    static func close(_ l: AppLanguage) -> String { l == .fr ? "Fermer" : "Close" }
    static func duplicate(_ l: AppLanguage) -> String { l == .fr ? "Dupliquer" : "Duplicate" }
    static func download(_ l: AppLanguage) -> String { l == .fr ? "Telecharger" : "Download" }
    static func later(_ l: AppLanguage) -> String { l == .fr ? "Plus tard" : "Later" }
    static func understood(_ l: AppLanguage) -> String { l == .fr ? "Compris" : "Got it" }

    // Champs communs
    static func name(_ l: AppLanguage) -> String { l == .fr ? "Nom" : "Name" }
    static func address(_ l: AppLanguage) -> String { l == .fr ? "Adresse" : "Address" }
    static func postalCode(_ l: AppLanguage) -> String { l == .fr ? "Code postal" : "Postal code" }
    static func city(_ l: AppLanguage) -> String { l == .fr ? "Ville" : "City" }
    static func email(_ l: AppLanguage) -> String { "Email" }
    static func phone(_ l: AppLanguage) -> String { l == .fr ? "Telephone" : "Phone" }
    static func vatNumber(_ l: AppLanguage) -> String { l == .fr ? "Numero TVA" : "VAT number" }
    static func apeCode(_ l: AppLanguage) -> String { l == .fr ? "Code APE" : "APE code" }

    // Labels generiques
    static func type(_ l: AppLanguage) -> String { "Type" }
    static func number(_ l: AppLanguage) -> String { l == .fr ? "Numero" : "Number" }
    static func status(_ l: AppLanguage) -> String { l == .fr ? "Statut" : "Status" }
    static func language(_ l: AppLanguage) -> String { l == .fr ? "Langue" : "Language" }
    static func date(_ l: AppLanguage) -> String { "Date" }
    static func amount(_ l: AppLanguage) -> String { l == .fr ? "Montant" : "Amount" }
    static func notes(_ l: AppLanguage) -> String { "Notes" }
    static func blockchain(_ l: AppLanguage) -> String { "Blockchain" }
    static func contact(_ l: AppLanguage) -> String { "Contact" }
    static func logo(_ l: AppLanguage) -> String { "Logo" }
    static func iban(_ l: AppLanguage) -> String { "IBAN" }
    static func bic(_ l: AppLanguage) -> String { "BIC" }

    // Navigation
    static func selectSection(_ l: AppLanguage) -> String { l == .fr ? "Selectionnez une section" : "Select a section" }

    // Preview / Export
    static func preview(_ l: AppLanguage) -> String { l == .fr ? "Apercu" : "Preview" }
    static func exportPDF(_ l: AppLanguage) -> String { l == .fr ? "Exporter PDF" : "Export PDF" }
    static func exportDocument(_ l: AppLanguage) -> String { l == .fr ? "Exporter le document" : "Export document" }
    static func chooseSaveLocation(_ l: AppLanguage) -> String { l == .fr ? "Choisissez où sauvegarder le fichier PDF" : "Choose where to save the PDF file" }
    static func previewTitle(_ l: AppLanguage, number: String) -> String { l == .fr ? "Aperçu — \(number)" : "Preview — \(number)" }
    static func pdfGenerationError(_ l: AppLanguage) -> String { l == .fr ? "Erreur de génération" : "Generation error" }
    static func cannotGeneratePDF(_ l: AppLanguage) -> String { l == .fr ? "Impossible de générer le PDF." : "Could not generate PDF." }
    static func pdfExportError(_ l: AppLanguage) -> String { l == .fr ? "Erreur d'export PDF" : "PDF export error" }
    static func cannotExportPDF(_ l: AppLanguage) -> String {
        l == .fr ? "Impossible d'enregistrer le PDF. Verifiez l'emplacement choisi et reessayez."
        : "Could not save the PDF. Check the selected location and try again."
    }

    // Alertes app
    static func firstLaunchTitle(_ l: AppLanguage) -> String { l == .fr ? "Bienvenue sur Facio !" : "Welcome to Facio!" }
    static func firstLaunchMessage(_ l: AppLanguage) -> String {
        l == .fr ? "Vous pouvez supprimer le fichier DMG de vos telechargements, Facio est installe."
        : "You can delete the DMG file from Downloads. Facio is installed."
    }
    static func updateAvailableTitle(_ l: AppLanguage) -> String { l == .fr ? "Nouvelle version disponible" : "New version available" }
    static func updateAvailableMessage(_ l: AppLanguage, version: String) -> String {
        l == .fr ? "Facio \(version) est disponible. Telechargez la derniere version sur GitHub."
        : "Facio \(version) is available. Download the latest version from GitHub."
    }
}
