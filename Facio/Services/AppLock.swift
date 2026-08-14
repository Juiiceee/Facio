import AppKit
import Foundation
import LocalAuthentication
import Observation
import Security

/// Verrouillage de l'app par code.
///
/// Modèle : l'app démarre **verrouillée** dès qu'un code existe, reste
/// déverrouillée tant qu'elle tourne, et se reverrouille sur inactivité, veille
/// du Mac, passage en arrière-plan (optionnel) ou demande explicite (⌃⌘L).
///
/// C'est une **barrière d'accès à l'interface**, pas un chiffrement de données :
/// les fichiers sur disque sont déjà chiffrés indépendamment par
/// `SecurePersistence` avec une clé du trousseau. Le code n'ouvre ni ne ferme
/// ce chiffrement — il empêche simplement d'ouvrir Facio.
///
/// État global injecté dans l'environnement (comme `PrivacyMode`) : réglages
/// dans `UserDefaults`, empreinte du code dans le trousseau (`AppLockStore`).
@Observable
@MainActor
final class AppLock {
    private enum Keys {
        static let autoLock = "facio_lock_autolock_minutes"
        static let lockOnBackground = "facio_lock_on_background"
        static let biometrics = "facio_lock_biometrics"
        static let failedAttempts = "facio_lock_failed_attempts"
        static let lockoutUntil = "facio_lock_lockout_until"
    }

    /// Empreinte du code courant, `nil` si le verrouillage est désactivé.
    private(set) var credential: AppLockCredential?
    private(set) var isLocked = false
    private(set) var failedAttempts: Int
    private(set) var lockedOutUntil: Date?
    /// Vrai pendant la dérivation PBKDF2 (quelques centaines de ms) : la vue
    /// désactive la saisie pour éviter deux vérifications concurrentes.
    private(set) var isVerifying = false
    /// Dernière erreur de trousseau, affichée dans les réglages.
    private(set) var storageError: String?
    /// Le trousseau n'a pas pu être lu : on ne sait donc PAS s'il existe un
    /// code. Distinct de « aucun code » — voir `init`.
    private(set) var storeUnavailable = false

    var autoLockDelay: AutoLockDelay {
        didSet {
            UserDefaults.standard.set(autoLockDelay.rawValue, forKey: Keys.autoLock)
            noteActivity()
        }
    }

    var lockOnBackground: Bool {
        didSet { UserDefaults.standard.set(lockOnBackground, forKey: Keys.lockOnBackground) }
    }

    var useBiometrics: Bool {
        didSet { UserDefaults.standard.set(useBiometrics, forKey: Keys.biometrics) }
    }

    /// Pas de la boucle de veille. Assez fin pour que « 1 minute » veuille dire
    /// 1 minute, assez lâche pour ne rien coûter.
    private static let idleCheckInterval: TimeInterval = 10

    private var lastActivity = Date()
    private var activityMonitor: Any?
    private var observers: [NSObjectProtocol] = []

    /// Un code est-il configuré ?
    var isEnabled: Bool { credential != nil }

    /// Touch ID est-il disponible **et** activé pour le déverrouillage ?
    var canUseBiometrics: Bool { useBiometrics && Self.biometricsAvailable }

    /// La machine sait-elle faire du Touch ID ? (Faux sur un Mac sans capteur,
    /// ou sur un binaire non signé auquel le système refuse LocalAuthentication.)
    static var biometricsAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    init() {
        let defaults = UserDefaults.standard
        // `object(forKey:)` et pas `integer(forKey:)` : la valeur par défaut au
        // premier lancement doit être 5 min, pas 0 (= jamais).
        let storedDelay = defaults.object(forKey: Keys.autoLock) as? Int
        autoLockDelay = storedDelay.flatMap(AutoLockDelay.init(rawValue:)) ?? .fiveMinutes
        lockOnBackground = defaults.bool(forKey: Keys.lockOnBackground)
        useBiometrics = defaults.object(forKey: Keys.biometrics) as? Bool ?? true
        failedAttempts = defaults.integer(forKey: Keys.failedAttempts)
        // La temporisation survit au redémarrage : sinon relancer l'app remet
        // le compteur d'essais à zéro et annule l'anti-force-brute.
        if let until = defaults.object(forKey: Keys.lockoutUntil) as? Date, until > Date() {
            lockedOutUntil = until
        }

        loadCredential()
    }

    /// Lit l'empreinte du trousseau et en déduit l'état de départ.
    ///
    /// `load()` a trois issues et elles ne doivent pas être confondues :
    /// une empreinte (code configuré), `nil` (aucun code), ou une erreur —
    /// trousseau refusé, verrouillé, charge corrompue. Dans ce dernier cas on
    /// ne sait pas s'il existe un code : traiter « inconnu » comme « aucun »
    /// ouvrirait l'app en grand sur une erreur passagère, et inviterait
    /// l'utilisateur à « créer un code » par-dessus celui qu'il possède encore.
    /// Une barrière d'accès se ferme sur le doute.
    private func loadCredential() {
        do {
            credential = try AppLockStore.load()
            storeUnavailable = false
            storageError = nil
        } catch {
            credential = nil
            storeUnavailable = true
            storageError = error.localizedDescription
        }
        isLocked = credential != nil || storeUnavailable
    }

