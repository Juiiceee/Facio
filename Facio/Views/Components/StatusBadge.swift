import SwiftUI

struct StatusBadge: View {
    let status: DocumentStatus
    var isOverdue: Bool = false
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var color: Color { isOverdue ? .red : Color.statusColor(for: status) }
    private var label: String { isOverdue ? L10n.overdue(lang) : status.label(for: lang) }
    private var icon: String {
        if isOverdue { return "exclamationmark.triangle.fill" }
        switch status {
        case .brouillon: return "pencil"
        case .envoyee: return "paperplane.fill"
        case .payee: return "checkmark.circle.fill"
        case .annulee: return "xmark.circle.fill"
        }
    }

    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption2)
            .fontWeight(.medium)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .fixedSize()
    }
}
