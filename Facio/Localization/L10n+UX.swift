import Foundation

// MARK: - UI/UX refinement strings

extension L10n {
    static func todayFocus(_ l: AppLanguage) -> String { l == .fr ? "À traiter" : "Needs attention" }
    static func nothingToHandle(_ l: AppLanguage) -> String { l == .fr ? "Rien à traiter" : "Nothing to handle" }
    static func nothingToHandleHint(_ l: AppLanguage) -> String {
        l == .fr ? "Les documents, paiements et périodes sont à jour." : "Documents, payments, and periods are up to date."
    }
    static func overdueInvoices(_ l: AppLanguage) -> String { l == .fr ? "Factures en retard" : "Overdue invoices" }
    static func awaitingPayment(_ l: AppLanguage) -> String { l == .fr ? "Paiement attendu" : "Awaiting payment" }
    static func quotesToFollowUp(_ l: AppLanguage) -> String { l == .fr ? "Devis à relancer" : "Quotes to follow up" }
    static func missingAccountingConversions(_ l: AppLanguage) -> String { l == .fr ? "Conversions manquantes" : "Missing conversions" }
    static func uninvoicedPeriods(_ l: AppLanguage) -> String { l == .fr ? "Périodes à facturer" : "Periods to invoice" }
    static func openDocument(_ l: AppLanguage) -> String { l == .fr ? "Ouvrir le document" : "Open document" }
    static func openPeriod(_ l: AppLanguage) -> String { l == .fr ? "Ouvrir la période" : "Open period" }
    static func recentWork(_ l: AppLanguage) -> String { l == .fr ? "Activité récente" : "Recent activity" }

    static func documentStudio(_ l: AppLanguage) -> String { l == .fr ? "Atelier document" : "Document studio" }
    static func readyToSend(_ l: AppLanguage) -> String { l == .fr ? "Prêt à envoyer" : "Ready to send" }
    static func documentInspector(_ l: AppLanguage) -> String { l == .fr ? "Inspecteur" : "Inspector" }
    static func documentDetails(_ l: AppLanguage) -> String { l == .fr ? "Détails du document" : "Document details" }
    static func documentReadiness(_ l: AppLanguage) -> String { l == .fr ? "Complétude" : "Readiness" }
    static func clientReady(_ l: AppLanguage) -> String { l == .fr ? "Client renseigné" : "Client filled in" }
    static func linesReady(_ l: AppLanguage) -> String { l == .fr ? "Lignes valides" : "Valid line items" }
    static func amountReady(_ l: AppLanguage) -> String { l == .fr ? "Montant positif" : "Positive amount" }
    static func paymentReady(_ l: AppLanguage) -> String { l == .fr ? "Paiement prêt" : "Payment ready" }
    static func conversionReady(_ l: AppLanguage) -> String { l == .fr ? "Conversion comptable prête" : "Accounting conversion ready" }
    static func missingClientHint(_ l: AppLanguage) -> String { l == .fr ? "Choisissez un client ou renseignez son nom." : "Choose a client or enter a client name." }
    static func missingLinesHint(_ l: AppLanguage) -> String { l == .fr ? "Ajoutez au moins une ligne avec une désignation." : "Add at least one line with a description." }
    static func missingAmountHint(_ l: AppLanguage) -> String { l == .fr ? "Le total doit être supérieur à zéro." : "The total must be greater than zero." }
    static func missingPaymentHint(_ l: AppLanguage) -> String { l == .fr ? "Configurez un virement ou un wallet utilisable." : "Configure a usable bank transfer or wallet." }
    static func missingConversionHint(_ l: AppLanguage) -> String { l == .fr ? "Renseignez le taux de conversion." : "Enter the exchange rate." }
    static func pdfActions(_ l: AppLanguage) -> String { l == .fr ? "PDF" : "PDF" }
    static func businessActions(_ l: AppLanguage) -> String { l == .fr ? "Actions métier" : "Business actions" }
    static func duplicateLine(_ l: AppLanguage) -> String { l == .fr ? "Dupliquer la ligne" : "Duplicate line" }
    static func insertLineBelow(_ l: AppLanguage) -> String { l == .fr ? "Insérer une ligne dessous" : "Insert line below" }
    static func deleteLine(_ l: AppLanguage) -> String { l == .fr ? "Supprimer la ligne" : "Delete line" }
    static func invalidLine(_ l: AppLanguage) -> String { l == .fr ? "Ligne à compléter" : "Line needs attention" }

