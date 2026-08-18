import SwiftUI

/// Échelle typographique gouvernée de Facio.
///
/// Toute taille de texte passe par ces tokens — aucune `.font(.system(size:))`
/// arbitraire dans les vues.
///
/// **Sept paliers réellement distincts, plancher à 11 pt.** L'échelle précédente
/// annonçait 22 tokens pour quatre paliers réels : `caption` et `captionSmall`
/// se résolvaient tous les deux autour de 10 pt, indiscernables à l'œil, et
/// portaient à eux seuls plus de la moitié du texte de l'application. Le palier
/// manquant — 12 pt, `secondary` — est celui qui portait tout ce travail.
///
/// Les tailles sont fixes et en points macOS, comme spécifié par le design :
/// l'alignement des colonnes de montants et la densité des tableaux ne
/// survivent pas à une mise à l'échelle dynamique. Le jeu numérique est séparé
/// et en **chiffres tabulaires** — les montants d'une colonne doivent s'aligner.
///
/// Liste blanche — seuls cas où un `.font()` natif reste autorisé dans les vues :
/// 1. dimensionnement d'un glyphe SF Symbol (`Image(systemName:).font(...)`) ;
/// 2. tailles décoratives uniques (logo de la page À propos, « F » de repli).
/// Tout autre `.font()` natif est une dette : le migrer vers un token.
enum FacioFont {
    // MARK: - Paliers de texte (7)

    /// 22 / semibold / −0,02 em — titre d'écran.
    static let titleScreen: Font = .system(size: 22, weight: .semibold)
    /// 17 / semibold — bandeau de document, nom de client.
    static let titleHero: Font = .system(size: 17, weight: .semibold)
    /// 15 / semibold — titre de section.
    static let titleSection: Font = .system(size: 15, weight: .semibold)
    /// 13 / semibold — titre de panneau, en-tête de colonne.
    static let titlePanel: Font = .system(size: 13, weight: .semibold)
    /// 13 / regular — texte courant, valeur de champ.
    static let body: Font = .system(size: 13, weight: .regular)
    /// 12 / regular — métadonnée lisible. Palier neuf : il remplace les 10 pt.
    static let secondary: Font = .system(size: 12, weight: .regular)
    /// 11 / medium — libellé de champ, badge. **Plancher : rien en dessous.**
    static let label: Font = .system(size: 11, weight: .medium)

    // MARK: - Jeu numérique (chiffres tabulaires)

    /// 28 / mono semibold — valeur d'une tuile KPI.
    static let metric: Font = .system(size: 28, weight: .semibold, design: .monospaced).monospacedDigit()
    /// 28 / mono regular — minuteur.
    static let clock: Font = .system(size: 28, weight: .regular, design: .monospaced).monospacedDigit()
    /// 13 / mono medium — montant, en ligne comme en colonne.
    static let amount: Font = .system(size: 13, weight: .medium, design: .monospaced).monospacedDigit()
    /// 17 / mono semibold — total mis en avant (bandeau de document).
    static let amountHero: Font = .system(size: 17, weight: .semibold, design: .monospaced).monospacedDigit()
    /// 11 / mono medium — métadonnée numérique discrète.
    static let metaValue: Font = .system(size: 11, weight: .medium, design: .monospaced).monospacedDigit()

    /// 13 / medium — **un compte n'est pas un montant.** Il reste en typo de
    /// texte et porte toujours son unité (« 3 devis », pas « 3 » aligné comme
    /// une somme dans la même mono que la tuile voisine).
    static let count: Font = .system(size: 13, weight: .medium)

    /// Texte monospace générique (signatures, identifiants, IBAN).
    static let mono: Font = .system(size: 13, weight: .regular, design: .monospaced)
    /// Monospace discret (hash tronqué, SQL).
    static let monoSmall: Font = .system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - Noms historiques
    //
    // Conservés parce qu'ils sont appelés dans toutes les vues ; ils pointent
    // désormais vers le palier de la nouvelle échelle qui porte leur rôle.
    // Les deux paliers à 10 pt disparaissent ici : `caption` monte à 12 pt et
    // `captionSmall` au plancher de 11 pt.

    static let screenTitle: Font = titleScreen
    static let screenSubtitle: Font = secondary
    static let sectionTitle: Font = titleSection
    static let subsectionTitle: Font = titlePanel
    static let heroTitle: Font = titleHero
    static let heroTotal: Font = .system(size: 22, weight: .semibold, design: .monospaced).monospacedDigit()

    static let fieldLabel: Font = label
    static let rowTitle: Font = .system(size: 13, weight: .medium)
    static let rowSubtitle: Font = secondary
    static let rowValue: Font = amount

    static let caption: Font = secondary
    static let captionSmall: Font = label

    static let metricValue: Font = metric
    static let heroValue: Font = metric
    static let amountEmphasis: Font = amountHero
    static let clockCompact: Font = amountHero
    static let monoCaption: Font = monoSmall
}