    /// Nouvelle tentative de lecture, offerte sur l'écran de verrouillage quand
    /// le trousseau était indisponible (refus ponctuel, session pas encore
    /// déverrouillée…). Déverrouille si le trousseau s'avère finalement vide.
    func retryLoadingCredential() {
        loadCredential()
        if !storeUnavailable, credential == nil {
            isLocked = false
        }
    }

    // MARK: - Cycle de vie

    /// Branche la surveillance (inactivité, veille, arrière-plan). Appelé une
    /// fois depuis la scène principale — pas dans `init`, qui ne doit pas
    /// toucher à AppKit.
    func start() {
        guard observers.isEmpty else { return }

        let workspace = NSWorkspace.shared.notificationCenter
        // Veille écran / session utilisateur quittée : le Mac est de toute façon
        // protégé, on reverrouille Facio derrière lui.
        for name in [NSWorkspace.screensDidSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            observers.append(workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.lockNow() }
            })
        }
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.handleResignActive() }
            }
        )

        // Moniteur local : ne reçoit que les événements destinés à Facio, donc
        // « inactif » veut bien dire « personne n'utilise Facio ».
        activityMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel, .mouseMoved]
        ) { [weak self] event in
            // Les moniteurs locaux sont toujours délivrés sur le thread principal.
            MainActor.assumeIsolated { self?.lastActivity = Date() }
            return event
        }

        // Boucle de veille : s'arrête d'elle-même si le service disparaît
        // (il vit en pratique aussi longtemps que l'app).
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.idleCheckInterval))
                guard let self else { return }
                self.evaluateIdle()
            }
        }
    }

    // MARK: - Verrouillage

    func noteActivity() {
        lastActivity = Date()
    }

    func lockNow() {
        guard isEnabled else { return }
        isLocked = true
    }

    private func handleResignActive() {
        guard lockOnBackground else { return }
        lockNow()
    }

    private func evaluateIdle() {
        guard isEnabled, !isLocked else { return }
        guard AppLockPolicy.shouldAutoLock(idle: Date().timeIntervalSince(lastActivity), delay: autoLockDelay) else { return }
        lockNow()
    }

    // MARK: - Déverrouillage

    /// Temps restant de temporisation à l'instant `date` (0 si aucune).
    func remainingLockout(at date: Date = Date()) -> TimeInterval {
        guard let lockedOutUntil else { return 0 }
        return max(0, lockedOutUntil.timeIntervalSince(date))
    }

    var isRateLimited: Bool { remainingLockout() > 0 }

    /// Vérifie le code saisi et déverrouille si besoin.
    /// Retourne `false` sur code faux **ou** pendant une temporisation.
    @discardableResult
    func unlock(with code: String) async -> Bool {
        // Trousseau illisible : il n'y a rien à comparer, donc aucun code ne
        // peut ouvrir. Sans ce garde, `credential == nil` déverrouillerait sur
        // n'importe quelle saisie.
        guard !storeUnavailable else { return false }
        guard let credential else {
            isLocked = false
            return true
        }
        guard !isRateLimited, !isVerifying else { return false }

        isVerifying = true
        let matches = await Self.verify(code: code, against: credential)
        isVerifying = false

        if matches {
            clearFailures()
            isLocked = false
            noteActivity()
        } else {
            registerFailure()
        }
        return matches
    }

    /// Déverrouillage Touch ID. Retourne `false` si l'utilisateur annule, si le
    /// capteur échoue, ou si la biométrie n'est pas disponible.
    @discardableResult
    func unlockWithBiometrics(reason: String) async -> Bool {
        guard isEnabled, canUseBiometrics, !isRateLimited else { return false }
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else { return false }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            guard success else { return false }
            // Touch ID ne compte pas comme un essai raté et ne consomme pas le
            // quota : c'est l'utilisateur du Mac qui vient de s'authentifier.
            clearFailures()
            isLocked = false
            noteActivity()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Gestion du code

    /// Définit le premier code (ou remplace celui en place après vérification
    /// par `changeCode`). Laisse l'app déverrouillée.
    func setCode(_ code: String, confirmation: String) async throws {
        try AppLockCode.validate(code)
        guard code == confirmation else { throw AppLockCodeError.mismatch }

        let newCredential = await Self.makeCredential(code: code)
        guard let newCredential else { throw AppLockCodeError.storageFailed }

        do {
            try AppLockStore.save(newCredential)
        } catch {
            storageError = error.localizedDescription
            throw AppLockCodeError.storageFailed
        }

        storageError = nil
        credential = newCredential
        clearFailures()
        isLocked = false
        noteActivity()
    }

    func changeCode(current: String, new: String, confirmation: String) async throws {
        try await requireCurrentCode(current)
        try await setCode(new, confirmation: confirmation)
    }

    func removeCode(current: String) async throws {
        try await requireCurrentCode(current)
        do {
            try AppLockStore.delete()
        } catch {
            storageError = error.localizedDescription
            throw AppLockCodeError.storageFailed
        }
        storageError = nil
        credential = nil
        clearFailures()
        isLocked = false
    }

    /// Contrôle le code actuel **sans** toucher à l'état de verrouillage, pour
    /// laisser les réglages valider une étape avant de demander la suivante.
    /// Un échec consomme un essai, comme sur l'écran de verrouillage.
    func matchesCurrentCode(_ current: String) async -> Bool {
        guard let credential else { return true }
        guard !isRateLimited, !isVerifying else { return false }

        isVerifying = true
        let matches = await Self.verify(code: current, against: credential)
        isVerifying = false

        if matches {
            clearFailures()
        } else {
            registerFailure()
        }
        return matches
    }

    private func requireCurrentCode(_ current: String) async throws {
        guard credential != nil else { return }
        guard await matchesCurrentCode(current) else { throw AppLockCodeError.wrongCurrentCode }
    }

    // MARK: - Anti-force-brute

    private func registerFailure() {
        failedAttempts += 1
        UserDefaults.standard.set(failedAttempts, forKey: Keys.failedAttempts)

        if let duration = AppLockPolicy.lockoutDuration(failedAttempts: failedAttempts) {
            let until = Date().addingTimeInterval(duration)
            lockedOutUntil = until
            UserDefaults.standard.set(until, forKey: Keys.lockoutUntil)
        }
    }

    private func clearFailures() {
        failedAttempts = 0
        lockedOutUntil = nil
        UserDefaults.standard.removeObject(forKey: Keys.failedAttempts)
        UserDefaults.standard.removeObject(forKey: Keys.lockoutUntil)
    }

    // MARK: - Dérivation hors du thread principal
    //
    // PBKDF2 à 150 k itérations bloque ~200-400 ms : hors du main actor, sinon
    // l'interface gèle pendant la vérification.

    private static func verify(code: String, against credential: AppLockCredential) async -> Bool {
        await Task.detached(priority: .userInitiated) {
            AppLockCode.verify(code, against: credential)
        }.value
    }

    private static func makeCredential(code: String) async -> AppLockCredential? {
        await Task.detached(priority: .userInitiated) {
            try? AppLockCode.makeCredential(code: code)
        }.value
    }
}

