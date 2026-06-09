import SwiftUI

/// Champ de saisie tokenisé avec erreur **visible inline** (et non en tooltip).
///
/// Remplace les `TextField().textFieldStyle(.roundedBorder)` répétés et offre
/// un état focus et un état d'erreur explicites.
struct FacioTextField: View {
    let placeholder: String
    @Binding var text: String
    var systemImage: String?
    var error: String?
    var alignment: TextAlignment = .leading

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space4) {
            HStack(spacing: FacioLayout.space8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(alignment)
                    .focused($isFocused)
            }
            .padding(.horizontal, FacioLayout.space10)
            .padding(.vertical, FacioLayout.space8)
            .background(Color.surfaceField)
            .overlay(
                RoundedRectangle(cornerRadius: FacioLayout.radiusField)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusField))

            if let error, !error.isEmpty {
                Text(error)
                    .font(FacioFont.captionSmall)
                    .foregroundStyle(Color.intentDanger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var borderColor: Color {
        if error?.isEmpty == false { return .intentDanger }
        return isFocused ? .borderHover : .borderSubtle
    }
}
