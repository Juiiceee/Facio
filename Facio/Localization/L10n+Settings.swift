import Foundation

// MARK: - Parametres (tous les onglets)

extension L10n {

    // Onglets
    static func settings(_ l: AppLanguage) -> String { l == .fr ? "Parametres" : "Settings" }
    static func settingsCompany(_ l: AppLanguage) -> String { l == .fr ? "Entreprise" : "Company" }
    static func settingsPayment(_ l: AppLanguage) -> String { l == .fr ? "Paiement" : "Payment" }
    static func settingsDefaults(_ l: AppLanguage) -> String { l == .fr ? "Valeurs par defaut" : "Defaults" }
    static func settingsServices(_ l: AppLanguage) -> String { l == .fr ? "Prestations" : "Services" }
    static func settingsSync(_ l: AppLanguage) -> String { l == .fr ? "Synchronisation" : "Sync" }
    static func settingsAbout(_ l: AppLanguage) -> String { l == .fr ? "A propos" : "About" }
    static func settingsLanguage(_ l: AppLanguage) -> String { l == .fr ? "Langue & Format" : "Language & Format" }
    static func settingsCustomisation(_ l: AppLanguage) -> String { l == .fr ? "Personnalisation" : "Customisation" }

    // Personnalisation
    static func themeColor(_ l: AppLanguage) -> String { l == .fr ? "Couleur du theme" : "Theme color" }
    static func mainColor(_ l: AppLanguage) -> String { l == .fr ? "Couleur principale" : "Main color" }
    static func resetColor(_ l: AppLanguage) -> String { l == .fr ? "Reinitialiser" : "Reset" }
    static func colorPreview(_ l: AppLanguage) -> String { l == .fr ? "Apercu" : "Preview" }
    static func colorHeader(_ l: AppLanguage) -> String { l == .fr ? "En-tete" : "Header" }
    static func colorSections(_ l: AppLanguage) -> String { l == .fr ? "Sections" : "Sections" }
    static func colorAlternating(_ l: AppLanguage) -> String { l == .fr ? "Alternance" : "Alternating" }

    // Entreprise
    static func identity(_ l: AppLanguage) -> String { l == .fr ? "Identite" : "Identity" }
    static func companyName(_ l: AppLanguage) -> String { l == .fr ? "Nom de l'entreprise" : "Company name" }
    static func postalAddress(_ l: AppLanguage) -> String { l == .fr ? "Adresse postale" : "Postal address" }
    static func chooseAnotherFile(_ l: AppLanguage) -> String { l == .fr ? "Choisir un autre fichier..." : "Choose another file..." }
    static func deleteLogo(_ l: AppLanguage) -> String { l == .fr ? "Supprimer le logo" : "Delete logo" }
    static func dragImageHere(_ l: AppLanguage) -> String { l == .fr ? "Glissez une image ici" : "Drag an image here" }
    static func chooseFile(_ l: AppLanguage) -> String { l == .fr ? "Choisir un fichier..." : "Choose a file..." }

    // Paiement
    static func fiatPayment(_ l: AppLanguage) -> String { l == .fr ? "Paiement Fiat" : "Fiat payment" }
    static func bankName(_ l: AppLanguage) -> String { l == .fr ? "Nom de la banque" : "Bank name" }
    static func bankNamePlaceholder(_ l: AppLanguage) -> String { l == .fr ? "Ex: Boursorama, BNP, Revolut..." : "Ex: Chase, Wise, Revolut..." }
    static func accountHolderLabel(_ l: AppLanguage) -> String { l == .fr ? "Titulaire du compte" : "Account holder" }
    static func accountHolderPlaceholder(_ l: AppLanguage) -> String { l == .fr ? "Nom du titulaire" : "Account holder name" }
    static func cryptoWallets(_ l: AppLanguage) -> String { l == .fr ? "Wallets Crypto" : "Crypto wallets" }
    static func noWalletConfiguredShort(_ l: AppLanguage) -> String { l == .fr ? "Aucun wallet configure" : "No wallet configured" }
    static func addWallet(_ l: AppLanguage) -> String { l == .fr ? "Ajouter un wallet" : "Add wallet" }

