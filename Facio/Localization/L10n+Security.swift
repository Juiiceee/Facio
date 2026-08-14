import Foundation

// MARK: - Verrouillage de l'app (code d'accès)

extension L10n {

    // Onglet réglages
    static func settingsSecurity(_ l: AppLanguage) -> String { l == .fr ? "Sécurité" : "Security" }
    static func settingsSecurityHelp(_ l: AppLanguage) -> String {
        l == .fr ? "Code d'accès à l'application et re-verrouillage automatique." :
        "App passcode and automatic re-locking."
    }

    // MARK: Écran de verrouillage

    static func appLockedTitle(_ l: AppLanguage) -> String { l == .fr ? "Facio est verrouillé" : "Facio is locked" }
    static func appLockedSubtitle(_ l: AppLanguage, digits: Int) -> String {
        l == .fr ? "Saisissez votre code à \(digits) chiffres pour continuer." :
        "Enter your \(digits)-digit passcode to continue."
    }
    static func unlockWithBiometrics(_ l: AppLanguage) -> String {
        l == .fr ? "Déverrouiller avec Touch ID" : "Unlock with Touch ID"
    }
    static func biometricsReason(_ l: AppLanguage) -> String {
        l == .fr ? "Déverrouiller Facio" : "Unlock Facio"
    }
    static func wrongCode(_ l: AppLanguage) -> String { l == .fr ? "Code incorrect" : "Wrong passcode" }
    static func attemptsRemaining(_ l: AppLanguage, count: Int) -> String {
        if l == .fr {
            return count == 1 ? "Encore 1 essai avant blocage" : "Encore \(count) essais avant blocage"
        }
        return count == 1 ? "1 attempt left before lockout" : "\(count) attempts left before lockout"
    }
    static func lockedOutRetryIn(_ l: AppLanguage, delay: String) -> String {
        l == .fr ? "Saisie bloquée — réessayez dans \(delay)" : "Entry locked — try again in \(delay)"
    }

    /// La règle COMPLÈTE, annoncée dès le premier refus : l'utilisateur
    /// légitime qui hésite était puni sans jamais avoir été prévenu, et le
    /// compteur d'essais restants disparaissait après le premier blocage alors
    /// que la sanction suivante, elle, doublait.
    static func lockoutRule(_ l: AppLanguage, steps: String) -> String {
        l == .fr
            ? "Après \(AppLockPolicy.attemptsBeforeLockout) essais, la saisie se bloque \(steps)."
            : "After \(AppLockPolicy.attemptsBeforeLockout) attempts, entry locks for \(steps)."
    }

    // MARK: - Écran de verrouillage
    static func lockedSubtitle(_ l: AppLanguage) -> String {
        l == .fr ? "Facio est verrouillé" : "Facio is locked"
    }
    /// Sur Mac, la frappe clavier est le geste réel de tout le monde : rien ne
    /// l'indiquait, et taper une lettre était avalé en silence.
    static func typeOnKeyboard(_ l: AppLanguage) -> String {
        l == .fr ? "tapez au clavier" : "type on your keyboard"
    }
    static func codeProgress(_ l: AppLanguage, entered: Int, total: Int) -> String {
        l == .fr ? "\(entered) chiffre\(entered > 1 ? "s" : "") sur \(total)" : "\(entered) of \(total) digits"
    }
    static func showKeypad(_ l: AppLanguage) -> String {
        l == .fr ? "Afficher le pavé numérique" : "Show the keypad"
    }
    static func hideKeypad(_ l: AppLanguage) -> String {
        l == .fr ? "Masquer le pavé numérique" : "Hide the keypad"
    }
    static func orEnterCode(_ l: AppLanguage) -> String {
        l == .fr ? "ou saisissez votre code" : "or enter your passcode"
    }
    static func biometricsUnavailableShort(_ l: AppLanguage) -> String {
        l == .fr ? "Touch ID indisponible" : "Touch ID unavailable"
    }
    static func forgotCode(_ l: AppLanguage) -> String { l == .fr ? "Code oublié ?" : "Forgot your passcode?" }
    static func forgotCodeExplanation(_ l: AppLanguage) -> String {
        l == .fr ?
        "Aucun contournement n'existe dans l'app. Pour retrouver l'accès, ouvrez « Trousseaux d'accès », cherchez « com.facio.applock » et supprimez l'élément : macOS demandera votre mot de passe de session. Vos factures, clients et heures restent intacts." :
        "There is no bypass inside the app. To regain access, open Keychain Access, search for “com.facio.applock” and delete the item: macOS will ask for your login password. Your invoices, clients, and hours stay intact."
    }
    static func deleteDigit(_ l: AppLanguage) -> String { l == .fr ? "Effacer" : "Delete" }

