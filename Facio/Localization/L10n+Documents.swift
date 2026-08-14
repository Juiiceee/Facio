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
    static func paymentDate(_ l: AppLanguage) -> String { l == .fr ? "Date de paiement" : "Payment date" }
    static func amountPaid(_ l: AppLanguage) -> String { l == .fr ? "Montant payé" : "Amount paid" }
    static func remainingToPay(_ l: AppLanguage) -> String { l == .fr ? "Reste à payer" : "Remaining to pay" }
    static func partialPayments(_ l: AppLanguage) -> String { l == .fr ? "Paiements partiels" : "Partial payments" }
    static func addPartialPayment(_ l: AppLanguage) -> String { l == .fr ? "Ajouter un paiement" : "Add a payment" }
    static func payRemainingBalance(_ l: AppLanguage, amount: String) -> String {
        l == .fr ? "Payer le reste (\(amount))" : "Pay the remainder (\(amount))"
    }
    static func noPartialPayments(_ l: AppLanguage) -> String { l == .fr ? "Aucun paiement enregistré." : "No payment recorded yet." }

    // Devise & Paiement
    static func currencyPayment(_ l: AppLanguage) -> String { l == .fr ? "Devise & Paiement" : "Currency & Payment" }
    static func payment(_ l: AppLanguage) -> String { l == .fr ? "Paiement" : "Payment" }
    static func blockchainNone(_ l: AppLanguage) -> String { l == .fr ? "Aucune" : "None" }
    static func accountingConversion(_ l: AppLanguage) -> String { l == .fr ? "Conversion comptable" : "Accounting conversion" }
    static func accountingCurrency(_ l: AppLanguage) -> String { l == .fr ? "Devise comptable" : "Accounting currency" }
    static func exchangeRate(_ l: AppLanguage) -> String { l == .fr ? "Taux de conversion" : "Exchange rate" }
    static func accountingTotal(_ l: AppLanguage) -> String { l == .fr ? "Total comptable" : "Accounting total" }
    static func exchangeRatePrefix(_ l: AppLanguage, source: String) -> String { "1 \(source) =" }
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
    /// Taux de TVA formaté selon le format de nombre (« 5,5 % » / « 5.5% »).
    static func vatRateLabel(_ l: AppLanguage, rate: Decimal) -> String {
        let value = rate.formattedDecimal(maxFractionDigits: 2, for: l)
        return l == .fr ? "\(value) %" : "\(value)%"
    }
    static func totalHTLabel(_ l: AppLanguage) -> String { l == .fr ? "Total HT" : "Subtotal" }
    static func totalTTCLabel(_ l: AppLanguage) -> String { l == .fr ? "Total TTC" : "Total" }
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
    // Ces deux phrases s'accordent avec le nom qu'elles contiennent (« une
    // facture » vs « un devis », « an invoice » vs « a quote ») : on écrit donc
    // chaque phrase en entier au lieu d'interpoler le type dans un gabarit.
    static func noDocuments(_ l: AppLanguage, type: DocumentType) -> String {
        switch type {
        case .facture: return l == .fr ? "Aucune facture" : "No invoices"
        case .devis: return l == .fr ? "Aucun devis" : "No quotes"
        }
    }

    static func clickToCreate(_ l: AppLanguage, type: DocumentType) -> String {
        switch type {
        case .facture: return l == .fr ? "Cliquez sur + pour créer une facture." : "Click + to create an invoice."
        case .devis: return l == .fr ? "Cliquez sur + pour créer un devis." : "Click + to create a quote."
        }
    }
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
    // MARK: - Cycle de vie
    //
    // Chaque transition est un bouton nommé, plus une valeur dans un menu
    // déroulant : le statut pilote le CA, le retard et les encaissements, il ne
    // peut pas rester une cellule de formulaire au même poids que « Langue ».
    static func actionSend(_ l: AppLanguage) -> String { l == .fr ? "Envoyer" : "Send" }
    static func actionMarkPaid(_ l: AppLanguage) -> String { l == .fr ? "Marquer payée" : "Mark as paid" }
    static func actionRecordDeposit(_ l: AppLanguage) -> String { l == .fr ? "Enregistrer un acompte" : "Record a part-payment" }
    static func actionRemind(_ l: AppLanguage) -> String { l == .fr ? "Relancer" : "Send a reminder" }
    static func actionCancelDocument(_ l: AppLanguage) -> String { l == .fr ? "Annuler le document" : "Cancel document" }
    static func actionReopen(_ l: AppLanguage) -> String { l == .fr ? "Rouvrir" : "Reopen" }

    static func statusChangedToast(_ l: AppLanguage, status: String) -> String {
        l == .fr ? "Statut : \(status)" : "Status: \(status)"
    }

    /// La numérotation continue est une obligation légale en France, et le
    /// numéro était éditable à deux endroits du même écran sans aucun contrôle.
    static func duplicateNumberError(_ l: AppLanguage) -> String {
        l == .fr ? "Ce numéro est déjà utilisé par un autre document." : "This number is already used by another document."
    }
    // MARK: - Conformité
    //
    // Le panneau n'affichait QUE les contrôles en échec, toujours avec la
    // pastille vide : il était une liste de reproches, jamais une confirmation.
    // Et quand tout était correct il disparaissait — au-dessus de 1120 pt, avec
    // toute la colonne inspecteur — donc le seul retour pour avoir corrigé une
    // erreur était un saut de mise en page.
    static func issuerReady(_ l: AppLanguage) -> String {
        l == .fr ? "Mentions de l'émetteur" : "Issuer's legal details"
    }
    static func missingIssuerHint(_ l: AppLanguage) -> String {
        l == .fr
            ? "Nom, adresse et SIRET sont obligatoires sur une facture française."
            : "Name, address and SIRET are mandatory on a French invoice."
    }
    static func documentReadyToSend(_ l: AppLanguage) -> String {
        l == .fr ? "Prêt à envoyer" : "Ready to send"
    }
    static func readinessProgress(_ l: AppLanguage, remaining: Int, total: Int) -> String {
        l == .fr ? "\(remaining) à corriger sur \(total)" : "\(remaining) of \(total) to fix"
    }
    static func inspectorToggle(_ l: AppLanguage) -> String {
        l == .fr ? "Conformité" : "Compliance"
    }
}
