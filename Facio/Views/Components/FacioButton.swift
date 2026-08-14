import SwiftUI

/// Hiérarchie d'action de Facio. Un seul vocabulaire de boutons pour toute l'app,
/// là où quatre coexistaient : 27 `.facio(...)`, 21 `.plain`, 15 `.borderless`,
/// plus les boutons système bruts des réglages.
enum FacioButtonRole {
    /// Action principale d'un contexte — fond plein accent de marque.
    /// Un seul par contexte.
    case primary
    /// Action secondaire — surface discrète bordée.
    case secondary
    /// Action de troisième plan : pas de fond, pas de bordure, libellé accentué.
    /// C'est le rôle qui absorbe les « borderless » et les boutons système bruts.
    case tertiary
    /// Action destructive — fond plein rouge, confirmation obligatoire.
    case destructive
}

// Le rôle porte lui-même sa palette : le style ne fait plus que l'appliquer.
// C'est aussi ce qui rend la table testable — la suite de régression mesure la
// MÊME source que le rendu, et pas une copie des valeurs attendues.
extension FacioButtonRole {
    /// Aucun texte ne passe 4,5:1 sur cet accent (jaune vif, cyan pâle…) : le
    /// bouton primaire garde alors la teinte mais repasse en surface teintée.
    static func accentUnusable(_ accent: Color, _ scheme: ColorScheme) -> Bool {
        Color.needsTintFallback(accent, scheme)
    }

    func fill(accent: Color, scheme: ColorScheme) -> Color {
        switch self {
        case .primary:
            return Self.accentUnusable(accent, scheme) ? .accentTint : accent
        case .secondary:
            return .surfaceSunken
        case .tertiary:
            return .clear
        case .destructive:
            return FacioIntent.danger.fill
        }
    }

    /// Texte du rôle, TOUJOURS calculé sur l'aplat que le bouton peint.
    ///
    /// Les deux rôles pleins forçaient du blanc. En mode sombre, l'accent est
    /// une olive claire et l'aplat « danger » un rose clair : le blanc y tombait
    /// à 1,88:1 et à 2,16:1.
    func foreground(accent: Color, scheme: ColorScheme) -> Color {
        switch self {
        case .primary:
            return Self.accentUnusable(accent, scheme) ? .textPrimary : Color.onFill(accent, scheme)
        case .destructive:
            return Color.onFill(FacioIntent.danger.fill, scheme)
        case .secondary:
            return .textPrimary
        case .tertiary:
            // Posé sur une surface, pas sur un aplat : c'est l'accent en ENCRE.
            // Calibré pour porter du blanc, il tombe à 4,23:1 dans ce sens —
            // et un accent personnalisé peut être bien pire. On le rend lisible
            // par calcul plutôt que par exception.
            return Color.readableInk(accent, onAnyOf: Color.inkSurfaces, scheme)
        }
    }

    func border(accent: Color, scheme: ColorScheme) -> Color {
        switch self {
        case .primary: return Self.accentUnusable(accent, scheme) ? .borderStrong : .clear
        case .destructive, .tertiary: return .clear
        case .secondary: return .borderHairlineToken
        }
    }

    /// Le primaire est le seul à passer en semibold : c'est ce qui le distingue
    /// quand l'accent est remplacé par sa teinte.
    var isEmphasised: Bool { self == .primary }

    /// Le tertiaire est plus serré — il vit dans le flux du texte.
    var horizontalPadding: CGFloat {
        // La spec du catalogue demande 14 pt (8 en tertiaire). 14 est hors de la
        // grille de 4 pt posée par les fondations : on prend le cran valide le
        // plus proche vers le bas plutôt que de rouvrir la grille pour un seul
        // composant.
        self == .tertiary ? FacioLayout.space8 : FacioLayout.space12
    }
}

