import SwiftUI

struct StatusBadge: View {
    let status: DocumentStatus
    var isOverdue: Bool = false
    /// Facture « Payée » mais réglée en plusieurs versements : badge distinct.
    var paidViaInstallments: Bool = false
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var intent: FacioIntent {
        isOverdue ? Color.intentDangerTriple : Color.statusIntent(for: status)
    }
    private var label: String {
        if isOverdue { return L10n.overdue(lang) }
        if paidViaInstallments { return L10n.paidInInstallments(lang) }
        return status.label(for: lang)
    }
    private var icon: String {
        if isOverdue { return "exclamationmark.triangle.fill" }
        if paidViaInstallments { return "calendar.badge.checkmark" }
        switch status {
        case .brouillon: return "pencil"
        case .envoyee: return "paperplane.fill"
        case .partiel: return "circle.lefthalf.filled"
        case .payee: return "checkmark.circle.fill"
        case .annulee: return "xmark.circle.fill"
        }
    }

    var body: some View {
        // Le badge posait l'aplat à 14 % en fond ET le même aplat en texte de
        // 11 pt : un contraste que rien ne garantissait, et qui s'est éteint
        // quand les aplats ont été recalés sur le seuil du texte. Fond et texte
        // sortent maintenant de la paire mesurée `tint` / `onTint`, et l'icône
        // — qui ne porte pas de texte — prend la valeur vive.
        HStack(spacing: FacioLayout.space4) {
            Image(systemName: icon)
                .foregroundStyle(intent.glyph)
            Text(label)
                .foregroundStyle(intent.onTint)
        }
        .font(FacioFont.label)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, FacioLayout.space8)
        .frame(minHeight: FacioLayout.density.badgeHeight)
        .background(intent.tint)
        .clipShape(Capsule())
    }
}
