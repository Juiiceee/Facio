import CryptoKit
import Foundation

/// Empreinte du code de verrouillage de l'app.
///
/// Le code lui-même n'est **jamais** stocké : on ne conserve qu'un dérivé
/// PBKDF2-HMAC-SHA256 et son sel aléatoire (un sel par installation, régénéré à
/// chaque changement de code). Cette empreinte vit dans le trousseau
/// (`AppLockStore`) et n'est jamais synchronisée vers Supabase.
struct AppLockCredential: Codable, Equatable, Sendable {
    let salt: Data
    let hash: Data
    let iterations: Int
    /// Longueur du code — nécessaire pour dessiner les cases de saisie et pour
    /// valider à la volée. Ne révèle rien d'exploitable (l'app n'accepte que
    /// deux longueurs).
    let length: Int
}

/// Erreurs de saisie d'un code — toutes traduites côté vue.
enum AppLockCodeError: Error, Equatable {
    /// Longueur hors des valeurs autorisées.
    case invalidLength
    /// Le code contient autre chose que des chiffres.
    case nonDigit
    /// La confirmation ne correspond pas au code saisi.
    case mismatch
    /// Le code actuel fourni est faux (changement / suppression).
    case wrongCurrentCode
    /// Le trousseau a refusé l'écriture ou la lecture.
    case storageFailed
}

/// Règles et dérivation cryptographique du code de verrouillage.
///
/// Type pur (aucun état, aucun acteur) : c'est le point unique testé par la
/// suite de régression, la vue et le service ne font que l'appeler.
enum AppLockCode {
    /// Longueurs proposées à la création. Deux choix suffisent : la saisie est
    /// à cases fixes, donc la longueur doit rester lisible d'un coup d'œil.
    static let allowedLengths = [4, 6]
    static let defaultLength = 6

    /// Coût de dérivation. Un code à 4-6 chiffres a une entropie très faible :
    /// le seul rempart contre une attaque hors-ligne (empreinte extraite du
    /// trousseau) est le coût par essai. ~150 k itérations ≈ quelques centaines
    /// de ms sur un Mac récent, imperceptible pour un déverrouillage unique.
    static let derivationIterations = 150_000

    private static let saltByteCount = 32

    // MARK: - Validation

    static func validate(_ code: String) throws {
        guard code.allSatisfy(\.isNumber) else { throw AppLockCodeError.nonDigit }
        guard allowedLengths.contains(code.count) else { throw AppLockCodeError.invalidLength }
    }

    /// Code trivialement devinable : chiffre répété (0000) ou suite de chiffres
    /// consécutifs, croissante ou décroissante (1234, 9876). Non bloquant —
    /// l'app affiche un simple avertissement, elle n'impose pas de politique.
    static func isWeak(_ code: String) -> Bool {
        let digits = code.compactMap { $0.wholeNumberValue }
        guard digits.count == code.count, digits.count > 1 else { return false }

        let deltas = zip(digits, digits.dropFirst()).map { $1 - $0 }
        return deltas.allSatisfy { $0 == 0 } || deltas.allSatisfy { $0 == 1 } || deltas.allSatisfy { $0 == -1 }
    }

    // MARK: - Dérivation

    /// Crée l'empreinte d'un code valide. `iterations` n'est explicite que pour
    /// la suite de régression (le défaut est la seule valeur utilisée en vrai).
    static func makeCredential(code: String, iterations: Int = derivationIterations) throws -> AppLockCredential {
        try validate(code)
        var saltBytes = [UInt8](repeating: 0, count: saltByteCount)
        for index in saltBytes.indices {
            saltBytes[index] = UInt8.random(in: .min ... .max)
        }
        let salt = Data(saltBytes)
        return AppLockCredential(
            salt: salt,
            hash: derive(code: code, salt: salt, iterations: iterations),
            iterations: iterations,
            length: code.count
        )
    }

