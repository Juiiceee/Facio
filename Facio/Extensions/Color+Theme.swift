import SwiftUI

// MARK: - Intention

/// Une intention porte QUATRE valeurs qui ne sont jamais interchangeables :
/// l'aplat (`fill`), le fond teinté (`tint`), le seul texte autorisé sur ce
/// fond (`onTint`), et la marque colorée qui ne porte pas de texte (`glyph`).
///
/// Avant, une intention servait à la fois de remplissage ET de couleur de texte
/// posée sur 9 à 16 % d'elle-même, en 10 pt — un contraste que personne n'avait
/// mesuré. Les rôles sont désormais séparés et chiffrés.
///
/// `glyph` répond à un constat d'usage : `fill` et `onTint` sont calés sur
/// 4,5:1, le seuil du TEXTE, ce qui les force sombres et éteint tout ce qui,
/// dans l'interface, est de la couleur pure — pastille de statut, icône, filet
/// de tuile, flèche de tendance. Ces objets relèvent du seuil « objets
/// graphiques » de WCAG, 3:1, et peuvent donc être bien plus lumineux. La
/// séparation rend à l'app sa vivacité sans desserrer aucune règle de lisibilité.
struct FacioIntent {
    /// Aplat portant du texte clair. Calé sur 4,5:1 avec `textOnAccent`.
    let fill: Color
    /// Fond teinté, très pâle en clair, très sombre en sombre.
    let tint: Color
    /// Le seul texte autorisé sur `tint`. Calé sur 4,5:1.
    let onTint: Color
    /// Marque colorée SANS texte : pastille, icône, filet, flèche.
    /// Calée sur 3:1 contre les sept surfaces, dans les deux thèmes.
    let glyph: Color
}

extension FacioIntent {
    // Noms courts destinés aux vues : `intent: .success` plutôt que
    // `intent: Color.intentSuccessTriple`. Les valeurs vivent dans `Color`,
    // avec le reste de la palette.
    static var info: FacioIntent { Color.intentInfoTriple }
    static var success: FacioIntent { Color.intentSuccessTriple }
    static var warning: FacioIntent { Color.intentWarningTriple }
    static var danger: FacioIntent { Color.intentDangerTriple }
    static var neutral: FacioIntent { Color.intentNeutralTriple }

    /// Accent de marque, ou la couleur choisie par l'utilisateur.
    static func accent(from company: CompanyInfo) -> FacioIntent {
        Color.accentIntent(from: company)
    }
}

extension Color {
    // MARK: - Résolution clair / sombre
    // Note : `static var` calculée et non `static let` — un `static let` de Color
    // fait crasher le compilateur Swift 6.0.x en release.

    /// Adapte une couleur à l'apparence : `light` en clair, `dark` en sombre.
    ///
    /// Source unique du dark mode — les vues ne lisent JAMAIS `colorScheme`,
    /// tout passe par les tokens de ce fichier. La closure se résout au dessin
    /// et ne doit capturer que des NSColor immuables (Swift 6 : pas d'état
    /// @MainActor ni de CompanyInfo dedans).
    ///
    /// ATTENTION : uniquement des constantes sRGB dans les branches — appeler
    /// `withAlphaComponent` sur une couleur de catalogue (controlBackgroundColor…)
    /// FIGE sa résolution à l'apparence active au moment de l'appel.
    private static func dynamic(_ light: NSColor, _ dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }

