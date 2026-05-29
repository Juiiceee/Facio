import Foundation

// MARK: - Editeur et liste de documents (factures & devis)

extension L10n {

    // En-tete
    static func newDocument(_ l: AppLanguage) -> String { l == .fr ? "Nouveau document" : "New document" }
    static func headerSection(_ l: AppLanguage) -> String { l == .fr ? "En-tête" : "Header" }

    // Dates
    static func datesSection(_ l: AppLanguage) -> String { "Dates" }
    static func creationDate(_ l: AppLanguage) -> String { l == .fr ? "Date de création" : "Creation date" }
    static func dueDateLabel(_ l: AppLanguage) -> String { l == .fr ? "Date d'échéance" : "Due date" }

    // Devise & Paiement
    static func currencyPayment(_ l: AppLanguage) -> String { l == .fr ? "Devise & Paiement" : "Currency & Payment" }
    static func payment(_ l: AppLanguage) -> String { l == .fr ? "Paiement" : "Payment" }
    static func blockchainNone(_ l: AppLanguage) -> String { l == .fr ? "Aucune" : "None" }
    static func accountingConversion(_ l: AppLanguage) -> String { l == .fr ? "Conversion comptable" : "Accounting conversion" }
    static func accountingCurrency(_ l: AppLanguage) -> String { l == .fr ? "Devise comptable" : "Accounting currency" }
    static func exchangeRate(_ l: AppLanguage) -> String { l == .fr ? "Taux de conversion" : "Exchange rate" }
    static func accountingTotal(_ l: AppLanguage) -> String { l == .fr ? "Total comptable" : "Accounting total" }
    static func exchangeRateHint(_ l: AppLanguage, source: String, target: String) -> String {
        l == .fr ? "1 \(source) = ... \(target)" : "1 \(source) = ... \(target)"
    }
    static func exchangeRateRequiredForDashboard(_ l: AppLanguage) -> String {
        l == .fr ? "Renseignez ce taux pour inclure cette facture dans le CA du tableau de bord."
        : "Enter this rate to include this invoice in dashboard revenue."
    }

    // Destinataire
    static func recipientSection(_ l: AppLanguage) -> String { l == .fr ? "DESTINATAIRE" : "RECIPIENT" }
    static func clientInfo(_ l: AppLanguage) -> String { l == .fr ? "Informations client" : "Client information" }
    static func clientBook(_ l: AppLanguage) -> String { l == .fr ? "Carnet de clients" : "Client directory" }
    static func clientName(_ l: AppLanguage) -> String { l == .fr ? "Nom du client" : "Client name" }

    // Lignes
    static func linesSection(_ l: AppLanguage) -> String { l == .fr ? "Lignes" : "Line items" }
    static func designationLabel(_ l: AppLanguage) -> String { l == .fr ? "Désignation" : "Description" }
    static func quantityLabel(_ l: AppLanguage) -> String { l == .fr ? "Quantité" : "Quantity" }
    static func unitPrice(_ l: AppLanguage) -> String { l == .fr ? "Prix unitaire" : "Unit price" }
    static func vatLabel(_ l: AppLanguage) -> String { l == .fr ? "TVA" : "VAT" }
    static func totalHTLabel(_ l: AppLanguage) -> String { l == .fr ? "Total HT" : "Subtotal" }
    static func priceLabel(_ l: AppLanguage) -> String { l == .fr ? "Prix" : "Price" }
    static func qtyShort(_ l: AppLanguage) -> String { l == .fr ? "Qte" : "Qty" }
    static func noLines(_ l: AppLanguage) -> String { l == .fr ? "Aucune ligne. Ajoutez-en une ci-dessous." : "No line items. Add one below." }
    static func addEmptyLine(_ l: AppLanguage) -> String { l == .fr ? "Ajouter une ligne vide" : "Add empty line" }
    static func favoriteService(_ l: AppLanguage) -> String { l == .fr ? "Prestation favorite" : "Favorite service" }
    static func unitShort(_ l: AppLanguage) -> String { l == .fr ? "u" : "unit" }

