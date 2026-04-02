import Foundation

// MARK: - Langue de l'application

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case fr = "fr"
    case en = "en"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fr: return "Francais"
        case .en: return "English"
        }
    }
}

// MARK: - Traductions centralisees

struct L10n {

    // MARK: - PDF — Titre & Dates

    static func invoiceDate(_ l: AppLanguage) -> String {
        l == .fr ? "Date de facture: " : "Invoice date: "
    }

    static func quoteDate(_ l: AppLanguage) -> String {
        l == .fr ? "Date du devis: " : "Quote date: "
    }

    static func dueDate(_ l: AppLanguage) -> String {
        l == .fr ? "Echeance: " : "Due date: "
    }

    static func recipient(_ l: AppLanguage) -> String {
        l == .fr ? "DESTINATAIRE" : "RECIPIENT"
    }

    // MARK: - PDF — Tableau

    static func designation(_ l: AppLanguage) -> String {
        l == .fr ? "DESIGNATION" : "DESCRIPTION"
    }

    static func quantity(_ l: AppLanguage) -> String {
        l == .fr ? "QUANTITE" : "QUANTITY"
    }

    static func price(_ l: AppLanguage) -> String {
        l == .fr ? "PRIX" : "PRICE"
    }

    static func total(_ l: AppLanguage) -> String {
        "TOTAL"
    }

    static func vat(_ l: AppLanguage) -> String {
        l == .fr ? "TVA" : "VAT"
    }

    // MARK: - PDF — Totaux

    static func totalHT(_ l: AppLanguage) -> String {
        l == .fr ? "Total HT" : "Subtotal"
    }

    static func totalVAT(_ l: AppLanguage) -> String {
        l == .fr ? "TVA" : "VAT"
    }

    static func vatRate(_ l: AppLanguage, rate: String) -> String {
        l == .fr ? "TVA \(rate)%" : "VAT \(rate)%"
    }

    static func totalTVA(_ l: AppLanguage) -> String {
        l == .fr ? "Total TVA" : "Total VAT"
    }

    static func totalTTC(_ l: AppLanguage) -> String {
        l == .fr ? "Total TTC" : "Total incl. tax"
    }

    // MARK: - PDF — Paiement

    static func paymentProofs(_ l: AppLanguage) -> String {
        l == .fr ? "PREUVES DE PAIEMENT" : "PAYMENT PROOFS"
    }

    static func txPrefix(_ l: AppLanguage) -> String { "TX: " }

    static func bankTransfer(_ l: AppLanguage) -> String {
        l == .fr ? "Virement bancaire" : "Bank transfer"
    }

    static func cryptoTransfer(_ l: AppLanguage) -> String {
        l == .fr ? "Transfert Cryptomonnaie" : "Cryptocurrency transfer"
    }

    static func walletAddress(_ l: AppLanguage) -> String {
        l == .fr ? "Wallet adresse:" : "Wallet address:"
    }

    static func accountHolder(_ l: AppLanguage) -> String {
        l == .fr ? "Titulaire: " : "Holder: "
    }

    static func companyFallback(_ l: AppLanguage) -> String {
        l == .fr ? "ENTREPRISE" : "COMPANY"
    }

    // MARK: - Enums — DocumentType

    static func invoice(_ l: AppLanguage) -> String {
        l == .fr ? "Facture" : "Invoice"
    }

    static func quote(_ l: AppLanguage) -> String {
        l == .fr ? "Devis" : "Quote"
    }

    // MARK: - Enums — DocumentStatus

    static func draft(_ l: AppLanguage) -> String {
        l == .fr ? "Brouillon" : "Draft"
    }

    static func sent(_ l: AppLanguage) -> String {
        l == .fr ? "Envoyee" : "Sent"
    }

    static func paid(_ l: AppLanguage) -> String {
        l == .fr ? "Payee" : "Paid"
    }

    static func cancelled(_ l: AppLanguage) -> String {
        l == .fr ? "Annulee" : "Cancelled"
    }

    // MARK: - Enums — PaymentMode

    static func paymentNone(_ l: AppLanguage) -> String {
        l == .fr ? "Aucun" : "None"
    }

    static func paymentTransfer(_ l: AppLanguage) -> String {
        l == .fr ? "Virement" : "Transfer"
    }