/// Accent de marque ambiant (couleur d'accent de `CompanyInfo`), injecté à la
/// racine de chaque scène par `FacioApp`. Permet aux styles de boutons de
/// suivre la couleur de marque sans dépendre de `DataStore`.
private struct FacioAccentKey: EnvironmentKey {
    // `static var` calculée : même précaution que Color+Theme (crash du
    // compilateur Swift 6.0.x en release sur les `static let` de Color).
    static var defaultValue: Color { .appPrimary }
}

extension EnvironmentValues {
    var facioAccent: Color {
        get { self[FacioAccentKey.self] }
        set { self[FacioAccentKey.self] = newValue }
    }
}

/// Style de bouton tokenisé. Utilisable via `.buttonStyle(.facio(.primary))`.
/// Le style suit l'accent de marque ambiant, et CALCULE le texte à poser dessus.
///
/// Préférer `FacioButton` : l'enveloppe ajoute l'anneau de focus clavier et
/// l'état de chargement, que le style seul ne peut pas porter.
struct FacioButtonStyle: ButtonStyle {
    var role: FacioButtonRole = .primary
    var density: FacioLayout.Density = FacioLayout.density

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.facioAccent) private var ambientAccent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(role.isEmphasised ? FacioFont.buttonLabelEmphasis : FacioFont.buttonLabel)
            .lineLimit(1)
            .padding(.horizontal, role.horizontalPadding)
            .frame(minHeight: density.controlHeight)
            .foregroundStyle(foreground)
            .background(background(pressed: configuration.isPressed))
            .overlay(
                RoundedRectangle(cornerRadius: FacioLayout.radiusSmall)
                    .strokeBorder(border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusSmall))
            .contentShape(RoundedRectangle(cornerRadius: FacioLayout.radiusSmall))
            .opacity(isEnabled ? 1 : 0.45)
            .animation(FacioMotion.respecting(FacioMotion.hover, reduceMotion: reduceMotion), value: configuration.isPressed)
    }

    private var fill: Color { role.fill(accent: ambientAccent, scheme: scheme) }
    private var foreground: Color { role.foreground(accent: ambientAccent, scheme: scheme) }
    private var border: Color { role.border(accent: ambientAccent, scheme: scheme) }

    private func background(pressed: Bool) -> Color {
        switch role {
        case .primary, .destructive:
            return pressed ? fill.opacity(0.82) : fill
        case .secondary:
            return pressed ? .surfaceHover : fill
        case .tertiary:
            return pressed ? .surfaceHover : .clear
        }
    }
}

extension ButtonStyle where Self == FacioButtonStyle {
    // Le paramètre `accent:` a disparu : aucune vue ne s'en servait, et il
    // court-circuitait le calcul de la couleur de texte.
    static func facio(
        _ role: FacioButtonRole = .primary,
        density: FacioLayout.Density = FacioLayout.density
    ) -> FacioButtonStyle {
        FacioButtonStyle(role: role, density: density)
    }
}

/// Bouton prêt à l'emploi : accent ambiant, anneau de focus clavier, et état
/// de chargement.
///
/// **Chargement.** Aucun bouton de l'app ne pouvait afficher un travail en
/// cours — il n'existait qu'un seul indicateur de progression dans tout le
/// produit. Le bouton garde sa largeur (les deux libellés sont empilés, la
/// pile prend le plus large), passe au participe présent, et devient
/// non actionnable SANS emprunter l'opacité du désactivé : un bouton qui
/// travaille n'est pas un bouton indisponible.
struct FacioButton: View {
    let title: String
    var systemImage: String?
    var role: FacioButtonRole = .primary
    var density: FacioLayout.Density = FacioLayout.density
    /// Travail en cours : le libellé passe à `loadingTitle` et le bouton
    /// n'accepte plus de clic.
    var isLoading: Bool = false
    /// Libellé au participe présent (« Envoi… », « Génération du PDF… »).
    var loadingTitle: String?
    let action: () -> Void

    @FocusState private var isFocused: Bool