    // Trousseau illisible : on ignore s'il existe un code, donc on reste fermé.
    static func lockStoreUnavailableTitle(_ l: AppLanguage) -> String {
        l == .fr ? "Trousseau illisible" : "Keychain unreadable"
    }
    static func lockStoreUnavailableMessage(_ l: AppLanguage) -> String {
        l == .fr ?
        "Facio n'a pas pu lire le code d'accès sur ce Mac, et ne peut donc pas savoir s'il en existe un. Par précaution, l'app reste fermée. Vos factures, clients et heures sont intacts." :
        "Facio could not read the passcode on this Mac, so it cannot tell whether one exists. It stays closed as a precaution. Your invoices, clients, and hours are intact."
    }
    static func retry(_ l: AppLanguage) -> String { l == .fr ? "Réessayer" : "Try again" }

    // MARK: Réglages — code

    static func appLockSection(_ l: AppLanguage) -> String { l == .fr ? "Code d'accès" : "Passcode" }
    static func appLockOn(_ l: AppLanguage) -> String { l == .fr ? "Code actif" : "Passcode on" }
    static func appLockOff(_ l: AppLanguage) -> String { l == .fr ? "Aucun code configuré" : "No passcode set" }
    static func appLockDescription(_ l: AppLanguage) -> String {
        l == .fr ?
        "Facio demande ce code à chaque ouverture. Tant que l'app reste ouverte, vous n'avez rien à ressaisir." :
        "Facio asks for this passcode every time it opens. While the app stays open, you never retype it."
    }
    static func createCode(_ l: AppLanguage) -> String { l == .fr ? "Créer un code" : "Create passcode" }
    static func changeCode(_ l: AppLanguage) -> String { l == .fr ? "Modifier le code" : "Change passcode" }
    static func removeCode(_ l: AppLanguage) -> String { l == .fr ? "Supprimer le code" : "Remove passcode" }
    static func lockNow(_ l: AppLanguage) -> String { l == .fr ? "Verrouiller maintenant" : "Lock now" }
    static func appLockSecurityNote(_ l: AppLanguage) -> String {
        l == .fr ?
        "Le code n'est jamais enregistré en clair : seule son empreinte (PBKDF2-HMAC-SHA256, sel aléatoire) est gardée dans le trousseau de ce Mac, et elle n'est jamais synchronisée." :
        "The passcode is never stored in clear text: only its fingerprint (PBKDF2-HMAC-SHA256 with a random salt) is kept in this Mac's Keychain, and it is never synced."
    }

    // MARK: Réglages — verrouillage automatique

    static func autoLockSection(_ l: AppLanguage) -> String { l == .fr ? "Verrouillage automatique" : "Automatic locking" }
    static func autoLockDelayLabel(_ l: AppLanguage) -> String { l == .fr ? "Après inactivité" : "After inactivity" }
    static func autoLockNever(_ l: AppLanguage) -> String { l == .fr ? "Jamais" : "Never" }
    static func autoLockMinutes(_ l: AppLanguage, minutes: Int) -> String {
        l == .fr ? "\(minutes) min" : "\(minutes) min"
    }
    static func autoLockOneHour(_ l: AppLanguage) -> String { l == .fr ? "1 heure" : "1 hour" }
    static func autoLockHint(_ l: AppLanguage) -> String {
        l == .fr ?
        "Facio se reverrouille aussi dès que le Mac se met en veille ou que l'économiseur d'écran démarre." :
        "Facio also re-locks as soon as the Mac sleeps or the screen saver starts."
    }
    static func lockOnBackgroundLabel(_ l: AppLanguage) -> String {
        l == .fr ? "Verrouiller quand Facio passe en arrière-plan" : "Lock when Facio goes to the background"
    }
    static func lockOnBackgroundHint(_ l: AppLanguage) -> String {
        l == .fr ?
        "Le code est redemandé dès que vous basculez sur une autre app. Sûr, mais exigeant au quotidien." :
        "The passcode is required again as soon as you switch to another app. Safe, but demanding day to day."
    }

    // MARK: Réglages — essais répétés