    static func paymentCrypto(_ l: AppLanguage) -> String { "Crypto" }

    // MARK: - Enums — Jours

    static func weekdayLabel(_ day: Int, _ l: AppLanguage) -> String {
        let fr = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        let en = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return l == .fr ? fr[day] : en[day]
    }

    static func weekdayShort(_ day: Int, _ l: AppLanguage) -> String {
        let fr = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
        let en = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return l == .fr ? fr[day] : en[day]
    }

    // MARK: - UI — Sidebar

    static func sidebarInvoices(_ l: AppLanguage) -> String {
        l == .fr ? "Factures" : "Invoices"
    }

    static func sidebarQuotes(_ l: AppLanguage) -> String {
        l == .fr ? "Devis" : "Quotes"
    }

    static func sidebarClients(_ l: AppLanguage) -> String { "Clients" }

    static func sidebarTimeTracking(_ l: AppLanguage) -> String {
        l == .fr ? "Suivi des heures" : "Time tracking"
    }

    static func sidebarDashboard(_ l: AppLanguage) -> String {
        l == .fr ? "Tableau de bord" : "Dashboard"
    }

    static func sidebarSettings(_ l: AppLanguage) -> String {
        l == .fr ? "Parametres" : "Settings"
    }

    static func sidebarDocuments(_ l: AppLanguage) -> String { "Documents" }

    static func sidebarManagement(_ l: AppLanguage) -> String {
        l == .fr ? "Gestion" : "Management"
    }

    // MARK: - UI — DocumentEditor

    static func newDocument(_ l: AppLanguage) -> String {
        l == .fr ? "Nouveau document" : "New document"
    }

    static func duplicate(_ l: AppLanguage) -> String {
        l == .fr ? "Dupliquer" : "Duplicate"
    }

    static func preview(_ l: AppLanguage) -> String {
        l == .fr ? "Apercu" : "Preview"
    }

    static func exportPDF(_ l: AppLanguage) -> String {
        l == .fr ? "Exporter PDF" : "Export PDF"
    }

    static func headerSection(_ l: AppLanguage) -> String {
        l == .fr ? "En-tete" : "Header"
    }

    static func type(_ l: AppLanguage) -> String { "Type" }

    static func number(_ l: AppLanguage) -> String {
        l == .fr ? "Numero" : "Number"
    }

    static func status(_ l: AppLanguage) -> String {
        l == .fr ? "Statut" : "Status"
    }

    static func language(_ l: AppLanguage) -> String {
        l == .fr ? "Langue" : "Language"
    }

    static func datesSection(_ l: AppLanguage) -> String { "Dates" }

    static func creationDate(_ l: AppLanguage) -> String {
        l == .fr ? "Date de creation" : "Creation date"
    }

    static func dueDateLabel(_ l: AppLanguage) -> String {
        l == .fr ? "Date d'echeance" : "Due date"
    }

    static func currencyPayment(_ l: AppLanguage) -> String {
        l == .fr ? "Devise & Paiement" : "Currency & Payment"
    }

    static func payment(_ l: AppLanguage) -> String {
        l == .fr ? "Paiement" : "Payment"
    }

    static func blockchain(_ l: AppLanguage) -> String { "Blockchain" }

    static func blockchainNone(_ l: AppLanguage) -> String {
        l == .fr ? "Aucune" : "None"
    }

    static func recipientSection(_ l: AppLanguage) -> String {
        l == .fr ? "DESTINATAIRE" : "RECIPIENT"
    }

    static func clientInfo(_ l: AppLanguage) -> String {
        l == .fr ? "Informations client" : "Client information"
    }

    static func clientBook(_ l: AppLanguage) -> String {
        l == .fr ? "Carnet de clients" : "Client directory"
    }

    static func name(_ l: AppLanguage) -> String {
        l == .fr ? "Nom" : "Name"
    }

    static func clientName(_ l: AppLanguage) -> String {
        l == .fr ? "Nom du client" : "Client name"
    }

    static func address(_ l: AppLanguage) -> String {
        l == .fr ? "Adresse" : "Address"
    }

    static func postalCode(_ l: AppLanguage) -> String {
        l == .fr ? "Code postal" : "Postal code"
    }

