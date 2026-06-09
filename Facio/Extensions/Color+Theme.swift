import SwiftUI

extension Color {
    // MARK: - Couleurs principales de l'app
    // Note: static var au lieu de static let pour eviter un crash du compilateur Swift 6.0.x en release

    /// Vert principal (barre de titre, en-tete tableau)
    static var appPrimary: Color { Color(red: 0.33, green: 0.54, blue: 0.19) }

    /// Vert clair pour les lignes alternees du tableau
    static var appPrimaryLight: Color { Color(red: 0.33, green: 0.54, blue: 0.19).opacity(0.08) }

    /// Couleur principale dynamique (depuis CompanyInfo)
    static func appPrimary(from company: CompanyInfo) -> Color {
        guard let hex = company.couleurAccentHex,
              let ns = NSColor.fromHex(hex) else { return appPrimary }
        return Color(nsColor: ns)
    }

    /// Fond de la sidebar
    static var sidebarBackground: Color { Color(nsColor: .controlBackgroundColor) }

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
    static var statusPayee: Color { intentSuccess }
    static var statusAnnulee: Color { intentDanger }

    static func statusColor(for status: DocumentStatus) -> Color {
        switch status {
        case .brouillon: return .statusBrouillon
        case .envoyee: return .statusEnvoyee
        case .payee: return .statusPayee
        case .annulee: return .statusAnnulee
        }
    }

    // MARK: - Surfaces sémantiques
    //
    // Une seule opacité par rôle (remplace les 8 opacités de panneau divergentes).

    /// Fond des panneaux / cartes (SectionPanel).
    static var surfacePanel: Color { Color(nsColor: .controlBackgroundColor).opacity(0.78) }
    /// Fond des tuiles métriques et tuiles d'action.
    static var surfaceTile: Color { Color(nsColor: .textBackgroundColor).opacity(0.68) }
    /// Fond des lignes de liste au repos.
    static var surfaceRow: Color { Color(nsColor: .textBackgroundColor).opacity(0.62) }
    /// Fond des lignes de liste au survol.
    static var surfaceRowHover: Color { Color(nsColor: .textBackgroundColor).opacity(0.9) }
    /// Fond des champs de saisie / surfaces enfoncées.
    static var surfaceField: Color { Color(nsColor: .textBackgroundColor).opacity(0.5) }
    /// Fond de l'inspecteur latéral.
    static var surfaceInspector: Color { Color(nsColor: .windowBackgroundColor) }

    // MARK: - Bordures sémantiques

    /// Bordure discrète au repos (panneaux, tuiles, lignes).
    static var borderSubtle: Color { Color.primary.opacity(0.08) }
    /// Bordure au survol / focus.
    static var borderHover: Color { Color.primary.opacity(0.14) }
    /// Séparateur fin.
    static var borderHairline: Color { Color.primary.opacity(0.06) }
}