    // Paiement (UI)
    static func paymentBankSection(_ l: AppLanguage) -> String { l == .fr ? "Paiement — Virement bancaire" : "Payment — Bank transfer" }
    static func noIBANConfigured(_ l: AppLanguage) -> String { l == .fr ? "Aucun IBAN configuré (voir Paramètres > Paiement)" : "No IBAN configured (see Settings > Payment)" }
    static func noBankAccountConfigured(_ l: AppLanguage) -> String { l == .fr ? "Aucun compte bancaire utilisable (voir Paramètres > Paiement)" : "No usable bank account configured (see Settings > Payment)" }
    static func paymentCryptoSection(_ l: AppLanguage) -> String { l == .fr ? "Paiement — Crypto" : "Payment — Crypto" }
    static func network(_ l: AppLanguage) -> String { l == .fr ? "Réseau" : "Network" }
    static func wallet(_ l: AppLanguage) -> String { "Wallet" }
    static func noWalletConfigured(_ l: AppLanguage, chain: String) -> String { l == .fr ? "Aucun wallet configuré pour \(chain) (voir Paramètres > Paiement)" : "No wallet configured for \(chain) (see Settings > Payment)" }
    static func selectNetwork(_ l: AppLanguage) -> String { l == .fr ? "Sélectionnez un réseau dans la section Devise & Paiement" : "Select a network in the Currency & Payment section" }

    // Signatures
    static func paymentProofsSection(_ l: AppLanguage) -> String { l == .fr ? "Preuves de paiement" : "Payment proofs" }
    static func addSignature(_ l: AppLanguage) -> String { l == .fr ? "Ajouter une signature" : "Add signature" }
    static func noSignatures(_ l: AppLanguage) -> String { l == .fr ? "Aucune signature enregistrée." : "No signatures recorded." }
    static func viewOn(_ l: AppLanguage, explorer: String) -> String { l == .fr ? "Voir sur \(explorer)" : "View on \(explorer)" }
    static func addPaymentProof(_ l: AppLanguage) -> String { l == .fr ? "Ajouter une preuve de paiement" : "Add payment proof" }
    static func txHash(_ l: AppLanguage) -> String { l == .fr ? "Signature / Hash de transaction" : "Signature / Transaction hash" }

    // Client picker
    static func selectClient(_ l: AppLanguage) -> String { l == .fr ? "Sélectionner un client" : "Select a client" }
    static func newClient(_ l: AppLanguage) -> String { l == .fr ? "Nouveau client" : "New client" }
    static func createAndSelect(_ l: AppLanguage) -> String { l == .fr ? "Créer et sélectionner" : "Create and select" }
    static func searchClient(_ l: AppLanguage) -> String { l == .fr ? "Rechercher un client" : "Search client" }

    // Liste documents
    static func convertToInvoice(_ l: AppLanguage) -> String { l == .fr ? "Convertir en Facture" : "Convert to Invoice" }
    static func searchByNumberOrClient(_ l: AppLanguage) -> String { l == .fr ? "Rechercher par numéro ou client" : "Search by number or client" }
    static func noDocuments(_ l: AppLanguage, type: String) -> String { l == .fr ? "Aucun \(type)" : "No \(type)" }
    static func clickToCreate(_ l: AppLanguage, type: String) -> String { l == .fr ? "Cliquez sur + pour créer un \(type)." : "Click + to create a \(type)." }
    static func noClient(_ l: AppLanguage) -> String { l == .fr ? "Sans client" : "No client" }
    static func overdue(_ l: AppLanguage) -> String { l == .fr ? "Retard" : "Overdue" }
    static func deleteDocumentConfirmTitle(_ l: AppLanguage) -> String {
        l == .fr ? "Supprimer ce document ?" : "Delete this document?"
    }
    static func deleteDocumentConfirmMessage(_ l: AppLanguage, number: String) -> String {
        l == .fr ? "Le document \(number) sera supprimé définitivement." : "Document \(number) will be permanently deleted."
    }

    // Etats vides
    static func noDocumentSelected(_ l: AppLanguage) -> String { l == .fr ? "Aucun document sélectionné" : "No document selected" }
    static func selectDocumentHint(_ l: AppLanguage) -> String { l == .fr ? "Sélectionnez un document dans la liste ou créez-en un nouveau avec +" : "Select a document from the list or create a new one with +" }
    static func noPeriodSelected(_ l: AppLanguage) -> String { l == .fr ? "Aucune période sélectionnée" : "No period selected" }
    static func selectPeriodHint(_ l: AppLanguage) -> String { l == .fr ? "Sélectionnez une période ou créez-en une avec +" : "Select a period or create one with +" }
}