    static func city(_ l: AppLanguage) -> String {
        l == .fr ? "Ville" : "City"
    }

    static func linesSection(_ l: AppLanguage) -> String {
        l == .fr ? "Lignes" : "Line items"
    }

    static func designationLabel(_ l: AppLanguage) -> String {
        l == .fr ? "Designation" : "Description"
    }

    static func quantityLabel(_ l: AppLanguage) -> String {
        l == .fr ? "Quantite" : "Quantity"
    }

    static func unitPrice(_ l: AppLanguage) -> String {
        l == .fr ? "Prix unitaire" : "Unit price"
    }

    static func vatLabel(_ l: AppLanguage) -> String {
        l == .fr ? "TVA" : "VAT"
    }

    static func totalHTLabel(_ l: AppLanguage) -> String {
        l == .fr ? "Total HT" : "Subtotal"
    }

    static func noLines(_ l: AppLanguage) -> String {
        l == .fr ? "Aucune ligne. Ajoutez-en une ci-dessous." : "No line items. Add one below."
    }

    static func addEmptyLine(_ l: AppLanguage) -> String {
        l == .fr ? "Ajouter une ligne vide" : "Add empty line"
    }

    static func favoriteService(_ l: AppLanguage) -> String {
        l == .fr ? "Prestation favorite" : "Favorite service"
    }

    static func paymentBankSection(_ l: AppLanguage) -> String {
        l == .fr ? "Paiement — Virement bancaire" : "Payment — Bank transfer"
    }

    static func noIBANConfigured(_ l: AppLanguage) -> String {
        l == .fr ? "Aucun IBAN configure (voir Parametres > Paiement)" : "No IBAN configured (see Settings > Payment)"
    }

    static func paymentCryptoSection(_ l: AppLanguage) -> String {
        l == .fr ? "Paiement — Crypto" : "Payment — Crypto"
    }

    static func network(_ l: AppLanguage) -> String {
        l == .fr ? "Reseau" : "Network"
    }

    static func wallet(_ l: AppLanguage) -> String { "Wallet" }

    static func noWalletConfigured(_ l: AppLanguage, chain: String) -> String {
        l == .fr ? "Aucun wallet configure pour \(chain) (voir Parametres > Paiement)" : "No wallet configured for \(chain) (see Settings > Payment)"
    }

    static func selectNetwork(_ l: AppLanguage) -> String {
        l == .fr ? "Selectionnez un reseau dans la section Devise & Paiement" : "Select a network in the Currency & Payment section"
    }

    static func paymentProofsSection(_ l: AppLanguage) -> String {
        l == .fr ? "Preuves de paiement" : "Payment proofs"
    }

    static func addSignature(_ l: AppLanguage) -> String {
        l == .fr ? "Ajouter une signature" : "Add signature"
    }

    static func noSignatures(_ l: AppLanguage) -> String {
        l == .fr ? "Aucune signature enregistree." : "No signatures recorded."
    }

    static func notes(_ l: AppLanguage) -> String { "Notes" }

    static func viewOn(_ l: AppLanguage, explorer: String) -> String {
        l == .fr ? "Voir sur \(explorer)" : "View on \(explorer)"
    }

    // MARK: - UI — Client Picker / Add Signature

    static func selectClient(_ l: AppLanguage) -> String {
        l == .fr ? "Selectionner un client" : "Select a client"
    }

    static func new(_ l: AppLanguage) -> String {
        l == .fr ? "Nouveau" : "New"
    }

    static func close(_ l: AppLanguage) -> String {
        l == .fr ? "Fermer" : "Close"
    }

    static func newClient(_ l: AppLanguage) -> String {
        l == .fr ? "Nouveau client" : "New client"
    }

    static func email(_ l: AppLanguage) -> String { "Email" }

    static func createAndSelect(_ l: AppLanguage) -> String {
        l == .fr ? "Creer et selectionner" : "Create and select"
    }

    static func searchClient(_ l: AppLanguage) -> String {
        l == .fr ? "Rechercher un client" : "Search client"
    }

    static func addPaymentProof(_ l: AppLanguage) -> String {
        l == .fr ? "Ajouter une preuve de paiement" : "Add payment proof"
    }