    static func bruteForceSection(_ l: AppLanguage) -> String {
        l == .fr ? "Essais répétés" : "Repeated attempts"
    }
    static func bruteForceExplanation(_ l: AppLanguage, attempts: Int) -> String {
        l == .fr ?
        "Après \(attempts) codes erronés, Facio impose une attente qui s'allonge à chaque nouvel échec. Le compteur repart à zéro dès qu'un code correct est saisi, et l'attente en cours survit à un redémarrage de l'app." :
        "After \(attempts) wrong passcodes, Facio enforces a wait that grows with every further failure. The counter resets as soon as a correct passcode is entered, and a pending wait survives an app restart."
    }
    static func bruteForceFailureNumber(_ l: AppLanguage, number: Int) -> String {
        l == .fr ? "Échec n° \(number)" : "Failure #\(number)"
    }
    static func bruteForceFailureNumberAndBeyond(_ l: AppLanguage, number: Int) -> String {
        l == .fr ? "Échec n° \(number) et suivants" : "Failure #\(number) and beyond"
    }
    static func bruteForceStatusClear(_ l: AppLanguage) -> String {
        l == .fr ? "Aucun échec récent." : "No recent failure."
    }
    static func bruteForceStatusFailures(_ l: AppLanguage, failures: Int, remaining: Int) -> String {
        if l == .fr {
            let f = failures == 1 ? "1 échec" : "\(failures) échecs"
            let r = remaining == 1 ? "1 essai" : "\(remaining) essais"
            return "\(f) — encore \(r) avant la première attente."
        }
        let f = failures == 1 ? "1 failure" : "\(failures) failures"
        let r = remaining == 1 ? "1 attempt" : "\(remaining) attempts"
        return "\(f) — \(r) left before the first wait."
    }
    static func bruteForceStatusWaiting(_ l: AppLanguage, delay: String) -> String {
        l == .fr ? "Attente en cours : \(delay)." : "Wait in progress: \(delay)."
    }

    // MARK: Réglages — Touch ID

    static func biometricsSection(_ l: AppLanguage) -> String { l == .fr ? "Touch ID" : "Touch ID" }
    static func biometricsToggle(_ l: AppLanguage) -> String {
        l == .fr ? "Proposer Touch ID sur l'écran de verrouillage" : "Offer Touch ID on the lock screen"
    }
    static func biometricsUnavailable(_ l: AppLanguage) -> String {
        l == .fr ? "Touch ID n'est pas disponible sur ce Mac." : "Touch ID isn't available on this Mac."
    }

    // MARK: Feuilles de saisie

    static func codeStepCurrent(_ l: AppLanguage) -> String { l == .fr ? "Code actuel" : "Current passcode" }
    static func codeStepNew(_ l: AppLanguage) -> String { l == .fr ? "Nouveau code" : "New passcode" }
    static func codeStepConfirm(_ l: AppLanguage) -> String { l == .fr ? "Confirmez le code" : "Confirm the passcode" }
    static func codeLengthLabel(_ l: AppLanguage) -> String { l == .fr ? "Longueur" : "Length" }
    static func codeLengthDigits(_ l: AppLanguage, digits: Int) -> String {
        l == .fr ? "\(digits) chiffres" : "\(digits) digits"
    }
    static func codeMismatch(_ l: AppLanguage) -> String {
        l == .fr ? "Les deux codes ne correspondent pas." : "The two passcodes don't match."
    }
    static func codeWrongCurrent(_ l: AppLanguage) -> String {
        l == .fr ? "Code actuel incorrect." : "Wrong current passcode."
    }
    static func codeInvalidLength(_ l: AppLanguage) -> String {
        l == .fr ? "Le code doit faire 4 ou 6 chiffres." : "The passcode must be 4 or 6 digits."
    }
    static func codeNonDigit(_ l: AppLanguage) -> String {
        l == .fr ? "Le code ne peut contenir que des chiffres." : "The passcode can only contain digits."
    }
    static func codeWeakWarning(_ l: AppLanguage) -> String {
        l == .fr ? "Ce code est facile à deviner (chiffres répétés ou qui se suivent)." :
        "This passcode is easy to guess (repeated or consecutive digits)."
    }
    static func codeStorageFailed(_ l: AppLanguage) -> String {
        l == .fr ? "Impossible d'enregistrer le code dans le trousseau." :
        "Could not store the passcode in the Keychain."
    }
    static func removeCodeConfirmTitle(_ l: AppLanguage) -> String {
        l == .fr ? "Supprimer le code d'accès ?" : "Remove the passcode?"
    }
    static func removeCodeConfirmMessage(_ l: AppLanguage) -> String {
        l == .fr ? "Facio s'ouvrira sans rien demander, pour n'importe qui ayant accès à ce Mac." :
        "Facio will open without asking anything, for anyone with access to this Mac."
    }

    // Toasts
    static func toastCodeCreated(_ l: AppLanguage) -> String { l == .fr ? "Code d'accès activé" : "Passcode enabled" }
    static func toastCodeChanged(_ l: AppLanguage) -> String { l == .fr ? "Code d'accès modifié" : "Passcode changed" }
    static func toastCodeRemoved(_ l: AppLanguage) -> String { l == .fr ? "Code d'accès supprimé" : "Passcode removed" }
    static func settingsLockedMessage(_ l: AppLanguage) -> String {
        l == .fr
            ? "Saisissez votre code dans la fenêtre principale de Facio pour retrouver les réglages."
            : "Enter your passcode in the main Facio window to reach settings again."
    }
}
