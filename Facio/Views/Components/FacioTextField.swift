import SwiftUI

/// Densité du chrome d'un champ : `regular` pour les formulaires,
/// `compact` pour les lignes de tableau et les barres de saisie denses.
enum FacioFieldDensity {
    case regular
    case compact
}

/// Chrome tokenisé d'un champ de saisie, appliqué à un `TextField`/`SecureField`
/// natif via `.facioField(error:density:disabledReason:)` : fond `surfaceField`,
/// bordure avec états focus/erreur, anneau de focus clavier, et message d'erreur
/// rendu **en texte dans les deux densités**. Source unique du style de champ —
/// `FacioTextField` s'appuie dessus.
struct FacioFieldModifier: ViewModifier {
    var error: String?
    var density: FacioFieldDensity = .regular
    /// Raison, en texte, pour laquelle le champ n'accepte pas de saisie —
    /// « piloté par le minuteur » plutôt qu'un champ grisé et muet.
    var disabledReason: String?

    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space4) {
            content
                .textFieldStyle(.plain)
                .focused($isFocused)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, density == .regular ? FacioLayout.space12 : FacioLayout.space8)
                .padding(.vertical, density == .regular ? FacioLayout.space8 : FacioLayout.space4)
                .frame(minHeight: FacioLayout.density.controlHeight)
                .background(Color.surfaceFieldToken)
                .overlay(
                    RoundedRectangle(cornerRadius: FacioLayout.radiusSmall)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusSmall))
                // Le seul indice de focus était un passage de bordure de 8 % à
                // 14 % de noir : 6 % d'alpha sur 1 pt, invisible. L'anneau
                // partagé le remplace.
                .facioFocusRing(isFocused && error?.isEmpty != false, radius: FacioLayout.radiusSmall)

            // L'erreur est rendue en TEXTE dans les deux densités. En compact
            // elle ne l'était pas : le message n'existait qu'en infobulle, donc
            // la valeur fautive restait dans le champ pendant que le modèle
            // gardait silencieusement l'ancienne — l'interface et la donnée
            // divergeaient sans le moindre signal visible.
            if let error, !error.isEmpty {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(FacioFont.label)
                    .foregroundStyle(FacioIntent.danger.onTint)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isStaticText)
            } else if let disabledReason, !disabledReason.isEmpty {
                Label(disabledReason, systemImage: "bolt.horizontal.circle")
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var borderColor: Color {
        if error?.isEmpty == false { return FacioIntent.danger.glyph }
        return isFocused ? .borderStrong : .borderHairlineToken
    }
}

extension View {
    /// Applique le chrome de champ du design system à un champ de saisie natif.
    /// Remplace les `.textFieldStyle(.roundedBorder)` disséminés dans les vues.
    func facioField(
        error: String? = nil,
        density: FacioFieldDensity = .regular,
        disabledReason: String? = nil
    ) -> some View {
        modifier(FacioFieldModifier(error: error, density: density, disabledReason: disabledReason))
    }
}

/// Champ de saisie tokenisé avec erreur **visible inline** (et non en tooltip).
///
/// Variante « riche » du chrome `.facioField` pour les cas avec icône d'appoint ;
/// pour un champ nu, appliquer directement `.facioField()` au `TextField` natif.
struct FacioTextField: View {
    let placeholder: String
    @Binding var text: String
    var systemImage: String?
    var error: String?
    var alignment: TextAlignment = .leading

    var body: some View {
        HStack(spacing: FacioLayout.space8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.textSecondary)
                    .font(FacioFont.label)
            }
            TextField(placeholder, text: $text)
                .multilineTextAlignment(alignment)
        }
        .facioField(error: error)
    }
}
