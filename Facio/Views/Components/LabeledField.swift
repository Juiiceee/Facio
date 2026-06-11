import SwiftUI

/// Champ de formulaire libellé : label au-dessus du contenu.
///
/// Source unique remplaçant les copies privées de `settingsRow` disséminées
/// dans les écrans Réglages et Clients.
struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space4) {
            Text(label)
                .font(FacioFont.fieldLabel)
                .foregroundStyle(.secondary)
            content
        }
    }
}
