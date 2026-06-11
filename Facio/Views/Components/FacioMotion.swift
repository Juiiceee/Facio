import SwiftUI

/// Vocabulaire de motion de Facio — sobre et fermé.
///
/// Règle d'or : aucune `.animation()` nue ni durée magique dans les vues.
/// Toute animation passe par un de ces tokens et est attachée à une `value:`
/// précise (jamais d'animation implicite globale — certains écrans vivent
/// dans une TimelineView à la seconde).
///
/// Respect de l'accessibilité : les vues qui animent lisent
/// `@Environment(\.accessibilityReduceMotion)` et passent `nil` quand il est
/// actif (helper `FacioMotion.respecting(_:reduceMotion:)`).
///
/// Exclusions volontaires (anti-gadget) : scroll des listes, transitions de
/// navigation, compteurs KPI animés, apparition des états vides.
enum FacioMotion {
    /// Retour de survol (fonds, bordures) — quasi instantané.
    static let hover: Animation = .easeOut(duration: 0.12)
    /// Changement d'état local (drop zone, bascule d'inspecteur).
    static let state: Animation = .snappy(duration: 0.18)
    /// Apparition/disparition d'un élément ponctuel (undo bar, bannière).
    static let emphasis: Animation = .spring(response: 0.32, dampingFraction: 0.86)

    /// Glissement depuis le haut (bannières, undo bar).
    static var slideIn: AnyTransition { .move(edge: .top).combined(with: .opacity) }
    /// Glissement depuis le bas (toasts).
    static var slideUp: AnyTransition { .move(edge: .bottom).combined(with: .opacity) }

    /// Annule l'animation quand « Réduire les animations » est actif.
    static func respecting(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}
