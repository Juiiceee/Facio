import SwiftUI

/// Échelle typographique gouvernée de Facio.
///
/// Toute taille de texte passe par ces tokens — aucune `.font(.system(size:))`
/// arbitraire dans les vues. Les styles sont adossés aux styles dynamiques
/// d'Apple (Dynamic Type) quand c'est possible, et n'utilisent une taille fixe
/// que pour les grands nombres (KPI, horloge de timer) où la mise à l'échelle
/// casserait l'alignement.
enum FacioFont {
    // MARK: - Titres

    /// Grand titre d'écran (en-tête de page).
    static let screenTitle: Font = .title.weight(.bold)
    /// Sous-titre d'écran sous le titre.
    static let screenSubtitle: Font = .subheadline

    /// Titre de section / de panneau (SectionPanel).
    static let sectionTitle: Font = .headline

    /// Titre d'une sous-section à l'intérieur d'un panneau.
    static let subsectionTitle: Font = .subheadline.weight(.semibold)

    // MARK: - Formulaires

    /// Libellé d'un champ de formulaire (LabeledField).
    static let fieldLabel: Font = .subheadline

    // MARK: - Lignes & listes

    /// Titre d'une ligne de liste.
    static let rowTitle: Font = .subheadline.weight(.medium)
    /// Sous-titre / métadonnée d'une ligne.
    static let rowSubtitle: Font = .caption
    /// Valeur numérique d'une ligne de liste.
    static let rowValue: Font = .subheadline.monospacedDigit()
    /// Métadonnée numérique discrète (compteurs, totaux secondaires).
    static let metaValue: Font = .caption.monospacedDigit()

    // MARK: - Corps & légendes

    static let body: Font = .body
    static let caption: Font = .caption
    static let captionSmall: Font = .caption2

    // MARK: - Valeurs numériques

    /// Valeur d'une tuile métrique standard.
    static let metricValue: Font = .title2.monospacedDigit().weight(.semibold)
    /// Valeur d'une tuile métrique « hero » (KPI principal mis en avant).
    static let heroValue: Font = .system(size: 30, weight: .semibold, design: .rounded).monospacedDigit()
    /// Chiffre monétaire inline (totaux).
    static let amount: Font = .body.monospacedDigit().weight(.medium)
    /// Total accentué (TTC).
    static let amountEmphasis: Font = .title3.monospacedDigit().weight(.semibold)

    // MARK: - Monospace / timer

    /// Horloge de timer en cours (HH:MM:SS).
    static let clock: Font = .system(size: 30, weight: .semibold, design: .monospaced)
    /// Horloge de timer compacte.
    static let clockCompact: Font = .system(.title3, design: .monospaced).weight(.semibold)
    /// Texte monospace générique (signatures, identifiants).
    static let mono: Font = .system(.body, design: .monospaced)
    static let monoCaption: Font = .system(.caption, design: .monospaced)
}
