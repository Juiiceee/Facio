import SwiftUI

/// Ligne de formulaire libellé + contenu, alignée en colonne.
///
/// Source unique remplaçant les copies privées de `settingsRow` disséminées
/// dans les écrans Réglages et Clients.
struct LabeledField<Content: View>: View {
    let label: String
    var labelWidth: CGFloat
    var alignment: VerticalAlignment
    @ViewBuilder let content: Content

    init(
        _ label: String,
        labelWidth: CGFloat = 160,
        alignment: VerticalAlignment = .firstTextBaseline,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.labelWidth = labelWidth
        self.alignment = alignment
        self.content = content()
    }

    var body: some View {
        HStack(alignment: alignment, spacing: FacioLayout.space12) {
            Text(label)
                .font(FacioFont.caption)
                .foregroundStyle(.secondary)
                .frame(width: labelWidth, alignment: .leading)
            content
            Spacer(minLength: 0)
        }
    }
}