    // Valeurs par defaut
    static func vatRate(_ l: AppLanguage) -> String { l == .fr ? "Taux de TVA" : "VAT rate" }
    static func defaultRate(_ l: AppLanguage) -> String { l == .fr ? "Taux par defaut" : "Default rate" }
    static func currency(_ l: AppLanguage) -> String { l == .fr ? "Devise" : "Currency" }
    static func defaultCurrency(_ l: AppLanguage) -> String { l == .fr ? "Devise par defaut" : "Default currency" }
    static func defaultBlockchain(_ l: AppLanguage) -> String { l == .fr ? "Blockchain par defaut" : "Default blockchain" }
    static func paymentDelay(_ l: AppLanguage) -> String { l == .fr ? "Delai de paiement" : "Payment delay" }
    static func defaultDelay(_ l: AppLanguage) -> String { l == .fr ? "Delai par defaut" : "Default delay" }
    static func days(_ l: AppLanguage, count: Int) -> String { l == .fr ? "\(count) jours" : "\(count) days" }

    // Prestations
    static func servicesInfo(_ l: AppLanguage) -> String {
        l == .fr ? "Configurez vos prestations habituelles pour les ajouter en un clic lors de la creation de factures et devis."
        : "Configure your usual services to add them with one click when creating invoices and quotes."
    }
    static func favoriteServices(_ l: AppLanguage) -> String { l == .fr ? "Prestations favorites" : "Favorite services" }
    static func noServiceConfigured(_ l: AppLanguage) -> String { l == .fr ? "Aucune prestation configuree" : "No service configured" }
    static func addService(_ l: AppLanguage) -> String { l == .fr ? "Ajouter une prestation" : "Add service" }

    // Langue & Format
    static func defaultLanguage(_ l: AppLanguage) -> String { l == .fr ? "Langue par defaut" : "Default language" }
    static func defaultLanguageHint(_ l: AppLanguage) -> String { l == .fr ? "Langue utilisee pour les nouveaux documents" : "Language used for new documents" }
    static func dateFormat(_ l: AppLanguage) -> String { l == .fr ? "Format de date" : "Date format" }
    static func numberFormat(_ l: AppLanguage) -> String { l == .fr ? "Format des nombres" : "Number format" }

    // Synchronisation
    static func cloudSync(_ l: AppLanguage) -> String { l == .fr ? "Synchronisation cloud" : "Cloud sync" }
    static func enableOnlineBackup(_ l: AppLanguage) -> String { l == .fr ? "Activer la sauvegarde en ligne" : "Enable online backup" }
    static func syncDescription(_ l: AppLanguage) -> String {
        l == .fr ? "Vos donnees sont synchronisees dans le cloud. Creez un compte ou connectez-vous pour activer la sync."
        : "Your data is synced to the cloud. Create an account or sign in to enable sync."
    }
    static func account(_ l: AppLanguage) -> String { l == .fr ? "Compte" : "Account" }
    static func connected(_ l: AppLanguage, email: String) -> String { l == .fr ? "Connecte — \(email)" : "Connected — \(email)" }
    static func signOut(_ l: AppLanguage) -> String { l == .fr ? "Deconnexion" : "Sign out" }
    static func otpSent(_ l: AppLanguage, email: String) -> String { l == .fr ? "Un code a 6 chiffres a ete envoye a **\(email)**" : "A 6-digit code was sent to **\(email)**" }
    static func verificationCode(_ l: AppLanguage) -> String { l == .fr ? "Code de verification" : "Verification code" }
    static func verify(_ l: AppLanguage) -> String { l == .fr ? "Verifier" : "Verify" }
    static func resendCode(_ l: AppLanguage) -> String { l == .fr ? "Renvoyer le code" : "Resend code" }
    static func verifying(_ l: AppLanguage) -> String { l == .fr ? "Verification..." : "Verifying..." }
    static func emailLoginPrompt(_ l: AppLanguage) -> String { l == .fr ? "Entrez votre email pour recevoir un code de connexion." : "Enter your email to receive a login code." }
    static func receiveCode(_ l: AppLanguage) -> String { l == .fr ? "Recevoir un code" : "Receive code" }
    static func sendingCode(_ l: AppLanguage) -> String { l == .fr ? "Envoi du code..." : "Sending code..." }
    static func syncStatus(_ l: AppLanguage) -> String { l == .fr ? "Statut" : "Status" }
    static func syncing(_ l: AppLanguage) -> String { l == .fr ? "Synchronisation..." : "Syncing..." }
    static func lastSync(_ l: AppLanguage) -> String { l == .fr ? "Derniere sync" : "Last sync" }
    static func synchronize(_ l: AppLanguage) -> String { l == .fr ? "Synchroniser" : "Synchronize" }
    static func pushAll(_ l: AppLanguage) -> String { l == .fr ? "Tout pousser" : "Push all" }
    static func advanced(_ l: AppLanguage) -> String { l == .fr ? "Avance" : "Advanced" }
    static func useOwnSupabase(_ l: AppLanguage) -> String { l == .fr ? "Utiliser ma propre base Supabase" : "Use my own Supabase database" }
    static func supabaseURL(_ l: AppLanguage) -> String { "URL Supabase" }
    static func apiKeyAnon(_ l: AppLanguage) -> String { l == .fr ? "Cle API (anon)" : "API key (anon)" }
    static func apiKey(_ l: AppLanguage) -> String { l == .fr ? "Cle API" : "API key" }
    static func sqlSchema(_ l: AppLanguage) -> String { l == .fr ? "Schema SQL pour votre base" : "SQL schema for your database" }
    static func copySQL(_ l: AppLanguage) -> String { l == .fr ? "Copier le SQL" : "Copy SQL" }