    static func cancel(_ l: AppLanguage) -> String {
        l == .fr ? "Annuler" : "Cancel"
    }

    static func txHash(_ l: AppLanguage) -> String {
        l == .fr ? "Signature / Hash de transaction" : "Signature / Transaction hash"
    }

    static func amount(_ l: AppLanguage) -> String {
        l == .fr ? "Montant" : "Amount"
    }

    static func date(_ l: AppLanguage) -> String { "Date" }

    static func add(_ l: AppLanguage) -> String {
        l == .fr ? "Ajouter" : "Add"
    }

    // MARK: - UI — DocumentList

    static func delete(_ l: AppLanguage) -> String {
        l == .fr ? "Supprimer" : "Delete"
    }

    static func convertToInvoice(_ l: AppLanguage) -> String {
        l == .fr ? "Convertir en Facture" : "Convert to Invoice"
    }

    static func searchByNumberOrClient(_ l: AppLanguage) -> String {
        l == .fr ? "Rechercher par numero ou client" : "Search by number or client"
    }

    static func noDocuments(_ l: AppLanguage, type: String) -> String {
        l == .fr ? "Aucun \(type)" : "No \(type)"
    }

    static func clickToCreate(_ l: AppLanguage, type: String) -> String {
        l == .fr ? "Cliquez sur + pour creer un \(type)." : "Click + to create a \(type)."
    }

    static func noClient(_ l: AppLanguage) -> String {
        l == .fr ? "Sans client" : "No client"
    }

    // MARK: - UI — ContentView (empty states)

    static func noDocumentSelected(_ l: AppLanguage) -> String {
        l == .fr ? "Aucun document selectionne" : "No document selected"
    }

    static func selectDocumentHint(_ l: AppLanguage) -> String {
        l == .fr ? "Selectionnez un document dans la liste ou creez-en un nouveau avec +" : "Select a document from the list or create a new one with +"
    }

    static func noPeriodSelected(_ l: AppLanguage) -> String {
        l == .fr ? "Aucune periode selectionnee" : "No period selected"
    }

    static func selectPeriodHint(_ l: AppLanguage) -> String {
        l == .fr ? "Selectionnez une periode ou creez-en une avec +" : "Select a period or create one with +"
    }

    static func selectSection(_ l: AppLanguage) -> String {
        l == .fr ? "Selectionnez une section" : "Select a section"
    }

    // MARK: - UI — Dashboard

    static func revenueThisMonth(_ l: AppLanguage) -> String {
        l == .fr ? "CA ce mois" : "Revenue this month"
    }

    static func revenueThisYear(_ l: AppLanguage) -> String {
        l == .fr ? "CA cette annee" : "Revenue this year"
    }

    static func pending(_ l: AppLanguage) -> String {
        l == .fr ? "En attente" : "Pending"
    }

    static func pendingInvoices(_ l: AppLanguage, count: Int) -> String {
        l == .fr ? "\(count) facture(s)" : "\(count) invoice(s)"
    }

    static func quotesInProgress(_ l: AppLanguage) -> String {
        l == .fr ? "Devis en cours" : "Quotes in progress"
    }

    static func latestInvoices(_ l: AppLanguage) -> String {
        l == .fr ? "Dernieres factures" : "Latest invoices"
    }

    static func noInvoicesYet(_ l: AppLanguage) -> String {
        l == .fr ? "Aucune facture pour le moment." : "No invoices yet."
    }

    static func latestQuotes(_ l: AppLanguage) -> String {
        l == .fr ? "Derniers devis" : "Latest quotes"
    }

    static func noQuotesYet(_ l: AppLanguage) -> String {
        l == .fr ? "Aucun devis pour le moment." : "No quotes yet."
    }

    static func dashboard(_ l: AppLanguage) -> String {
        l == .fr ? "Tableau de bord" : "Dashboard"
    }

    // MARK: - UI — Timesheet

    static func summary(_ l: AppLanguage) -> String {
        l == .fr ? "Resume" : "Summary"
    }

    static func totalHours(_ l: AppLanguage) -> String {
        l == .fr ? "Total heures" : "Total hours"
    }

    static func normalHours(_ l: AppLanguage) -> String {
        l == .fr ? "Normales" : "Normal"
    }