    static func clientTimeline(_ l: AppLanguage) -> String { l == .fr ? "Historique" : "Timeline" }
    static func clientRevenue(_ l: AppLanguage) -> String { l == .fr ? "Facturé" : "Invoiced" }
    static func clientPaid(_ l: AppLanguage) -> String { l == .fr ? "Payé" : "Paid" }
    static func createInvoiceForClient(_ l: AppLanguage) -> String { l == .fr ? "Créer une facture" : "Create invoice" }
    static func createQuoteForClient(_ l: AppLanguage) -> String { l == .fr ? "Créer un devis" : "Create quote" }
    static func noClientActivity(_ l: AppLanguage) -> String { l == .fr ? "Aucune activité pour ce client." : "No activity for this client." }

    static func commandPaletteTitle(_ l: AppLanguage) -> String { l == .fr ? "Commande rapide" : "Quick command" }
    static func privacyToggle(_ l: AppLanguage) -> String { l == .fr ? "Masquer les montants" : "Hide amounts" }
    static func commandPalettePlaceholder(_ l: AppLanguage) -> String { l == .fr ? "Rechercher une action..." : "Search an action..." }
    static func openSettingsPayment(_ l: AppLanguage) -> String { l == .fr ? "Ouvrir les réglages de paiement" : "Open payment settings" }
    static func searchDocumentsAndClients(_ l: AppLanguage) -> String { l == .fr ? "Rechercher documents et clients" : "Search documents and clients" }
    static func quickCreateInvoice(_ l: AppLanguage) -> String { l == .fr ? "Nouvelle facture" : "New invoice" }
    static func quickCreateQuote(_ l: AppLanguage) -> String { l == .fr ? "Nouveau devis" : "New quote" }
    static func quickCreateClient(_ l: AppLanguage) -> String { l == .fr ? "Nouveau client" : "New client" }
    static func noCommandResults(_ l: AppLanguage) -> String { l == .fr ? "Aucune commande trouvée" : "No command found" }
    static func noSearchResults(_ l: AppLanguage) -> String { l == .fr ? "Aucun résultat" : "No results" }
    static func noSearchResultsHint(_ l: AppLanguage) -> String {
        l == .fr ? "Essayez un autre mot-clé ou vérifiez les filtres." : "Try another keyword or check the filters."
    }

    // Toasts (retours non bloquants)
    static func toastPDFExported(_ l: AppLanguage) -> String { l == .fr ? "PDF exporté" : "PDF exported" }
    static func toastFacturXExported(_ l: AppLanguage) -> String { l == .fr ? "Facture électronique exportée" : "Electronic invoice exported" }
    static func toastEmailComposed(_ l: AppLanguage) -> String {
        l == .fr ? "Email préparé dans votre messagerie" : "Email drafted in your mail app"
    }
    static func toastCSVExported(_ l: AppLanguage) -> String { l == .fr ? "CSV exporté" : "CSV exported" }
    static func toastCSVExportFailed(_ l: AppLanguage) -> String {
        l == .fr ? "Export CSV impossible" : "CSV export failed"
    }
    static func toastAttachmentsAdded(_ l: AppLanguage, count: Int) -> String {
        if l == .fr {
            return count == 1 ? "1 justificatif ajouté" : "\(count) justificatifs ajoutés"
        }
        return count == 1 ? "1 supporting document added" : "\(count) supporting documents added"
    }

    // Confirmations destructives
    static func deletePeriodConfirmTitle(_ l: AppLanguage) -> String {
        l == .fr ? "Supprimer cette période ?" : "Delete this period?"
    }
    static func deletePeriodConfirmMessage(_ l: AppLanguage, label: String) -> String {
        l == .fr
            ? "La période \(label) et toutes ses heures saisies seront supprimées définitivement."
            : "Period \(label) and all its recorded hours will be permanently deleted."
    }
    static func deleteAttachmentConfirmTitle(_ l: AppLanguage) -> String {
        l == .fr ? "Supprimer ce justificatif ?" : "Delete this supporting document?"
    }
    static func deleteAttachmentConfirmMessage(_ l: AppLanguage, name: String) -> String {
        l == .fr
            ? "Le fichier « \(name) » sera supprimé définitivement du disque."
            : "The file “\(name)” will be permanently deleted from disk."
    }
    // Champs de formulaire
    static func fieldRequired(_ l: AppLanguage) -> String { l == .fr ? "requis" : "required" }
    /// Le libellé suit l'état : proposer « Masquer les montants » alors qu'ils
    /// sont déjà masqués annonce l'inverse de ce qui va se produire.
    static func privacyHide(_ l: AppLanguage) -> String { l == .fr ? "Masquer les montants" : "Hide amounts" }
    static func privacyShow(_ l: AppLanguage) -> String { l == .fr ? "Afficher les montants" : "Show amounts" }
}
