import Foundation

// MARK: - Parametres (tous les onglets)

extension L10n {

    // Onglets
    static func settings(_ l: AppLanguage) -> String { l == .fr ? "Paramètres" : "Settings" }
    static func settingsCompany(_ l: AppLanguage) -> String { l == .fr ? "Entreprise" : "Company" }
    static func settingsPayment(_ l: AppLanguage) -> String { l == .fr ? "Paiement" : "Payment" }
    static func settingsDefaults(_ l: AppLanguage) -> String { l == .fr ? "Valeurs par défaut" : "Defaults" }
    static func settingsServices(_ l: AppLanguage) -> String { l == .fr ? "Prestations" : "Services" }
    static func settingsSync(_ l: AppLanguage) -> String { l == .fr ? "Synchronisation" : "Sync" }
    static func settingsAbout(_ l: AppLanguage) -> String { l == .fr ? "À propos" : "About" }
    static func settingsLanguage(_ l: AppLanguage) -> String { l == .fr ? "Langue & Format" : "Language & Format" }
    static func settingsCustomisation(_ l: AppLanguage) -> String { l == .fr ? "Personnalisation" : "Customisation" }
    static func settingsCompanyHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Identité, coordonnées et informations légales utilisées sur vos documents." :
        "Identity, contact, and legal details used on your documents."
    }
    static func settingsCustomisationHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Logo et couleur d'accent appliqués à l'interface et aux exports." :
        "Logo and accent color applied to the app and exports."
    }
    static func settingsPaymentHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Comptes bancaires et wallets disponibles au moment de facturer." :
        "Bank accounts and wallets available when invoicing."
    }
    static func settingsDefaultsHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Valeurs reprises automatiquement sur les nouveaux documents et périodes." :
        "Defaults reused automatically for new documents and periods."
    }
    static func settingsServicesHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Prestations réutilisables pour saisir les lignes plus vite." :
        "Reusable services for faster line item entry."
    }
    static func settingsLanguageHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Langue, dates et formats numériques par défaut." :
        "Default language, dates, and number formats."
    }
    static func settingsSyncHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Sauvegarde cloud, connexion et synchronisation des données." :
        "Cloud backup, sign-in, and data sync."
    }
    static func settingsAboutHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Version, liens utiles et actions de maintenance." :
        "Version, useful links, and maintenance actions."
    }

    // Personnalisation
    static func themeColor(_ l: AppLanguage) -> String { l == .fr ? "Couleur du thème" : "Theme color" }
    static func mainColor(_ l: AppLanguage) -> String { l == .fr ? "Couleur principale" : "Main color" }
    static func resetColor(_ l: AppLanguage) -> String { l == .fr ? "Réinitialiser" : "Reset" }
    static func colorPreview(_ l: AppLanguage) -> String { l == .fr ? "Aperçu" : "Preview" }
    static func colorHeader(_ l: AppLanguage) -> String { l == .fr ? "En-tête" : "Header" }
    static func colorSections(_ l: AppLanguage) -> String { l == .fr ? "Sections" : "Sections" }
    static func colorAlternating(_ l: AppLanguage) -> String { l == .fr ? "Alternance" : "Alternating" }

    // Entreprise
    static func identity(_ l: AppLanguage) -> String { l == .fr ? "Identité" : "Identity" }
    static func companyName(_ l: AppLanguage) -> String { l == .fr ? "Nom de l'entreprise" : "Company name" }
    static func postalAddress(_ l: AppLanguage) -> String { l == .fr ? "Adresse postale" : "Postal address" }
    static func postalCodePlaceholder(_ l: AppLanguage) -> String { l == .fr ? "54000" : "10001" }
    static func siretPlaceholder(_ l: AppLanguage) -> String { l == .fr ? "000 000 000 00000" : "Company registration number" }
    // Exemple de n° de TVA intracommunautaire français — identique quelle que
    // soit la langue de l'UI (le format ne dépend pas de la langue).
    static func vatNumberPlaceholder(_ l: AppLanguage) -> String { "FR00 000000000" }
    static func phonePlaceholder(_ l: AppLanguage) -> String { l == .fr ? "06 00 00 00 00" : "(555) 010-0000" }
    static func contactEmailPlaceholder(_ l: AppLanguage) -> String { l == .fr ? "contact@entreprise.fr" : "contact@company.com" }
    static func chooseAnotherFile(_ l: AppLanguage) -> String { l == .fr ? "Choisir un autre fichier..." : "Choose another file..." }
    static func deleteLogo(_ l: AppLanguage) -> String { l == .fr ? "Supprimer le logo" : "Delete logo" }
    static func dragImageHere(_ l: AppLanguage) -> String { l == .fr ? "Glissez une image ici" : "Drag an image here" }
    static func chooseFile(_ l: AppLanguage) -> String { l == .fr ? "Choisir un fichier..." : "Choose a file..." }

    // Paiement
    static func fiatPayment(_ l: AppLanguage) -> String { l == .fr ? "Paiement Fiat" : "Fiat payment" }
    static func bankAccounts(_ l: AppLanguage) -> String { l == .fr ? "Comptes bancaires" : "Bank accounts" }
    static func bankAccount(_ l: AppLanguage) -> String { l == .fr ? "Compte bancaire" : "Bank account" }
    static func noBankAccountConfiguredShort(_ l: AppLanguage) -> String { l == .fr ? "Aucun compte bancaire configuré" : "No bank account configured" }
    static func addBankAccount(_ l: AppLanguage) -> String { l == .fr ? "Ajouter un compte bancaire" : "Add bank account" }
    static func bankAccountNamePlaceholder(_ l: AppLanguage) -> String { l == .fr ? "Nom (ex: Pro, Wise EUR...)" : "Name (e.g. Business, Wise EUR...)" }
    static func bankName(_ l: AppLanguage) -> String { l == .fr ? "Nom de la banque" : "Bank name" }
    static func bankNamePlaceholder(_ l: AppLanguage) -> String { l == .fr ? "Ex: Boursorama, BNP, Revolut..." : "Ex: Chase, Wise, Revolut..." }
    static func accountHolderLabel(_ l: AppLanguage) -> String { l == .fr ? "Titulaire du compte" : "Account holder" }
    static func accountHolderPlaceholder(_ l: AppLanguage) -> String { l == .fr ? "Nom du titulaire" : "Account holder name" }
    static func ibanPlaceholder(_ l: AppLanguage) -> String { l == .fr ? "FR76 0000 0000 0000 0000 0000 000" : "Bank account number / IBAN" }
    static func bicPlaceholder(_ l: AppLanguage) -> String { l == .fr ? "BNPAFRPP" : "SWIFT / BIC" }
    static func bankAccountIbanRequired(_ l: AppLanguage) -> String { l == .fr ? "IBAN requis pour utiliser ce compte sur une facture" : "IBAN required before this account can be used on an invoice" }
    static func cryptoWallets(_ l: AppLanguage) -> String { l == .fr ? "Wallets Crypto" : "Crypto wallets" }
    static func noWalletConfiguredShort(_ l: AppLanguage) -> String { l == .fr ? "Aucun wallet configuré" : "No wallet configured" }
    static func addWallet(_ l: AppLanguage) -> String { l == .fr ? "Ajouter un wallet" : "Add wallet" }
    static func walletNamePlaceholder(_ l: AppLanguage) -> String { l == .fr ? "Nom (ex: Phantom, Ledger...)" : "Name (e.g. Phantom, Ledger...)" }
    static func walletAddressPlaceholder(_ l: AppLanguage) -> String { l == .fr ? "Adresse du wallet" : "Wallet address" }
    static func walletAddressRequired(_ l: AppLanguage) -> String { l == .fr ? "Adresse requise pour l'utiliser comme moyen de paiement" : "Address required before this can be used for payment" }

    // Valeurs par defaut
    static func vatRate(_ l: AppLanguage) -> String { l == .fr ? "Taux de TVA" : "VAT rate" }
    static func defaultRate(_ l: AppLanguage) -> String { l == .fr ? "Taux par défaut" : "Default rate" }
    static func currency(_ l: AppLanguage) -> String { l == .fr ? "Devise" : "Currency" }
    static func defaultCurrency(_ l: AppLanguage) -> String { l == .fr ? "Devise par défaut" : "Default currency" }
    static func accountingCurrencySetting(_ l: AppLanguage) -> String { l == .fr ? "Devise comptable" : "Accounting currency" }
    static func defaultBlockchain(_ l: AppLanguage) -> String { l == .fr ? "Blockchain par défaut" : "Default blockchain" }
    static func paymentDelay(_ l: AppLanguage) -> String { l == .fr ? "Délai de paiement" : "Payment delay" }
    static func defaultDelay(_ l: AppLanguage) -> String { l == .fr ? "Délai par défaut" : "Default delay" }
    static func days(_ l: AppLanguage, count: Int) -> String { l == .fr ? "\(count) jours" : "\(count) days" }

    // Prestations
    static func servicesInfo(_ l: AppLanguage) -> String {
        l == .fr ? "Configurez vos prestations habituelles pour les ajouter en un clic lors de la création de factures et devis."
        : "Configure your usual services to add them with one click when creating invoices and quotes."
    }
    static func favoriteServices(_ l: AppLanguage) -> String { l == .fr ? "Prestations favorites" : "Favorite services" }
    static func noServiceConfigured(_ l: AppLanguage) -> String { l == .fr ? "Aucune prestation configurée" : "No service configured" }
    static func addService(_ l: AppLanguage) -> String { l == .fr ? "Ajouter une prestation" : "Add service" }

    // Langue & Format
    static func defaultLanguage(_ l: AppLanguage) -> String { l == .fr ? "Langue par défaut" : "Default language" }
    static func defaultLanguageHint(_ l: AppLanguage) -> String { l == .fr ? "Langue utilisée pour les nouveaux documents" : "Language used for new documents" }
    static func dateFormat(_ l: AppLanguage) -> String { l == .fr ? "Format de date" : "Date format" }
    static func numberFormat(_ l: AppLanguage) -> String { l == .fr ? "Format des nombres" : "Number format" }
    static func frenchDateFormatSample(_ l: AppLanguage) -> String { "dd/MM/yyyy (02/04/2026)" }
    static func englishDateFormatSample(_ l: AppLanguage) -> String { "MM/dd/yyyy (04/02/2026)" }
    static func frenchNumberFormatSample(_ l: AppLanguage) -> String { "1 234,56 (FR)" }
    static func englishNumberFormatSample(_ l: AppLanguage) -> String { "1,234.56 (EN)" }

    // Synchronisation
    static func cloudSync(_ l: AppLanguage) -> String { l == .fr ? "Synchronisation cloud" : "Cloud sync" }
    static func enableOnlineBackup(_ l: AppLanguage) -> String { l == .fr ? "Activer la sauvegarde en ligne" : "Enable online backup" }
    static func syncDescription(_ l: AppLanguage) -> String {
        l == .fr ? "Vos données sont synchronisées dans le cloud. Créez un compte ou connectez-vous pour activer la sync."
        : "Your data is synced to the cloud. Create an account or sign in to enable sync."
    }
    static func account(_ l: AppLanguage) -> String { l == .fr ? "Compte" : "Account" }
    static func connected(_ l: AppLanguage, email: String) -> String { l == .fr ? "Connecté — \(email)" : "Connected — \(email)" }
    static func signOut(_ l: AppLanguage) -> String { l == .fr ? "Déconnexion" : "Sign out" }
    static func otpSent(_ l: AppLanguage, email: String) -> String { l == .fr ? "Un code à 6 chiffres a été envoyé à **\(email)**" : "A 6-digit code was sent to **\(email)**" }
    static func verificationCode(_ l: AppLanguage) -> String { l == .fr ? "Code de vérification" : "Verification code" }
    static func otpCodePlaceholder(_ l: AppLanguage) -> String { l == .fr ? "123456" : "123456" }
    static func verify(_ l: AppLanguage) -> String { l == .fr ? "Vérifier" : "Verify" }
    static func resendCode(_ l: AppLanguage) -> String { l == .fr ? "Renvoyer le code" : "Resend code" }
    static func verifying(_ l: AppLanguage) -> String { l == .fr ? "Vérification..." : "Verifying..." }
    static func emailLoginPrompt(_ l: AppLanguage) -> String { l == .fr ? "Entrez votre email pour recevoir un code de connexion." : "Enter your email to receive a login code." }
    static func emailPlaceholder(_ l: AppLanguage) -> String { l == .fr ? "email@exemple.com" : "email@example.com" }
    static func receiveCode(_ l: AppLanguage) -> String { l == .fr ? "Recevoir un code" : "Receive code" }
    static func sendingCode(_ l: AppLanguage) -> String { l == .fr ? "Envoi du code..." : "Sending code..." }
    static func syncStatus(_ l: AppLanguage) -> String { l == .fr ? "Statut" : "Status" }
    static func syncing(_ l: AppLanguage) -> String { l == .fr ? "Synchronisation..." : "Syncing..." }
    static func lastSync(_ l: AppLanguage) -> String { l == .fr ? "Dernière sync" : "Last sync" }
    static func synchronize(_ l: AppLanguage) -> String { l == .fr ? "Synchroniser" : "Synchronize" }
    static func pushAll(_ l: AppLanguage) -> String { l == .fr ? "Forcer l'envoi" : "Upload all changes" }
    static func advanced(_ l: AppLanguage) -> String { l == .fr ? "Avancé" : "Advanced" }
    static func useOwnSupabase(_ l: AppLanguage) -> String { l == .fr ? "Utiliser ma propre base Supabase" : "Use my own Supabase database" }
    static func supabaseURL(_ l: AppLanguage) -> String { "URL Supabase" }
    static func apiKeyAnon(_ l: AppLanguage) -> String { l == .fr ? "Clé API (anon)" : "API key (anon)" }
    static func apiKey(_ l: AppLanguage) -> String { l == .fr ? "Clé API" : "API key" }
    static func supabaseURLPlaceholder(_ l: AppLanguage) -> String { l == .fr ? "https://xxx.supabase.co" : "https://xxx.supabase.co" }
    static func apiKeyPlaceholder(_ l: AppLanguage) -> String { l == .fr ? "eyJhbG..." : "eyJhbG..." }
    static func sqlSchema(_ l: AppLanguage) -> String { l == .fr ? "Schéma SQL pour votre base" : "SQL schema for your database" }
    static func copySQL(_ l: AppLanguage) -> String { l == .fr ? "Copier le SQL" : "Copy SQL" }
    static func authenticationError(_ l: AppLanguage) -> String {
        l == .fr ? "Connexion impossible" : "Sign-in issue"
    }
    static func synchronizationError(_ l: AppLanguage) -> String {
        l == .fr ? "Synchronisation impossible" : "Sync issue"
    }
    static func showApiKey(_ l: AppLanguage) -> String { l == .fr ? "Afficher la clé API" : "Show API key" }
    static func hideApiKey(_ l: AppLanguage) -> String { l == .fr ? "Masquer la clé API" : "Hide API key" }
    static func removeBankAccount(_ l: AppLanguage) -> String { l == .fr ? "Supprimer ce compte bancaire" : "Remove this bank account" }
    static func removeWallet(_ l: AppLanguage) -> String { l == .fr ? "Supprimer ce wallet" : "Remove this wallet" }
    static func removeService(_ l: AppLanguage) -> String { l == .fr ? "Supprimer cette prestation" : "Remove this service" }
    static func invalidLogoFile(_ l: AppLanguage) -> String {
        l == .fr ? "Logo invalide : utilisez PNG, JPEG ou TIFF, 2 Mo maximum et 4096 px par côté." :
        "Invalid logo: use PNG, JPEG, or TIFF, up to 2 MB and 4096 px per side."
    }

    // A propos
    static func professionalInvoices(_ l: AppLanguage) -> String { l == .fr ? "Factures & devis professionnels" : "Professional invoices & quotes" }
    static func version(_ l: AppLanguage, value: String) -> String { l == .fr ? "Version \(value)" : "Version \(value)" }
    static func links(_ l: AppLanguage) -> String { l == .fr ? "Liens" : "Links" }
    static func sourceCode(_ l: AppLanguage) -> String { l == .fr ? "Code source" : "Source code" }
    static func releases(_ l: AppLanguage) -> String { "Releases" }
    static func reportBug(_ l: AppLanguage) -> String { l == .fr ? "Signaler un bug" : "Report a bug" }
    static func dangerZone(_ l: AppLanguage) -> String { l == .fr ? "Zone dangereuse" : "Danger zone" }
    static func reset(_ l: AppLanguage) -> String { l == .fr ? "Réinitialiser" : "Reset" }
    static func resetHelp(_ l: AppLanguage) -> String { l == .fr ? "Supprime toutes les données et remet Facio à zéro" : "Deletes all data and resets Facio" }
    static func uninstall(_ l: AppLanguage) -> String { l == .fr ? "Désinstaller" : "Uninstall" }
    static func uninstallHelp(_ l: AppLanguage) -> String { l == .fr ? "Supprime toutes les données et ferme l'application" : "Deletes all data and closes the application" }
    static func resetDone(_ l: AppLanguage) -> String { l == .fr ? "Réinitialisation effectuée. Relancez Facio." : "Reset complete. Restart Facio." }
    static func irreversibleWarning(_ l: AppLanguage) -> String {
        l == .fr ? "Ces actions sont irréversibles. Assurez-vous d'avoir exporté vos documents importants."
        : "These actions are irreversible. Make sure you have exported your important documents."
    }
    static func resetConfirmTitle(_ l: AppLanguage) -> String { l == .fr ? "Réinitialiser Facio ?" : "Reset Facio?" }
    static func resetConfirmMessage(_ l: AppLanguage) -> String {
        l == .fr ? "Toutes vos données seront supprimées (factures, devis, clients, paramètres). Cette action est irréversible."
        : "All your data will be deleted (invoices, quotes, clients, settings). This action is irreversible."
    }
    static func uninstallConfirmTitle(_ l: AppLanguage) -> String { l == .fr ? "Désinstaller Facio ?" : "Uninstall Facio?" }
    static func uninstallConfirmMessage(_ l: AppLanguage) -> String {
        l == .fr ? "L'application sera fermée et toutes les données locales seront supprimées. Vous devrez supprimer Facio.app manuellement."
        : "The application will be closed and all local data will be deleted. You will need to delete Facio.app manually."
    }

    // Mises a jour
    static func checkForUpdates(_ l: AppLanguage) -> String { l == .fr ? "Vérifier les mises à jour" : "Check for updates" }
    static func updateAvailable(_ l: AppLanguage, version: String) -> String { l == .fr ? "Version \(version) disponible" : "Version \(version) available" }
    static func upToDate(_ l: AppLanguage) -> String { l == .fr ? "Vous êtes à jour" : "You're up to date" }
    static func updateCheckUnavailable(_ l: AppLanguage) -> String {
        l == .fr ? "Statut de mise à jour indisponible" : "Update status unavailable"
    }
    static func updateCheckFailed(_ l: AppLanguage) -> String {
        l == .fr ? "Impossible de vérifier les mises à jour" : "Could not check for updates"
    }
}