    private static func srgb(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
        NSColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    // MARK: - Accent de marque
    //
    // Les deux olives précédents (#548A30 côté interface, #6B8E3A côté PDF)
    // échouaient au même endroit : sous du texte blanc ils plafonnaient à 4,15:1
    // et 3,84:1. Aucun des deux ne pouvait donc rester la couleur du bouton
    // primaire. #4A7A2B tient les trois contraintes à la fois — blanc dessus
    // (5,11:1), olive en texte sur blanc (5,11:1), et lisibilité en laser noir et
    // blanc, le contraste étant calculé sur la luminance.

    /// Olive de marque. Le token sombre est un éclaircissement de l'olive
    /// (9,6:1 sur le canvas sombre), pas une seconde marque.
    static var accent: Color { dynamic(accentPrintNS, srgb(0xA9C68C)) }
    /// Survol des surfaces accentuées.
    static var accentHover: Color { dynamic(srgb(0x3D6621), srgb(0xBBD4A0)) }
    /// Fond de sélection, badge « Partiel ».
    static var accentTint: Color { dynamic(srgb(0xE4EDD8), srgb(0x2E3A20)) }
    /// Texte sur l'aplat d'accent de marque.
    static var textOnAccent: Color { dynamic(srgb(0xFFFFFF), srgb(0x12160C)) }

    /// Valeur imprimée : le PDF ne connaît pas le thème et utilise l'olive clair.
    /// C'est la MÊME constante que l'interface — un cas de non-régression
    /// l'épingle, avec le défaut par défaut de `CompanyInfo`.
    static var accentPrintNS: NSColor { srgb(0x4A7A2B) }

    /// Accent de marque, ou la couleur choisie par l'utilisateur.
    static func accent(from company: CompanyInfo) -> Color {
        guard let hex = company.couleurAccentHex,
              let ns = NSColor.fromHex(hex) else { return accent }
        // Hex parsé AVANT la closure : elle ne capture que des NSColor immuables.
        return dynamic(ns, ns.lightened(by: 0.12))
    }

    // Noms historiques, conservés : ils sont appelés dans toutes les vues.
    static var appPrimary: Color { accent }
    static func appPrimary(from company: CompanyInfo) -> Color { accent(from: company) }
    static var appRevenue: Color { accent }
    static var appQuote: Color { accent }
    static func appRevenue(from company: CompanyInfo) -> Color { accent(from: company) }
    static func appQuote(from company: CompanyInfo) -> Color { accent(from: company) }
    static var appPending: Color { intentWarning }

    // MARK: - Garde-fou de l'accent personnalisé
    //
    // Le bouton primaire forçait du texte blanc : un accent jaune ou cyan clair
    // rendait TOUS les boutons principaux de l'app illisibles. La couleur du
    // texte sur accent est désormais calculée.

    /// Texte à servir sur un aplat de cette couleur : blanc ou quasi-noir, celui
    /// des deux qui contraste le mieux.
    static func onAccent(_ background: NSColor) -> Color {
        Color(nsColor: NSColor.bestForeground(on: background))
    }

    /// Ce token, résolu en `NSColor` dans un thème donné.
    ///
    /// Indispensable dès qu'une couleur doit être **calculée** à partir d'une
    /// autre : un token est une paire clair/sombre, et raisonner sur une seule
    /// branche donne un résultat faux dans l'autre.
    func facioResolved(_ scheme: ColorScheme) -> NSColor {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        let resolved = resolve(in: environment)
        return NSColor(
            srgbRed: CGFloat(resolved.red),
            green: CGFloat(resolved.green),
            blue: CGFloat(resolved.blue),
            alpha: CGFloat(resolved.opacity)
        )
    }

    /// Texte à poser sur cet aplat, calculé **dans le thème courant**.
    ///
    /// La variante `onAccent(NSColor)` ne voit qu'une branche : appliquée à
    /// l'accent de marque, elle choisissait le blanc de l'olive claire et le
    /// posait aussi sur l'olive éclaircie du mode sombre — 1,88:1. En partant
    /// de l'aplat réellement peint, l'incohérence ne peut plus exister.
    static func onFill(_ fill: Color, _ scheme: ColorScheme) -> Color {
        Color(nsColor: NSColor.bestForeground(on: fill.facioResolved(scheme)))
    }

    /// Aucun texte ne passe 4,5:1 sur cet aplat, dans ce thème.
    static func needsTintFallback(_ fill: Color, _ scheme: ColorScheme) -> Bool {
        NSColor.bestContrastRatio(on: fill.facioResolved(scheme)) < 4.5
    }

    /// Vrai quand aucun texte ne passe 4,5:1 sur cet aplat (chroma extrême).
    /// Le bouton primaire garde alors sa teinte mais repasse en texte primaire
    /// sur `tint` : le système ne casse jamais, quelle que soit la couleur choisie.
    static func needsTintFallback(_ background: NSColor) -> Bool {
        NSColor.bestContrastRatio(on: background) < 4.5
    }

    // MARK: - Surfaces
    //
    // Cinq surfaces sur six étaient des alphas posés sur un fond jamais défini :
    // aucun ratio n'était spécifiable, et en sombre un panneau (blanc 5,5 %) et
    // une tuile (blanc 7,5 %) différaient de 2 % — indiscernables sans bordure.
    // On définit d'abord le canvas, puis des plans OPAQUES par-dessus.
    //
    // Écarts de luminance en sombre : canvas → panneau +1,1 %,
    // panneau → tuile +1,6 %, tuile → survol +2,2 %. Chaque pas reste visible
    // sans une seule bordure.

    /// Fond de fenêtre et de colonne.
    static var surfaceCanvas: Color { dynamic(srgb(0xEFEEE8), srgb(0x121210)) }
    /// Panneau de section, carte.
    static var surfaceRaised: Color { dynamic(srgb(0xFFFFFF), srgb(0x1F1E19)) }
    /// Tuile, ligne à l'intérieur d'un panneau.
    static var surfaceSunken: Color { dynamic(srgb(0xF6F5F0), srgb(0x292823)) }
    /// Champ de saisie. Règle : plus sombre que son panneau en mode sombre, plus
    /// clair en mode clair — le creusé est porté par la valeur, jamais par une
    /// ombre interne seule.
    static var surfaceFieldToken: Color { dynamic(srgb(0xFFFFFF), srgb(0x0D0D0A)) }
    /// Survol partagé, pour TOUS les composants survolables.
    static var surfaceHover: Color { dynamic(srgb(0xF1F0EA), srgb(0x33322B)) }
    /// Sélection — volontairement distincte du survol.
    static var surfaceSelected: Color { dynamic(srgb(0xE4EDD8), srgb(0x2E3A20)) }
    /// Popover, feuille, toast.
    static var surfaceFloat: Color { dynamic(srgb(0xFFFFFF), srgb(0x2B2A24)) }

    // Noms historiques.
    static var surfacePanel: Color { surfaceRaised }
    static var surfaceTile: Color { surfaceSunken }
    static var surfaceRow: Color { surfaceSunken }
    static var surfaceRowHover: Color { surfaceHover }
    static var surfaceField: Color { surfaceFieldToken }
    static var surfaceInspector: Color { surfaceCanvas }

    // MARK: - Contours
    //
    // Avec des plans opaques, le contour redevient ce qu'il aurait dû rester :
    // un raffinement, pas la preuve d'existence de la tuile.

    /// Contour de raffinement.
    static var borderHairlineToken: Color {
        dynamic(srgb(0x1A1A17, alpha: 0.10), srgb(0xF4F3ED, alpha: 0.10))
    }
    /// Filet interne (séparateur).
    static var borderDivider: Color {
        dynamic(srgb(0x1A1A17, alpha: 0.07), srgb(0xF4F3ED, alpha: 0.07))
    }
    /// Contour renforcé (survol d'une surface bordée).
    static var borderStrong: Color {
        dynamic(srgb(0x1A1A17, alpha: 0.18), srgb(0xF4F3ED, alpha: 0.18))
    }

    // Noms historiques.
    static var borderSubtle: Color { borderHairlineToken }
    static var borderHover: Color { borderStrong }
    static var borderHairline: Color { borderDivider }

    // MARK: - Ombres portées
    //
    // En clair l'élévation est portée par l'ombre ; en sombre par la luminance
    // du plan. Le plan e1 sombre ne porte donc AUCUNE ombre — d'où une couleur
    // entièrement transparente plutôt qu'une ombre atténuée.

    static var shadowE1: Color { dynamic(srgb(0x1A1A17, alpha: 0.05), srgb(0x000000, alpha: 0)) }
    static var shadowE2: Color { dynamic(srgb(0x1A1A17, alpha: 0.08), srgb(0x000000, alpha: 0.45)) }
    static var shadowE3: Color { dynamic(srgb(0x1A1A17, alpha: 0.16), srgb(0x000000, alpha: 0.60)) }

    // MARK: - Texte
    //
    // Aucune vue ne doit plus lire `.primary` / `.secondary` / `.tertiary` de
    // SwiftUI : le contraste n'y était ni contrôlable ni mesurable. Le tertiaire
    // est plafonné à 4,8:1 — il reste utilisable pour du TEXTE, pas seulement
    // pour décorer.

    /// Titre, valeur, libellé porteur. 15,8:1 clair · 14,9:1 sombre.
    static var textPrimary: Color { dynamic(srgb(0x1A1A17), srgb(0xF4F3ED)) }
    /// Description, métadonnée. 7,4:1 clair · 7,9:1 sombre.
    static var textSecondary: Color { dynamic(srgb(0x56544C), srgb(0xB4B2A8)) }
    /// Horodatage, aide.
    ///
    /// La spec donnait #757269 / #8C8A80 « 4,8:1 garanti ». Ces ratios sont
    /// mesurés contre le BLANC et contre le canvas sombre — or ce token est posé
    /// sur les sept surfaces. Il retombait à 4,14:1 sur le canvas clair et à
    /// 3,71:1 sur une ligne survolée en sombre, donc sous AA aux deux endroits
    /// où il sert le plus (horodatage d'une ligne de liste).
    ///
    /// Recalé sur le pire cas de chaque thème : 4,75:1 minimum en clair,
    /// 4,59:1 minimum en sombre, sur les sept surfaces. Un cas de non-régression
    /// balaie la matrice complète.
    static var textTertiary: Color { dynamic(srgb(0x69665E), srgb(0xA2A096)) }

    // MARK: - Intentions

    // Les valeurs `glyph` claires sont la tonalité la plus lumineuse de chaque
    // teinte tenant encore 3:1 sur les sept surfaces claires (environ 23 % de
    // luminance, contre 11 à 17 % pour les aplats). En sombre, les aplats sont
    // déjà clairs et dépassent tous 5,5:1 : ils font office de glyphe.

    static var intentSuccessTriple: FacioIntent {
        FacioIntent(
            fill: dynamic(srgb(0x2F7A3E), srgb(0x8FD09B)),
            tint: dynamic(srgb(0xE4F0E4), srgb(0x1C2E1F)),
            onTint: dynamic(srgb(0x205C2C), srgb(0x8FD09B)),
            glyph: dynamic(srgb(0x3A954C), srgb(0x8FD09B))
        )
    }
    static var intentWarningTriple: FacioIntent {
        FacioIntent(
            fill: dynamic(srgb(0xA8600A), srgb(0xE8B770)),
            tint: dynamic(srgb(0xF8ECD9), srgb(0x332415)),
            onTint: dynamic(srgb(0x7A4405), srgb(0xE8B770)),
            glyph: dynamic(srgb(0xC36F0C), srgb(0xE8B770))
        )
    }
    static var intentDangerTriple: FacioIntent {
        FacioIntent(
            fill: dynamic(srgb(0xB3261E), srgb(0xF09A92)),
            tint: dynamic(srgb(0xFBE5E3), srgb(0x361A18)),
            onTint: dynamic(srgb(0x8C1B15), srgb(0xF09A92)),
            glyph: dynamic(srgb(0xFA352A), srgb(0xF09A92))
        )
    }
    static var intentNeutralTriple: FacioIntent {
        FacioIntent(
            fill: dynamic(srgb(0x6B6860), srgb(0xBEBCB2)),
            tint: dynamic(srgb(0xEDECE6), srgb(0x2A2924)),
            onTint: dynamic(srgb(0x4B493F), srgb(0xBEBCB2)),
            glyph: dynamic(srgb(0x88847A), srgb(0xBEBCB2))
        )
    }
    static var intentInfoTriple: FacioIntent {
        FacioIntent(fill: accent, tint: accentTint, onTint: accent, glyph: accentGlyph)
    }

    /// Olive de marque en marque colorée sans texte (pastille, icône, filet).
    static var accentGlyph: Color { dynamic(srgb(0x599234), srgb(0xA9C68C)) }

    /// Intention portant l'accent de marque — ou la couleur choisie par
    /// l'utilisateur. Une couleur personnalisée n'a ni teinte pâle ni glyphe
    /// mesurés : on la sert telle quelle en marque et en texte sur `tint`, et
    /// c'est `onAccent` qui protège la lisibilité des aplats.
    static func accentIntent(from company: CompanyInfo) -> FacioIntent {
        guard company.couleurAccentHex != nil else { return intentInfoTriple }
        let custom = accent(from: company)
        return FacioIntent(fill: custom, tint: accentTint, onTint: custom, glyph: custom)
    }

    // Noms historiques : l'aplat de chaque intention.
    static var intentSuccess: Color { intentSuccessTriple.fill }
    static var intentWarning: Color { intentWarningTriple.fill }
    static var intentDanger: Color { intentDangerTriple.fill }
    static var intentInfo: Color { accent }
    static var intentNeutral: Color { intentNeutralTriple.fill }

    static func intent(for tone: InlineTone) -> FacioIntent {
        switch tone {
        case .info: return intentInfoTriple
        case .success: return intentSuccessTriple
        case .warning: return intentWarningTriple
        case .danger: return intentDangerTriple
        }
    }

    // MARK: - Statuts de document

    static var statusBrouillon: Color { intentNeutral }
    static var statusEnvoyee: Color { intentWarning }
    static var statusPartiel: Color { intentInfo }
    static var statusPayee: Color { intentSuccess }
    static var statusAnnulee: Color { intentDanger }

    static func statusColor(for status: DocumentStatus) -> Color {
        statusIntent(for: status).fill
    }

    /// Le triplet complet d'un statut — la capsule a besoin des trois valeurs.
    static func statusIntent(for status: DocumentStatus) -> FacioIntent {
        switch status {
        case .brouillon: return intentNeutralTriple
        case .envoyee: return intentWarningTriple
        case .partiel: return intentInfoTriple
        case .payee: return intentSuccessTriple
        case .annulee: return intentDangerTriple
        }
    }
}

// MARK: - Contraste

extension NSColor {
    /// Luminance relative WCAG, en sRGB linéarisé.
    var relativeLuminance: CGFloat {
        guard let c = usingColorSpace(.sRGB) else { return 0 }
        func channel(_ v: CGFloat) -> CGFloat {
            v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(c.redComponent)
            + 0.7152 * channel(c.greenComponent)
            + 0.0722 * channel(c.blueComponent)
    }

    /// Ratio de contraste WCAG entre deux couleurs (de 1:1 à 21:1).
    static func contrastRatio(_ lhs: NSColor, _ rhs: NSColor) -> CGFloat {
        let a = lhs.relativeLuminance, b = rhs.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// Quasi-noir de la palette — le pendant du blanc pour le texte sur aplat.
    static var facioInk: NSColor {
        NSColor(srgbRed: 0x12 / 255, green: 0x16 / 255, blue: 0x0C / 255, alpha: 1)
    }

    /// Blanc ou quasi-noir — celui des deux qui contraste le mieux sur `background`.
    static func bestForeground(on background: NSColor) -> NSColor {
        contrastRatio(.facioInk, background) >= contrastRatio(.white, background) ? .facioInk : .white
    }

    /// Le meilleur ratio atteignable sur `background` avec du blanc ou du quasi-noir.
    static func bestContrastRatio(on background: NSColor) -> CGFloat {
        max(contrastRatio(.white, background), contrastRatio(.facioInk, background))
    }
}
