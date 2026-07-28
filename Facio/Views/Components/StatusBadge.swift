import SwiftUI

struct StatusBadge: View {
    let status: DocumentStatus
    var isOverdue: Bool = false
    /// Facture « Payée » mais réglée en plusieurs versements : badge distinct.
    var paidViaInstallments: Bool = false
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var color: Color { isOverdue ? Color.intentDanger : Color.statusColor(for: status) }
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
        Label(label, systemImage: icon)
            .font(FacioFont.captionSmall)
            .fontWeight(.medium)
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, FacioLayout.space8)
            .padding(.vertical, FacioLayout.space4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
