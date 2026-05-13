import SwiftUI

struct StatusBadge: View {
    let status: DocumentStatus
    var isOverdue: Bool = false
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var color: Color { isOverdue ? .red : Color.statusColor(for: status) }
    private var label: String { isOverdue ? L10n.overdue(lang) : status.label(for: lang) }

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .fixedSize()
    }
}
