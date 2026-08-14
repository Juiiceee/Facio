import SwiftUI

/// Champ de formulaire libellé : label au-dessus du contenu.
///
/// Source unique remplaçant les copies privées de `settingsRow` disséminées
/// dans les écrans Réglages et Clients.
///
/// Le libellé est **lié programmatiquement** au contrôle : c'était un simple
/// `Text` posé au-dessus, donc VoiceOver annonçait le placeholder et jamais le
/// libellé. Et le caractère obligatoire d'un champ (SIRET, TVA — sans eux
/// l'export Factur-X est refusé) n'était visible nulle part avant l'échec.
struct LabeledField<Content: View>: View {
    let label: String
    /// Marqueur visible ET annoncé. À réserver aux champs dont l'absence
    /// bloque une action (mentions légales, IBAN d'un virement).
    var isRequired: Bool = false
    /// Aide sous le champ, en texte — jamais en infobulle seule.
    var hint: String?
    let lang: AppLanguage
    @ViewBuilder let content: Content

    init(
        _ label: String,
        lang: AppLanguage = .fr,
        isRequired: Bool = false,
        hint: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.lang = lang
        self.isRequired = isRequired
        self.hint = hint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space4) {
            HStack(spacing: FacioLayout.space4) {
                Text(label)
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textSecondary)
                if isRequired {
                    Text(verbatim: "✱")
                        .font(FacioFont.label)
                        .foregroundStyle(FacioIntent.danger.glyph)
                        .accessibilityHidden(true)
                }
            }

            content

            if let hint, !hint.isEmpty {
                Text(hint)
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // `.contain` garde le champ éditable et manipulable, tout en donnant au
        // groupe un libellé : l'astérisque devient un mot, pas un glyphe muet.
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isRequired ? "\(label), \(L10n.fieldRequired(lang))" : label)
    }
}
