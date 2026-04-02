import Foundation

// MARK: - Editeur et liste de documents (factures & devis)

extension L10n {

    // En-tete
    static func newDocument(_ l: AppLanguage) -> String { l == .fr ? "Nouveau document" : "New document" }
    static func headerSection(_ l: AppLanguage) -> String { l == .fr ? "En-tete" : "Header" }

    // Dates
    static func datesSection(_ l: AppLanguage) -> String { "Dates" }
    static func creationDate(_ l: AppLanguage) -> String { l == .fr ? "Date de creation" : "Creation date" }
    static func dueDateLabel(_ l: AppLanguage) -> String { l == .fr ? "Date d'echeance" : "Due date" }

    // Devise & Paiement
    static func currencyPayment(_ l: AppLanguage) -> String { l == .fr ? "Devise & Paiement" : "Currency & Payment" }
    static func payment(_ l: AppLanguage) -> String { l == .fr ? "Paiement" : "Payment" }
    static func blockchainNone(_ l: AppLanguage) -> String { l == .fr ? "Aucune" : "None" }

    // Destinataire
    static func recipientSection(_ l: AppLanguage) -> String { l == .fr ? "DESTINATAIRE" : "RECIPIENT" }
    static func clientInfo(_ l: AppLanguage) -> String { l == .fr ? "Informations client" : "Client information" }
    static func clientBook(_ l: AppLanguage) -> String { l == .fr ? "Carnet de clients" : "Client directory" }
    static func clientName(_ l: AppLanguage) -> String { l == .fr ? "Nom du client" : "Client name" }

    // Lignes
    static func linesSection(_ l: AppLanguage) -> String { l == .fr ? "Lignes" : "Line items" }
    static func designationLabel(_ l: AppLanguage) -> String { l == .fr ? "Designation" : "Description" }
    static func quantityLabel(_ l: AppLanguage) -> String { l == .fr ? "Quantite" : "Quantity" }
    static func unitPrice(_ l: AppLanguage) -> String { l == .fr ? "Prix unitaire" : "Unit price" }
    static func vatLabel(_ l: AppLanguage) -> String { l == .fr ? "TVA" : "VAT" }
    static func totalHTLabel(_ l: AppLanguage) -> String { l == .fr ? "Total HT" : "Subtotal" }
    static func priceLabel(_ l: AppLanguage) -> String { l == .fr ? "Prix" : "Price" }
    static func qtyShort(_ l: AppLanguage) -> String { l == .fr ? "Qte" : "Qty" }
    static func noLines(_ l: AppLanguage) -> String { l == .fr ? "Aucune ligne. Ajoutez-en une ci-dessous." : "No line items. Add one below." }
    static func addEmptyLine(_ l: AppLanguage) -> String { l == .fr ? "Ajouter une ligne vide" : "Add empty line" }
    static func favoriteService(_ l: AppLanguage) -> String { l == .fr ? "Prestation favorite" : "Favorite service" }

    // Paiement (UI)
    static func paymentBankSection(_ l: AppLanguage) -> String { l == .fr ? "Paiement — Virement bancaire" : "Payment — Bank transfer" }
    static func noIBANConfigured(_ l: AppLanguage) -> String { l == .fr ? "Aucun IBAN configure (voir Parametres > Paiement)" : "No IBAN configured (see Settings > Payment)" }
    static func paymentCryptoSection(_ l: AppLanguage) -> String { l == .fr ? "Paiement — Crypto" : "Payment — Crypto" }
    static func network(_ l: AppLanguage) -> String { l == .fr ? "Reseau" : "Network" }
    static func wallet(_ l: AppLanguage) -> String { "Wallet" }
    static func noWalletConfigured(_ l: AppLanguage, chain: String) -> String { l == .fr ? "Aucun wallet configure pour \(chain) (voir Parametres > Paiement)" : "No wallet configured for \(chain) (see Settings > Payment)" }
    static func selectNetwork(_ l: AppLanguage) -> String { l == .fr ? "Selectionnez un reseau dans la section Devise & Paiement" : "Select a network in the Currency & Payment section" }

    // Signatures
    static func paymentProofsSection(_ l: AppLanguage) -> String { l == .fr ? "Preuves de paiement" : "Payment proofs" }
    static func addSignature(_ l: AppLanguage) -> String { l == .fr ? "Ajouter une signature" : "Add signature" }
    static func noSignatures(_ l: AppLanguage) -> String { l == .fr ? "Aucune signature enregistree." : "No signatures recorded." }
    static func viewOn(_ l: AppLanguage, explorer: String) -> String { l == .fr ? "Voir sur \(explorer)" : "View on \(explorer)" }
    static func addPaymentProof(_ l: AppLanguage) -> String { l == .fr ? "Ajouter une preuve de paiement" : "Add payment proof" }
    static func txHash(_ l: AppLanguage) -> String { l == .fr ? "Signature / Hash de transaction" : "Signature / Transaction hash" }

    // Client picker
    static func selectClient(_ l: AppLanguage) -> String { l == .fr ? "Selectionner un client" : "Select a client" }
    static func newClient(_ l: AppLanguage) -> String { l == .fr ? "Nouveau client" : "New client" }
    static func createAndSelect(_ l: AppLanguage) -> String { l == .fr ? "Creer et selectionner" : "Create and select" }
    static func searchClient(_ l: AppLanguage) -> String { l == .fr ? "Rechercher un client" : "Search client" }

    // Liste documents
    static func convertToInvoice(_ l: AppLanguage) -> String { l == .fr ? "Convertir en Facture" : "Convert to Invoice" }
    static func searchByNumberOrClient(_ l: AppLanguage) -> String { l == .fr ? "Rechercher par numero ou client" : "Search by number or client" }
    static func noDocuments(_ l: AppLanguage, type: String) -> String { l == .fr ? "Aucun \(type)" : "No \(type)" }
    static func clickToCreate(_ l: AppLanguage, type: String) -> String { l == .fr ? "Cliquez sur + pour creer un \(type)." : "Click + to create a \(type)." }
    static func noClient(_ l: AppLanguage) -> String { l == .fr ? "Sans client" : "No client" }

    // Etats vides
    static func noDocumentSelected(_ l: AppLanguage) -> String { l == .fr ? "Aucun document selectionne" : "No document selected" }
    static func selectDocumentHint(_ l: AppLanguage) -> String { l == .fr ? "Selectionnez un document dans la liste ou creez-en un nouveau avec +" : "Select a document from the list or create a new one with +" }
    static func noPeriodSelected(_ l: AppLanguage) -> String { l == .fr ? "Aucune periode selectionnee" : "No period selected" }
    static func selectPeriodHint(_ l: AppLanguage) -> String { l == .fr ? "Selectionnez une periode ou creez-en une avec +" : "Select a period or create one with +" }
}
