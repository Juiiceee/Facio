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
/// Sans `accent` explicite, le style suit l'accent de marque ambiant.
struct FacioButtonStyle: ButtonStyle {
    var role: FacioButtonRole = .primary
    var accent: Color? = nil

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.facioAccent) private var ambientAccent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FacioFont.rowTitle)
            .lineLimit(1)
            .padding(.horizontal, FacioLayout.space12)
            .padding(.vertical, FacioLayout.space8)
            .frame(minHeight: FacioLayout.iconHitTarget)
            .foregroundStyle(foreground)
            .background(background(pressed: configuration.isPressed))
            .overlay(
                RoundedRectangle(cornerRadius: FacioLayout.radiusField)
                    .strokeBorder(border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusField))
            .contentShape(RoundedRectangle(cornerRadius: FacioLayout.radiusField))
            .opacity(isEnabled ? 1 : 0.45)
            .animation(FacioMotion.respecting(FacioMotion.hover, reduceMotion: reduceMotion), value: configuration.isPressed)
    }

    private var fill: Color {
        switch role {
        case .primary: return accent ?? ambientAccent
        case .secondary: return .surfaceTile
        case .destructive: return .intentDanger
        }
    }

    private var foreground: Color {
        switch role {
        case .primary, .destructive: return .white
        case .secondary: return .primary
        }
    }

    private var border: Color {
        switch role {
        case .primary, .destructive: return .clear
        case .secondary: return .borderSubtle
        }
    }

    private func background(pressed: Bool) -> Color {
        switch role {
        case .primary, .destructive:
            return pressed ? fill.opacity(0.82) : fill
        case .secondary:
            return pressed ? .surfaceRowHover : fill
        }
    }
}

extension ButtonStyle where Self == FacioButtonStyle {
    static func facio(_ role: FacioButtonRole = .primary, accent: Color? = nil) -> FacioButtonStyle {
        FacioButtonStyle(role: role, accent: accent)
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
                .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusField))
                .contentShape(RoundedRectangle(cornerRadius: FacioLayout.radiusField))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(FacioMotion.respecting(FacioMotion.hover, reduceMotion: reduceMotion), value: isHovering)
        .onHover { isHovering = $0 }
        .help(help ?? "")
    }
}