    // A propos
    static func professionalInvoices(_ l: AppLanguage) -> String { l == .fr ? "Factures & devis professionnels" : "Professional invoices & quotes" }
    static func links(_ l: AppLanguage) -> String { l == .fr ? "Liens" : "Links" }
    static func sourceCode(_ l: AppLanguage) -> String { l == .fr ? "Code source" : "Source code" }
    static func releases(_ l: AppLanguage) -> String { "Releases" }
    static func reportBug(_ l: AppLanguage) -> String { l == .fr ? "Signaler un bug" : "Report a bug" }
    static func dangerZone(_ l: AppLanguage) -> String { l == .fr ? "Zone dangereuse" : "Danger zone" }
    static func reset(_ l: AppLanguage) -> String { l == .fr ? "Reinitialiser" : "Reset" }
    static func resetHelp(_ l: AppLanguage) -> String { l == .fr ? "Supprime toutes les donnees et remet Facio a zero" : "Deletes all data and resets Facio" }
    static func uninstall(_ l: AppLanguage) -> String { l == .fr ? "Desinstaller" : "Uninstall" }
    static func uninstallHelp(_ l: AppLanguage) -> String { l == .fr ? "Supprime toutes les donnees et ferme l'application" : "Deletes all data and closes the application" }
    static func resetDone(_ l: AppLanguage) -> String { l == .fr ? "Reinitialisation effectuee. Relancez Facio." : "Reset complete. Restart Facio." }
    static func irreversibleWarning(_ l: AppLanguage) -> String {
        l == .fr ? "Ces actions sont irreversibles. Assurez-vous d'avoir exporte vos documents importants."
        : "These actions are irreversible. Make sure you have exported your important documents."
    }
    static func resetConfirmTitle(_ l: AppLanguage) -> String { l == .fr ? "Reinitialiser Facio ?" : "Reset Facio?" }
    static func resetConfirmMessage(_ l: AppLanguage) -> String {
        l == .fr ? "Toutes vos donnees seront supprimees (factures, devis, clients, parametres). Cette action est irreversible."
        : "All your data will be deleted (invoices, quotes, clients, settings). This action is irreversible."
    }
    static func uninstallConfirmTitle(_ l: AppLanguage) -> String { l == .fr ? "Desinstaller Facio ?" : "Uninstall Facio?" }
    static func uninstallConfirmMessage(_ l: AppLanguage) -> String {
        l == .fr ? "L'application sera fermee et toutes les donnees locales seront supprimees. Vous devrez supprimer Facio.app manuellement."
        : "The application will be closed and all local data will be deleted. You will need to delete Facio.app manually."
    }

    // Mises a jour
    static func checkForUpdates(_ l: AppLanguage) -> String { l == .fr ? "Verifier les mises a jour" : "Check for updates" }
    static func updateAvailable(_ l: AppLanguage, version: String) -> String { l == .fr ? "Version \(version) disponible" : "Version \(version) available" }
    static func upToDate(_ l: AppLanguage) -> String { l == .fr ? "Vous etes a jour" : "You're up to date" }
}