    /// Vérifie un code contre une empreinte, en temps constant.
    static func verify(_ code: String, against credential: AppLockCredential) -> Bool {
        let candidate = derive(code: code, salt: credential.salt, iterations: credential.iterations)
        return constantTimeEquals(candidate, credential.hash)
    }

    /// PBKDF2-HMAC-SHA256, longueur de sortie = 32 octets (= taille du bloc
    /// SHA-256), donc un seul bloc `T1` : le compteur big-endian INT(1) est
    /// concaténé au sel, puis les `c` itérations sont XORées entre elles.
    private static func derive(code: String, salt: Data, iterations: Int) -> Data {
        let key = SymmetricKey(data: Data(code.utf8))

        var seed = salt
        seed.append(contentsOf: [0, 0, 0, 1])

        var u = Data(HMAC<SHA256>.authenticationCode(for: seed, using: key))
        var result = u
        for _ in 1 ..< max(1, iterations) {
            u = Data(HMAC<SHA256>.authenticationCode(for: u, using: key))
            for index in result.indices {
                result[index] ^= u[index]
            }
        }
        return result
    }

    /// Comparaison sans court-circuit : le temps de réponse ne doit pas fuiter
    /// le nombre d'octets corrects.
    private static func constantTimeEquals(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var difference: UInt8 = 0
        for (left, right) in zip(lhs, rhs) {
            difference |= left ^ right
        }
        return difference == 0
    }
}

/// Délai d'inactivité avant re-verrouillage automatique.
/// La valeur brute est le délai en minutes (0 = jamais).
enum AutoLockDelay: Int, CaseIterable, Identifiable, Sendable {
    case never = 0
    case oneMinute = 1
    case fiveMinutes = 5
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60

    var id: Int { rawValue }

    /// Délai en secondes, ou `nil` si le verrouillage par inactivité est coupé.
    var interval: TimeInterval? {
        self == .never ? nil : TimeInterval(rawValue * 60)
    }

    func label(for l: AppLanguage) -> String {
        switch self {
        case .never: return L10n.autoLockNever(l)
        case .oneMinute: return L10n.autoLockMinutes(l, minutes: 1)
        case .fiveMinutes: return L10n.autoLockMinutes(l, minutes: 5)
        case .fifteenMinutes: return L10n.autoLockMinutes(l, minutes: 15)
        case .thirtyMinutes: return L10n.autoLockMinutes(l, minutes: 30)
        case .oneHour: return L10n.autoLockOneHour(l)
        }
    }
}

/// Politique de verrouillage : anti-force-brute et inactivité.
enum AppLockPolicy {
    /// Nombre d'essais ratés tolérés avant la première temporisation.
    static let attemptsBeforeLockout = 5
    /// Première temporisation, doublée à chaque essai raté suivant.
    static let baseLockoutDuration: TimeInterval = 30
    /// Plafond : au-delà, la temporisation n'augmente plus (on ne veut pas
    /// enfermer l'utilisateur légitime pour une demi-journée).
    static let maxLockoutDuration: TimeInterval = 300

    /// Durée d'attente imposée après `failedAttempts` essais ratés,
    /// ou `nil` tant que le seuil n'est pas atteint.
    static func lockoutDuration(failedAttempts: Int) -> TimeInterval? {
        let excess = failedAttempts - attemptsBeforeLockout
        guard excess >= 0 else { return nil }
        // Plafonne l'exposant avant le calcul : au-delà, `pow` explose pour rien.
        let steps = min(excess, 8)
        let duration = baseLockoutDuration * pow(2, Double(steps))
        return min(duration, maxLockoutDuration)
    }

    /// Essais restants avant la prochaine temporisation (0 = déjà temporisé).
    static func remainingAttempts(failedAttempts: Int) -> Int {
        max(0, attemptsBeforeLockout - failedAttempts)
    }

    /// L'app doit-elle se reverrouiller après `idle` secondes sans interaction ?
    static func shouldAutoLock(idle: TimeInterval, delay: AutoLockDelay) -> Bool {
        guard let interval = delay.interval else { return false }
        return idle >= interval
    }
}