/// Stockage trousseau de l'empreinte du code.
///
/// Service dédié (`com.facio.applock`) et **pas** celui de `KeychainService` :
/// se déconnecter de la synchronisation appelle `KeychainService.deleteAll()`,
/// qui viderait tout le service d'auth — le code de verrouillage ne doit pas
/// disparaître avec une déconnexion cloud.
enum AppLockStore {
    private static let service = "com.facio.applock"
    private static let account = "lockCredential.v1"

    #if DEBUG
    // Même raison que `KeychainService` : en build non signé, le trousseau
    // redemande l'autorisation à chaque lancement.
    private static let devKey = "applock.lockCredential.v1"
    #endif

    enum StoreError: LocalizedError {
        case corruptedPayload
        case keychainStatus(OSStatus)

        var errorDescription: String? {
            switch self {
            case .corruptedPayload: "The stored app lock passcode is unreadable."
            case .keychainStatus(let status): "Keychain operation failed with status \(status)."
            }
        }
    }

    static func load() throws -> AppLockCredential? {
        guard let data = try rawData() else { return nil }
        guard let credential = try? JSONDecoder().decode(AppLockCredential.self, from: data) else {
            throw StoreError.corruptedPayload
        }
        return credential
    }

    static func save(_ credential: AppLockCredential) throws {
        let data = try JSONEncoder().encode(credential)
        #if DEBUG
        DevSecretStore.set(data, for: devKey)
        #else
        var query = baseQuery()
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else { throw StoreError.keychainStatus(updateStatus) }

        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw StoreError.keychainStatus(addStatus) }
        #endif
    }

    static func delete() throws {
        #if DEBUG
        DevSecretStore.delete(devKey)
        #else
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StoreError.keychainStatus(status)
        }
        #endif
    }

    private static func rawData() throws -> Data? {
        #if DEBUG
        return DevSecretStore.data(for: devKey)
        #else
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw StoreError.keychainStatus(status) }
        guard let data = item as? Data else { throw StoreError.corruptedPayload }
        return data
        #endif
    }

    private static func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
