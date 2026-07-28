import SwiftUI

extension Color {
    // MARK: - Couleurs principales de l'app
    // Note: static var au lieu de static let pour eviter un crash du compilateur Swift 6.0.x en release

    /// Adapte une couleur à l'apparence : `light` en clair, `dark` en sombre.
    ///
    /// Source unique du dark mode — les vues ne lisent JAMAIS `colorScheme`,
    /// tout passe par les tokens de ce fichier. La closure se résout au dessin
    /// et ne doit capturer que des NSColor immuables (Swift 6 : pas d'état
    /// @MainActor ni de CompanyInfo dedans).
    private static func dynamic(_ light: NSColor, _ dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }

    /// Base sRGB du vert olive de marque (#6B8E3A approx.).
    private static var oliveBase: NSColor {
        NSColor(srgbRed: 0.33, green: 0.54, blue: 0.19, alpha: 1.0)
    }

    /// Vert principal (barre de titre, en-tete tableau) — éclairci en sombre
    /// pour rester lisible en texte et en icône.
    static var appPrimary: Color {
        dynamic(oliveBase, oliveBase.lightened(by: 0.12))
    }

    /// Couleur principale dynamique (depuis CompanyInfo)
    static func appPrimary(from company: CompanyInfo) -> Color {
        guard let hex = company.couleurAccentHex,
              let ns = NSColor.fromHex(hex) else { return appPrimary }
        // Hex parsé AVANT la closure : elle ne capture que des NSColor immuables.
        return dynamic(ns, ns.lightened(by: 0.12))
    }

    // MARK: - Palette d'intention (source de vérité unique)
    //
    // Toute couleur "sémantique" de l'app dérive d'ici. StatusBadge, InlineTone,
    // KPI et badges doivent référencer ces tokens — jamais .green/.blue/.orange crus.

    /// Succès / payé / terminé.
    static var intentSuccess: Color { .green }
    /// Attente / en cours / à relancer.
    static var intentWarning: Color { .orange }
    /// Erreur / annulé / destructif.
    static var intentDanger: Color { .red }
    /// Information / accent neutre — porte l'accent de marque olive.
    static var intentInfo: Color { appPrimary }
    /// Neutre / brouillon / désactivé.
    static var intentNeutral: Color { .secondary }

    // MARK: - Couleurs sémantiques métier (dérivées de la marque)

    /// Revenu / chiffre d'affaires — porte l'accent de marque.
    static var appRevenue: Color { appPrimary }
    /// Montant en attente de paiement.
    static var appPending: Color { intentWarning }
    /// Devis.
    static var appQuote: Color { intentInfo }

    static func appRevenue(from company: CompanyInfo) -> Color { appPrimary(from: company) }
    static func appQuote(from company: CompanyInfo) -> Color { appPrimary(from: company) }

    // MARK: - Couleurs de statut (dérivées de la palette d'intention)

    static var statusBrouillon: Color { intentNeutral }
    static var statusEnvoyee: Color { intentWarning }
    static var statusPartiel: Color { intentInfo }
    static var statusPayee: Color { intentSuccess }
    static var statusAnnulee: Color { intentDanger }

    static func statusColor(for status: DocumentStatus) -> Color {
        switch status {
        case .brouillon: return .statusBrouillon
        case .envoyee: return .statusEnvoyee
        case .partiel: return .statusPartiel
        case .payee: return .statusPayee
        case .annulee: return .statusAnnulee
        }
    }

    // MARK: - Surfaces sémantiques
    //
    // Une seule opacité par rôle (remplace les 8 opacités de panneau divergentes).
    // En sombre : surfaces « surélevées » par un voile blanc (et non enfoncées),
    // sauf les champs de saisie qui restent creusés par un voile noir.
    //
    // ATTENTION : uniquement des constantes sRGB dans les branches — appeler
    // `withAlphaComponent` sur une couleur de catalogue (controlBackgroundColor…)
    // FIGE sa résolution à l'apparence active au moment de l'appel.
    // En clair, controlBackgroundColor et textBackgroundColor valent blanc pur :
    // les branches light reproduisent exactement le rendu d'avant.

    /// Fond des panneaux / cartes (SectionPanel).
    static var surfacePanel: Color {
        dynamic(
            NSColor.white.withAlphaComponent(0.78),
            NSColor.white.withAlphaComponent(0.055)
        )
    }
    /// Fond des tuiles métriques et tuiles d'action.
    static var surfaceTile: Color {
        dynamic(
            NSColor.white.withAlphaComponent(0.68),
            NSColor.white.withAlphaComponent(0.075)
        )
    }
    /// Fond des lignes de liste au repos.
    static var surfaceRow: Color {
        dynamic(
            NSColor.white.withAlphaComponent(0.62),
            NSColor.white.withAlphaComponent(0.06)
        )
    }
    /// Fond des lignes de liste au survol.
    static var surfaceRowHover: Color {
        dynamic(
            NSColor.white.withAlphaComponent(0.9),
            NSColor.white.withAlphaComponent(0.11)
        )
    }
    /// Fond des champs de saisie / surfaces enfoncées.
    static var surfaceField: Color {
        dynamic(
            NSColor.white.withAlphaComponent(0.5),
            NSColor.black.withAlphaComponent(0.22)
        )
    }
    /// Fond de l'inspecteur latéral (windowBackgroundColor est déjà dynamique).
    static var surfaceInspector: Color { Color(nsColor: .windowBackgroundColor) }

    // MARK: - Bordures sémantiques
    //
    // Renforcées en sombre : un voile primaire à 8 % y est presque invisible.

    /// Bordure discrète au repos (panneaux, tuiles, lignes).
    static var borderSubtle: Color {
        dynamic(NSColor.black.withAlphaComponent(0.08), NSColor.white.withAlphaComponent(0.12))
    }
    /// Bordure au survol / focus.
    static var borderHover: Color {
        dynamic(NSColor.black.withAlphaComponent(0.14), NSColor.white.withAlphaComponent(0.20))
    }
    /// Séparateur fin.
    static var borderHairline: Color {
        dynamic(NSColor.black.withAlphaComponent(0.06), NSColor.white.withAlphaComponent(0.08))
    }
}
