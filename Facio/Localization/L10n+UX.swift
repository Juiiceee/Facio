import Foundation

// MARK: - UI/UX refinement strings

extension L10n {
    static func todayFocus(_ l: AppLanguage) -> String { l == .fr ? "À traiter" : "Today" }
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
    static func commandPalettePlaceholder(_ l: AppLanguage) -> String { l == .fr ? "Rechercher une action..." : "Search an action..." }
    static func openSettingsPayment(_ l: AppLanguage) -> String { l == .fr ? "Ouvrir les réglages de paiement" : "Open payment settings" }
    static func searchDocumentsAndClients(_ l: AppLanguage) -> String { l == .fr ? "Rechercher documents et clients" : "Search documents and clients" }
    static func quickCreateInvoice(_ l: AppLanguage) -> String { l == .fr ? "Nouvelle facture" : "New invoice" }
    static func quickCreateQuote(_ l: AppLanguage) -> String { l == .fr ? "Nouveau devis" : "New quote" }
    static func quickCreateClient(_ l: AppLanguage) -> String { l == .fr ? "Nouveau client" : "New client" }
    static func noCommandResults(_ l: AppLanguage) -> String { l == .fr ? "Aucune commande trouvée" : "No command found" }
}