    static func overtimeHours(_ l: AppLanguage) -> String {
        l == .fr ? "Supplementaires" : "Overtime"
    }

    static func normalCost(_ l: AppLanguage) -> String {
        l == .fr ? "Cout normal" : "Normal cost"
    }

    static func overtimeCost(_ l: AppLanguage) -> String {
        l == .fr ? "Cout sup." : "Overtime cost"
    }

    static func grossTotal(_ l: AppLanguage) -> String {
        l == .fr ? "Total brut" : "Gross total"
    }

    static func netTotal(_ l: AppLanguage) -> String {
        l == .fr ? "Total net" : "Net total"
    }

    static func week(_ l: AppLanguage, number: Int) -> String {
        l == .fr ? "Semaine \(number)" : "Week \(number)"
    }

    static func calculationParams(_ l: AppLanguage) -> String {
        l == .fr ? "Parametres de calcul" : "Calculation parameters"
    }

    static func weeklyThreshold(_ l: AppLanguage) -> String {
        l == .fr ? "Seuil hebdo (h)" : "Weekly threshold (h)"
    }

    static func normalRate(_ l: AppLanguage) -> String {
        l == .fr ? "Taux normal" : "Normal rate"
    }

    static func overtimeRate(_ l: AppLanguage) -> String {
        l == .fr ? "Taux sup." : "Overtime rate"
    }

    static func netCoeff(_ l: AppLanguage) -> String {
        l == .fr ? "Coeff. net" : "Net coeff."
    }

    static func newPeriod(_ l: AppLanguage) -> String {
        l == .fr ? "Nouvelle periode" : "New period"
    }

    static func month(_ l: AppLanguage) -> String {
        l == .fr ? "Mois" : "Month"
    }

    static func year(_ l: AppLanguage) -> String {
        l == .fr ? "Annee" : "Year"
    }

    static func periodExists(_ l: AppLanguage) -> String {
        l == .fr ? "Cette periode existe deja" : "This period already exists"
    }

    static func create(_ l: AppLanguage) -> String {
        l == .fr ? "Creer" : "Create"
    }

    static func noPeriod(_ l: AppLanguage) -> String {
        l == .fr ? "Aucune periode" : "No period"
    }

    static func clickToCreatePeriod(_ l: AppLanguage) -> String {
        l == .fr ? "Cliquez sur + pour creer une nouvelle periode de suivi." : "Click + to create a new tracking period."
    }

    static func generateInvoice(_ l: AppLanguage) -> String {
        l == .fr ? "Generer une facture" : "Generate invoice"
    }

    static func workHours(_ l: AppLanguage) -> String {
        l == .fr ? "Heures de travail" : "Work hours"
    }

    static func overtimeLabel(_ l: AppLanguage) -> String {
        l == .fr ? "Heures supplementaires" : "Overtime hours"
    }

    // MARK: - UI — Clients

    static func noClientSelected(_ l: AppLanguage) -> String {
        l == .fr ? "Aucun client selectionne" : "No client selected"
    }

    static func selectOrCreateClient(_ l: AppLanguage) -> String {
        l == .fr ? "Selectionnez un client ou creez-en un nouveau." : "Select a client or create a new one."
    }

    static func searchClientPrompt(_ l: AppLanguage) -> String {
        l == .fr ? "Rechercher un client..." : "Search client..."
    }

    static func information(_ l: AppLanguage) -> String {
        l == .fr ? "Informations" : "Information"
    }

    // MARK: - UI — Settings

    static func settings(_ l: AppLanguage) -> String {
        l == .fr ? "Parametres" : "Settings"
    }

    static func settingsCompany(_ l: AppLanguage) -> String {
        l == .fr ? "Entreprise" : "Company"
    }

    static func settingsPayment(_ l: AppLanguage) -> String {
        l == .fr ? "Paiement" : "Payment"
    }

    static func settingsDefaults(_ l: AppLanguage) -> String {
        l == .fr ? "Valeurs par defaut" : "Defaults"
    }

    static func settingsServices(_ l: AppLanguage) -> String {
        l == .fr ? "Prestations" : "Services"
    }

    static func settingsSync(_ l: AppLanguage) -> String {
        l == .fr ? "Synchronisation" : "Sync"
    }

