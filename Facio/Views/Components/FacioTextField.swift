import SwiftUI

/// Densité du chrome d'un champ : `regular` pour les formulaires,
/// `compact` pour les lignes de tableau et les barres de saisie denses.
enum FacioFieldDensity {
    case regular
    case compact
}

/// Chrome tokenisé d'un champ de saisie, appliqué à un `TextField`/`SecureField`
/// natif via `.facioField(error:density:)` : fond `surfaceField`, bordure avec
/// états focus/erreur, et message d'erreur inline en densité `regular` (en
/// `compact`, seule la bordure signale l'erreur pour ne pas casser la hauteur
/// des lignes). Source unique du style de champ — `FacioTextField` s'appuie dessus.
struct FacioFieldModifier: ViewModifier {
    var error: String?
    var density: FacioFieldDensity = .regular

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

            if density == .regular, let error, !error.isEmpty {
                Text(error)
                    .font(FacioFont.label)
                    .foregroundStyle(FacioIntent.danger.onTint)
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
    func facioField(error: String? = nil, density: FacioFieldDensity = .regular) -> some View {
        modifier(FacioFieldModifier(error: error, density: density))
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
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            TextField(placeholder, text: $text)
                .multilineTextAlignment(alignment)
        }
        .facioField(error: error)
    }
}
