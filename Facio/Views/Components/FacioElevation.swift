import SwiftUI

// MARK: - Élévation

/// Les trois plans de Facio.
///
/// Une seule ombre existait dans toute l'application (le toast), et la
/// séparation des plans reposait sur 1 pt de bordure et 1 à 2 points d'alpha —
/// en sombre, une tuile posée sur un panneau était indiscernable.
///
/// La règle change selon le thème : **en clair l'élévation est portée par
/// l'ombre, en sombre par la luminance du plan.** Un plan sombre n'a donc pas
/// besoin d'une bordure pour exister.
enum FacioElevation {
    /// Panneau, tuile, ligne.
    case e1
    /// Bandeau collant, barre d'outils.
    case e2
    /// Popover, feuille, toast.
    case e3

    var surface: Color {
        switch self {
        case .e1: return .surfaceRaised
        case .e2: return .surfaceSunken
        case .e3: return .surfaceFloat
        }
    }

    var shadowColor: Color {
        switch self {
        case .e1: return .shadowE1
        case .e2: return .shadowE2
        case .e3: return .shadowE3
        }
    }

    /// Rayon de flou. Les valeurs du design sont en `blur` CSS : SwiftUI prend
    /// la moitié.
    var shadowRadius: CGFloat {
        switch self {
        case .e1: return 1
        case .e2: return 3
        case .e3: return 16
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .e1: return 1
        case .e2: return 2
        case .e3: return 12
        }
    }
}

extension View {
    /// Pose un plan : surface opaque, rayon, ombre du niveau, et — uniquement
    /// en `e1` — le contour de raffinement.
    func facioElevation(
        _ level: FacioElevation,
        radius: CGFloat = FacioLayout.radiusMedium,
        surface: Color? = nil
    ) -> some View {
        background(surface ?? level.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(level == .e1 ? Color.borderHairlineToken : .clear, lineWidth: 1)
            )
            .shadow(color: level.shadowColor, radius: level.shadowRadius, x: 0, y: level.shadowY)
    }
}

// MARK: - Focus clavier

/// Anneau de focus partagé.
///
/// Le seul indice de focus de l'application était un passage de bordure de 8 %
/// à 14 % de noir sur les champs — 6 % d'alpha sur 1 pt, invisible. Ni les
/// boutons ni les boutons-icône n'en avaient.
///
/// L'anneau se pose PAR-DESSUS la forme, en deux couches : un liseré de la
/// couleur du canvas pour détacher l'anneau de la surface, puis l'accent.
struct FacioFocusRing: ViewModifier {
    let isFocused: Bool
    var radius: CGFloat = FacioLayout.radiusSmall

    func body(content: Content) -> some View {
        content.overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Color.surfaceCanvas, lineWidth: 2)
                    .padding(-2)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius + 2)
                            .strokeBorder(Color.accent.opacity(0.55), lineWidth: 2)
                            .padding(-4)
                    }
            }
        }
    }
}

extension View {
    /// Anneau de focus clavier — à poser sur TOUT élément actionnable.
    func facioFocusRing(_ isFocused: Bool, radius: CGFloat = FacioLayout.radiusSmall) -> some View {
        modifier(FacioFocusRing(isFocused: isFocused, radius: radius))
    }
}

// MARK: - Survol

/// Survol partagé. La logique — `@State isHovering` + `.onHover` + la même
/// animation — était réimplémentée à l'identique dans quatre composants ;
/// toute évolution du survol devait donc être appliquée quatre fois.
struct FacioHoverable: ViewModifier {
    var radius: CGFloat = FacioLayout.radiusMedium
    var resting: Color = .surfaceSunken
    var hovering: Color = .surfaceHover
    /// Sélection : elle prime sur le survol et ne s'y confond jamais.
    var isSelected: Bool = false

    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fill: Color {
        if isSelected { return .surfaceSelected }
        return isHovering ? hovering : resting
    }

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .contentShape(RoundedRectangle(cornerRadius: radius))
            .animation(FacioMotion.respecting(FacioMotion.hover, reduceMotion: reduceMotion), value: isHovering)
            .animation(FacioMotion.respecting(FacioMotion.state, reduceMotion: reduceMotion), value: isSelected)
            .onHover { isHovering = $0 }
    }
}

extension View {
    func facioHoverable(
        radius: CGFloat = FacioLayout.radiusMedium,
        resting: Color = .surfaceSunken,
        hovering: Color = .surfaceHover,
        isSelected: Bool = false
    ) -> some View {
        modifier(FacioHoverable(radius: radius, resting: resting, hovering: hovering, isSelected: isSelected))
    }
}