    static func settingsAbout(_ l: AppLanguage) -> String {
        l == .fr ? "A propos" : "About"
    }

    static func settingsLanguage(_ l: AppLanguage) -> String {
        l == .fr ? "Langue & Format" : "Language & Format"
    }

    // MARK: - UI — Company Settings

    static func identity(_ l: AppLanguage) -> String {
        l == .fr ? "Identite" : "Identity"
    }

    static func companyName(_ l: AppLanguage) -> String {
        l == .fr ? "Nom de l'entreprise" : "Company name"
    }

    static func postalAddress(_ l: AppLanguage) -> String {
        l == .fr ? "Adresse postale" : "Postal address"
    }

    static func contact(_ l: AppLanguage) -> String { "Contact" }

    static func phone(_ l: AppLanguage) -> String {
        l == .fr ? "Telephone" : "Phone"
    }

    static func logo(_ l: AppLanguage) -> String { "Logo" }

    static func chooseAnotherFile(_ l: AppLanguage) -> String {
        l == .fr ? "Choisir un autre fichier..." : "Choose another file..."
    }

    static func deleteLogo(_ l: AppLanguage) -> String {
        l == .fr ? "Supprimer le logo" : "Delete logo"
    }

    static func dragImageHere(_ l: AppLanguage) -> String {
        l == .fr ? "Glissez une image ici" : "Drag an image here"
    }

    static func chooseFile(_ l: AppLanguage) -> String {
        l == .fr ? "Choisir un fichier..." : "Choose a file..."
    }

    // MARK: - UI — Payment Settings

    static func fiatPayment(_ l: AppLanguage) -> String {
        l == .fr ? "Paiement Fiat" : "Fiat payment"
    }

    static func bankName(_ l: AppLanguage) -> String {
        l == .fr ? "Nom de la banque" : "Bank name"
    }

    static func bankNamePlaceholder(_ l: AppLanguage) -> String {
        l == .fr ? "Ex: Boursorama, BNP, Revolut..." : "Ex: Chase, Wise, Revolut..."
    }

    static func accountHolderLabel(_ l: AppLanguage) -> String {
        l == .fr ? "Titulaire du compte" : "Account holder"
    }

    static func accountHolderPlaceholder(_ l: AppLanguage) -> String {
        l == .fr ? "Nom du titulaire" : "Account holder name"
    }

    static func cryptoWallets(_ l: AppLanguage) -> String {
        l == .fr ? "Wallets Crypto" : "Crypto wallets"
    }

    static func noWalletConfiguredShort(_ l: AppLanguage) -> String {
        l == .fr ? "Aucun wallet configure" : "No wallet configured"
    }

    static func addWallet(_ l: AppLanguage) -> String {
        l == .fr ? "Ajouter un wallet" : "Add wallet"
    }

    // MARK: - UI — Defaults Settings

    static func vatRate(_ l: AppLanguage) -> String {
        l == .fr ? "Taux de TVA" : "VAT rate"
    }

    static func defaultRate(_ l: AppLanguage) -> String {
        l == .fr ? "Taux par defaut" : "Default rate"
    }

    static func currency(_ l: AppLanguage) -> String {
        l == .fr ? "Devise" : "Currency"
    }

    static func defaultCurrency(_ l: AppLanguage) -> String {
        l == .fr ? "Devise par defaut" : "Default currency"
    }

    static func defaultBlockchain(_ l: AppLanguage) -> String {
        l == .fr ? "Blockchain par defaut" : "Default blockchain"
    }

    static func paymentDelay(_ l: AppLanguage) -> String {
        l == .fr ? "Delai de paiement" : "Payment delay"
    }

    static func defaultDelay(_ l: AppLanguage) -> String {
        l == .fr ? "Delai par defaut" : "Default delay"
    }

    static func days(_ l: AppLanguage, count: Int) -> String {
        l == .fr ? "\(count) jours" : "\(count) days"
    }

    // MARK: - UI — Prestations Settings

    static func servicesInfo(_ l: AppLanguage) -> String {
        l == .fr ? "Configurez vos prestations habituelles pour les ajouter en un clic lors de la creation de factures et devis."
        : "Configure your usual services to add them with one click when creating invoices and quotes."
    }