    init(
        _ title: String,
        systemImage: String? = nil,
        role: FacioButtonRole = .primary,
        density: FacioLayout.Density = FacioLayout.density,
        isLoading: Bool = false,
        loadingTitle: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.density = density
        self.isLoading = isLoading
        self.loadingTitle = loadingTitle
        self.action = action
    }

    var body: some View {
        Button {
            guard !isLoading else { return }
            action()
        } label: {
            // Les deux états sont empilés : la pile prend la largeur du plus
            // large, donc basculer en chargement ne déplace rien autour.
            ZStack {
                restingLabel.opacity(isLoading ? 0 : 1)
                loadingLabel.opacity(isLoading ? 1 : 0)
            }
        }
        .buttonStyle(.facio(role, density: density))
        .focused($isFocused)
        .facioFocusRing(isFocused, radius: FacioLayout.radiusSmall)
        .allowsHitTesting(!isLoading)
        .accessibilityLabel(isLoading ? (loadingTitle ?? title) : title)
    }

    @ViewBuilder
    private var restingLabel: some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(title)
        }
    }

    private var loadingLabel: some View {
        HStack(spacing: FacioLayout.space8) {
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.7)
                .frame(width: 12, height: 12)
            Text(loadingTitle ?? title)
        }
    }
}

// MARK: - Bouton-icône

/// Ce qu'un bouton-icône fait à la donnée. Un `ellipsis.circle` qui supprime et
/// un qui duplique ne peuvent pas se ressembler.
enum FacioIconButtonRole {
    case normal
    case destructive
}

/// Bouton-icône.
///
/// **Le libellé d'accessibilité est obligatoire.** Les onze boutons-icône de
/// l'app n'en portaient aucun : leur seul porteur de sens était `.help()`,
/// c'est-à-dire une infobulle au survol de la souris — invisible au clavier et
/// à VoiceOver. Et `help` avait pour défaut la chaîne vide, ce qui attachait
/// une infobulle vide à chacun.
struct FacioIconButton: View {
    let systemImage: String
    /// Obligatoire : ce que fait le bouton, en toutes lettres.
    let label: String
    var role: FacioIconButtonRole = .normal
    /// Teinte explicite, quand le glyphe porte lui-même un sens (le « play »
    /// vert d'une tâche). À défaut, le rôle décide.
    var tone: Color?
    var isEnabled: Bool = true
    /// Infobulle. À défaut, le libellé sert aussi d'infobulle.
    var help: String?
    let action: () -> Void

    @State private var isHovering = false
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        systemImage: String,
        label: String,
        role: FacioIconButtonRole = .normal,
        tone: Color? = nil,
        isEnabled: Bool = true,
        help: String? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.label = label
        self.role = role
        self.tone = tone
        self.isEnabled = isEnabled
        self.help = help
        self.action = action
    }

    /// Le destructif a une cible élargie : il ne doit pas être atteint par
    /// erreur dans une rangée dense d'icônes de même poids.
    private var side: CGFloat {
        role == .destructive ? FacioLayout.iconHitTarget + FacioLayout.space4 : FacioLayout.iconHitTarget
    }

    private var resolvedTone: Color {
        if let tone { return tone }
        return role == .destructive ? FacioIntent.danger.glyph : .textSecondary
    }

    private var hoverFill: Color {
        role == .destructive ? FacioIntent.danger.tint : .surfaceHover
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(FacioFont.body)
                .foregroundStyle(isEnabled ? resolvedTone : resolvedTone.opacity(0.35))
                .frame(width: side, height: side)
                .background(isHovering && isEnabled ? hoverFill : .clear)
                .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusSmall))
                .contentShape(RoundedRectangle(cornerRadius: FacioLayout.radiusSmall))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .focused($isFocused)
        .facioFocusRing(isFocused, radius: FacioLayout.radiusSmall)
        .animation(FacioMotion.respecting(FacioMotion.hover, reduceMotion: reduceMotion), value: isHovering)
        .onHover { isHovering = $0 }
        .help(help ?? label)
        .accessibilityLabel(label)
    }
}
