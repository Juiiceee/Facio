import SwiftUI

/// Hiérarchie d'action de Facio. Un seul vocabulaire de boutons pour toute l'app.
enum FacioButtonRole {
    /// Action principale d'un contexte — fond plein accent de marque.
    case primary
    /// Action secondaire — surface discrète bordée.
    case secondary
    /// Action destructive — fond plein rouge.
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
        }
    }

    func border(accent: Color, scheme: ColorScheme) -> Color {
        switch self {
        case .primary: return Self.accentUnusable(accent, scheme) ? .borderStrong : .clear
        case .destructive: return .clear
        case .secondary: return .borderHairlineToken
        }
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
struct FacioButtonStyle: ButtonStyle {
    var role: FacioButtonRole = .primary

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.facioAccent) private var ambientAccent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FacioFont.rowTitle)
            .lineLimit(1)
            .padding(.horizontal, FacioLayout.space12)
            .padding(.vertical, FacioLayout.space8)
            .frame(minHeight: FacioLayout.density.controlHeight)
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
        }
    }
}

extension ButtonStyle where Self == FacioButtonStyle {
    // Le paramètre `accent:` a disparu : aucune vue ne s'en servait, et il
    // court-circuitait le calcul de la couleur de texte.
    static func facio(_ role: FacioButtonRole = .primary) -> FacioButtonStyle {
        FacioButtonStyle(role: role)
    }
}

/// Bouton prêt à l'emploi suivant l'accent de marque ambiant.
struct FacioButton: View {
    let title: String
    var systemImage: String?
    var role: FacioButtonRole = .primary
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, role: FacioButtonRole = .primary, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .buttonStyle(.facio(role))
    }
}

/// Bouton-icône avec cible de clic ≥ 28 pt et fond au survol.
/// Remplace les glyphes nus disséminés dans l'app.
struct FacioIconButton: View {
    let systemImage: String
    var tone: Color = .secondary
    var help: String?
    var isEnabled: Bool = true
    let action: () -> Void

    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(isEnabled ? tone : tone.opacity(0.35))
                .frame(width: FacioLayout.iconHitTarget, height: FacioLayout.iconHitTarget)
                .background(isHovering && isEnabled ? Color.borderSubtle : .clear)
                .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusSmall))
                .contentShape(RoundedRectangle(cornerRadius: FacioLayout.radiusSmall))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(FacioMotion.respecting(FacioMotion.hover, reduceMotion: reduceMotion), value: isHovering)
        .onHover { isHovering = $0 }
        .help(help ?? "")
    }
}