    static func favoriteServices(_ l: AppLanguage) -> String {
        l == .fr ? "Prestations favorites" : "Favorite services"
    }

    static func noServiceConfigured(_ l: AppLanguage) -> String {
        l == .fr ? "Aucune prestation configuree" : "No service configured"
    }

    static func addService(_ l: AppLanguage) -> String {
        l == .fr ? "Ajouter une prestation" : "Add service"
    }

    // MARK: - UI — Sync Settings

    static func cloudSync(_ l: AppLanguage) -> String {
        l == .fr ? "Synchronisation cloud" : "Cloud sync"
    }

    static func enableOnlineBackup(_ l: AppLanguage) -> String {
        l == .fr ? "Activer la sauvegarde en ligne" : "Enable online backup"
    }

    static func syncDescription(_ l: AppLanguage) -> String {
        l == .fr ? "Vos donnees sont synchronisees dans le cloud. Creez un compte ou connectez-vous pour activer la sync."
        : "Your data is synced to the cloud. Create an account or sign in to enable sync."
    }

    static func account(_ l: AppLanguage) -> String {
        l == .fr ? "Compte" : "Account"
    }

    static func connected(_ l: AppLanguage, email: String) -> String {
        l == .fr ? "Connecte — \(email)" : "Connected — \(email)"
    }

    static func signOut(_ l: AppLanguage) -> String {
        l == .fr ? "Deconnexion" : "Sign out"
    }

    static func otpSent(_ l: AppLanguage, email: String) -> String {
        l == .fr ? "Un code a 6 chiffres a ete envoye a **\(email)**" : "A 6-digit code was sent to **\(email)**"
    }

    static func verificationCode(_ l: AppLanguage) -> String {
        l == .fr ? "Code de verification" : "Verification code"
    }

    static func verify(_ l: AppLanguage) -> String {
        l == .fr ? "Verifier" : "Verify"
    }

    static func resendCode(_ l: AppLanguage) -> String {
        l == .fr ? "Renvoyer le code" : "Resend code"
    }

    static func verifying(_ l: AppLanguage) -> String {
        l == .fr ? "Verification..." : "Verifying..."
    }

    static func emailLoginPrompt(_ l: AppLanguage) -> String {
        l == .fr ? "Entrez votre email pour recevoir un code de connexion." : "Enter your email to receive a login code."
    }

    static func receiveCode(_ l: AppLanguage) -> String {
        l == .fr ? "Recevoir un code" : "Receive code"
    }

    static func sendingCode(_ l: AppLanguage) -> String {
        l == .fr ? "Envoi du code..." : "Sending code..."
    }

    static func syncStatus(_ l: AppLanguage) -> String {
        l == .fr ? "Statut" : "Status"
    }

    static func syncing(_ l: AppLanguage) -> String {
        l == .fr ? "Synchronisation..." : "Syncing..."
    }

    static func lastSync(_ l: AppLanguage) -> String {
        l == .fr ? "Derniere sync" : "Last sync"
    }

    static func synchronize(_ l: AppLanguage) -> String {
        l == .fr ? "Synchroniser" : "Synchronize"
    }

    static func pushAll(_ l: AppLanguage) -> String {
        l == .fr ? "Tout pousser" : "Push all"
    }

    static func advanced(_ l: AppLanguage) -> String {
        l == .fr ? "Avance" : "Advanced"
    }

    static func useOwnSupabase(_ l: AppLanguage) -> String {
        l == .fr ? "Utiliser ma propre base Supabase" : "Use my own Supabase database"
    }

    static func supabaseURL(_ l: AppLanguage) -> String { "URL Supabase" }

    static func apiKeyAnon(_ l: AppLanguage) -> String {
        l == .fr ? "Cle API (anon)" : "API key (anon)"
    }

    static func apiKey(_ l: AppLanguage) -> String {
        l == .fr ? "Cle API" : "API key"
    }

    static func sqlSchema(_ l: AppLanguage) -> String {
        l == .fr ? "Schema SQL pour votre base" : "SQL schema for your database"
    }

    static func copySQL(_ l: AppLanguage) -> String {
        l == .fr ? "Copier le SQL" : "Copy SQL"
    }

    // MARK: - UI — About Settings

