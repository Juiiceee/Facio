import Foundation
import Observation

/// Mode confidentialité : masque tous les montants affichés à l'écran (remplacés
/// par `••••`) tant qu'il est actif. Bascule via l'icône œil de la barre d'outils.
///
/// État global injecté dans l'environnement (comme `ToastCenter`) et **persisté**
/// (`UserDefaults`) pour survivre aux redémarrages. N'affecte JAMAIS le PDF exporté
/// (la vraie facture) : seul l'affichage de l'app est masqué.
@Observable
@MainActor
final class PrivacyMode {
    static let placeholder = "••••"
    private static let storageKey = "facio_hide_amounts"

    var hideAmounts: Bool {
        didSet { UserDefaults.standard.set(hideAmounts, forKey: Self.storageKey) }
    }

    init() {
        hideAmounts = UserDefaults.standard.bool(forKey: Self.storageKey)
    }

    func toggle() {
        hideAmounts.toggle()
    }

    /// Point de formatage unique : le montant formaté, ou le masque si la
    /// confidentialité est active.
    func format(_ amount: Decimal, _ currency: CurrencyType, lang: AppLanguage) -> String {
        hideAmounts ? Self.placeholder : currency.formatAccounting(amount, lang: lang)
    }
}
