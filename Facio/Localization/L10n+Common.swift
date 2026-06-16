import Foundation

// MARK: - Labels partages (utilises dans plusieurs ecrans)

extension L10n {

    // Actions
    static func new(_ l: AppLanguage) -> String { l == .fr ? "Nouveau" : "New" }
    static func add(_ l: AppLanguage) -> String { l == .fr ? "Ajouter" : "Add" }
    static func create(_ l: AppLanguage) -> String { l == .fr ? "Créer" : "Create" }
    static func delete(_ l: AppLanguage) -> String { l == .fr ? "Supprimer" : "Delete" }
    static func cancel(_ l: AppLanguage) -> String { l == .fr ? "Annuler" : "Cancel" }
    static func close(_ l: AppLanguage) -> String { l == .fr ? "Fermer" : "Close" }
    static func back(_ l: AppLanguage) -> String { l == .fr ? "Retour" : "Back" }
    static func save(_ l: AppLanguage) -> String { l == .fr ? "Enregistrer" : "Save" }
    static func duplicate(_ l: AppLanguage) -> String { l == .fr ? "Dupliquer" : "Duplicate" }
    static func download(_ l: AppLanguage) -> String { l == .fr ? "Télécharger" : "Download" }
    static func syncUpToDate(_ l: AppLanguage) -> String { l == .fr ? "Synchronisé" : "Up to date" }
    static func later(_ l: AppLanguage) -> String { l == .fr ? "Plus tard" : "Later" }
    static func understood(_ l: AppLanguage) -> String { l == .fr ? "Compris" : "Got it" }

    // Champs communs
    static func name(_ l: AppLanguage) -> String { l == .fr ? "Nom" : "Name" }
    static func address(_ l: AppLanguage) -> String { l == .fr ? "Adresse" : "Address" }
    static func postalCode(_ l: AppLanguage) -> String { l == .fr ? "Code postal" : "Postal code" }
    static func city(_ l: AppLanguage) -> String { l == .fr ? "Ville" : "City" }
    static func email(_ l: AppLanguage) -> String { "Email" }
    static func phone(_ l: AppLanguage) -> String { l == .fr ? "Téléphone" : "Phone" }
    static func vatNumber(_ l: AppLanguage) -> String { l == .fr ? "Numéro TVA" : "VAT number" }
    static func apeCode(_ l: AppLanguage) -> String { l == .fr ? "Code APE" : "APE code" }

    // Labels generiques
    static func type(_ l: AppLanguage) -> String { "Type" }
    static func number(_ l: AppLanguage) -> String { l == .fr ? "Numéro" : "Number" }
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
    static func selectSection(_ l: AppLanguage) -> String { l == .fr ? "Sélectionnez une section" : "Select a section" }

    // Preview / Export
    static func preview(_ l: AppLanguage) -> String { l == .fr ? "Aperçu" : "Preview" }
    static func exportPDF(_ l: AppLanguage) -> String { l == .fr ? "Exporter PDF" : "Export PDF" }
    static func exportFacturX(_ l: AppLanguage) -> String { l == .fr ? "Facture électronique" : "Electronic invoice" }
    static func exportFacturXHelp(_ l: AppLanguage) -> String { l == .fr ? "Exporter en Factur-X (PDF/A-3, XML embarqué)" : "Export as Factur-X (PDF/A-3, embedded XML)" }
    static func facturXOnlyInvoices(_ l: AppLanguage) -> String { l == .fr ? "La facture électronique Factur-X n'est disponible que pour les factures (pas les devis)." : "Factur-X e-invoicing is only available for invoices (not quotes)." }
    static func facturXOnlyEUR(_ l: AppLanguage, currency: String) -> String { l == .fr ? "Factur-X requiert une devise ISO 4217 : indisponible en \(currency). Passez la facture en EUR." : "Factur-X requires an ISO 4217 currency: unavailable in \(currency). Switch the invoice to EUR." }
    static func facturXTitle(_ l: AppLanguage) -> String { l == .fr ? "Facture électronique" : "Electronic invoice" }
    static func facturXIncompleteNoLines(_ l: AppLanguage) -> String { l == .fr ? "Ajoutez au moins une ligne avant de générer la facture électronique." : "Add at least one line before generating the e-invoice." }
    static func facturXIncompleteNumber(_ l: AppLanguage) -> String { l == .fr ? "Cette facture n'a pas de numéro." : "This invoice has no number." }
    static func facturXIncompleteClient(_ l: AppLanguage) -> String { l == .fr ? "Renseignez le nom du client de la facture." : "Add the invoice client's name." }
    static func facturXMissingSellerVAT(_ l: AppLanguage) -> String { l == .fr ? "Renseignez votre numéro de TVA intracommunautaire (Réglages › Société) : il est obligatoire pour une facture avec TVA." : "Add your intracommunity VAT number (Settings › Company): it is required for an invoice that charges VAT." }
    static func exportDocument(_ l: AppLanguage) -> String { l == .fr ? "Exporter le document" : "Export document" }
    static func chooseSaveLocation(_ l: AppLanguage) -> String { l == .fr ? "Choisissez où sauvegarder le fichier PDF" : "Choose where to save the PDF file" }
    static func chooseCSVSaveLocation(_ l: AppLanguage) -> String { l == .fr ? "Choisissez où sauvegarder le fichier CSV" : "Choose where to save the CSV file" }
    static func previewTitle(_ l: AppLanguage, number: String) -> String { l == .fr ? "Aperçu — \(number)" : "Preview — \(number)" }
    static func pdfGenerationError(_ l: AppLanguage) -> String { l == .fr ? "Erreur de génération" : "Generation error" }
    static func cannotGeneratePDF(_ l: AppLanguage) -> String { l == .fr ? "Impossible de générer le PDF." : "Could not generate PDF." }
    static func pdfExportError(_ l: AppLanguage) -> String { l == .fr ? "Erreur d'export PDF" : "PDF export error" }
    static func cannotExportPDF(_ l: AppLanguage) -> String {
        l == .fr ? "Impossible d'enregistrer le PDF. Vérifiez l'emplacement choisi et réessayez."
        : "Could not save the PDF. Check the selected location and try again."
    }

    // Alertes app
    static func firstLaunchTitle(_ l: AppLanguage) -> String { l == .fr ? "Bienvenue sur Facio !" : "Welcome to Facio!" }
    static func firstLaunchMessage(_ l: AppLanguage) -> String {
        l == .fr ? "Vous pouvez supprimer le fichier DMG de vos téléchargements, Facio est installé."
        : "You can delete the DMG file from Downloads. Facio is installed."
    }
    static func updateAvailableTitle(_ l: AppLanguage) -> String { l == .fr ? "Nouvelle version disponible" : "New version available" }
    static func updateAvailableMessage(_ l: AppLanguage, version: String) -> String {
        l == .fr ? "Facio \(version) est disponible. Téléchargez la dernière version sur GitHub."
        : "Facio \(version) is available. Download the latest version from GitHub."
    }
}