    static func professionalInvoices(_ l: AppLanguage) -> String {
        l == .fr ? "Factures & devis professionnels" : "Professional invoices & quotes"
    }

    static func links(_ l: AppLanguage) -> String {
        l == .fr ? "Liens" : "Links"
    }

    static func sourceCode(_ l: AppLanguage) -> String {
        l == .fr ? "Code source" : "Source code"
    }

    static func releases(_ l: AppLanguage) -> String { "Releases" }

    static func reportBug(_ l: AppLanguage) -> String {
        l == .fr ? "Signaler un bug" : "Report a bug"
    }

    static func dangerZone(_ l: AppLanguage) -> String {
        l == .fr ? "Zone dangereuse" : "Danger zone"
    }

    static func reset(_ l: AppLanguage) -> String {
        l == .fr ? "Reinitialiser" : "Reset"
    }

    static func resetHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Supprime toutes les donnees et remet Facio a zero" : "Deletes all data and resets Facio"
    }

    static func uninstall(_ l: AppLanguage) -> String {
        l == .fr ? "Desinstaller" : "Uninstall"
    }

    static func uninstallHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Supprime toutes les donnees et ferme l'application" : "Deletes all data and closes the application"
    }

    static func resetDone(_ l: AppLanguage) -> String {
        l == .fr ? "Reinitialisation effectuee. Relancez Facio." : "Reset complete. Restart Facio."
    }

    static func irreversibleWarning(_ l: AppLanguage) -> String {
        l == .fr ? "Ces actions sont irreversibles. Assurez-vous d'avoir exporte vos documents importants."
        : "These actions are irreversible. Make sure you have exported your important documents."
    }

    static func resetConfirmTitle(_ l: AppLanguage) -> String {
        l == .fr ? "Reinitialiser Facio ?" : "Reset Facio?"
    }

    static func resetConfirmMessage(_ l: AppLanguage) -> String {
        l == .fr ? "Toutes vos donnees seront supprimees (factures, devis, clients, parametres). Cette action est irreversible."
        : "All your data will be deleted (invoices, quotes, clients, settings). This action is irreversible."
    }

    static func uninstallConfirmTitle(_ l: AppLanguage) -> String {
        l == .fr ? "Desinstaller Facio ?" : "Uninstall Facio?"
    }

    static func uninstallConfirmMessage(_ l: AppLanguage) -> String {
        l == .fr ? "L'application sera fermee et toutes les donnees locales seront supprimees. Vous devrez supprimer Facio.app manuellement."
        : "The application will be closed and all local data will be deleted. You will need to delete Facio.app manually."
    }

    // MARK: - UI — PDF Preview

    static func previewTitle(_ l: AppLanguage, number: String) -> String {
        l == .fr ? "Aperçu — \(number)" : "Preview — \(number)"
    }

    static func pdfGenerationError(_ l: AppLanguage) -> String {
        l == .fr ? "Erreur de génération" : "Generation error"
    }

    static func cannotGeneratePDF(_ l: AppLanguage) -> String {
        l == .fr ? "Impossible de générer le PDF." : "Could not generate PDF."
    }

    // MARK: - UI — Export

    static func exportDocument(_ l: AppLanguage) -> String {
        l == .fr ? "Exporter le document" : "Export document"
    }

    static func chooseSaveLocation(_ l: AppLanguage) -> String {
        l == .fr ? "Choisissez où sauvegarder le fichier PDF" : "Choose where to save the PDF file"
    }

    // MARK: - Language Settings

    static func defaultLanguage(_ l: AppLanguage) -> String {
        l == .fr ? "Langue par defaut" : "Default language"
    }

    static func defaultLanguageHint(_ l: AppLanguage) -> String {
        l == .fr ? "Langue utilisee pour les nouveaux documents" : "Language used for new documents"
    }

    static func dateFormat(_ l: AppLanguage) -> String {
        l == .fr ? "Format de date" : "Date format"
    }

    static func numberFormat(_ l: AppLanguage) -> String {
        l == .fr ? "Format des nombres" : "Number format"
    }

    static func priceLabel(_ l: AppLanguage) -> String {
        l == .fr ? "Prix" : "Price"
    }

    static func qtyShort(_ l: AppLanguage) -> String {
        l == .fr ? "Qte" : "Qty"
    }
}
