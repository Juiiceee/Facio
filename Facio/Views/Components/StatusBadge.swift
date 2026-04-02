import SwiftUI

struct StatusBadge: View {
    let status: DocumentStatus
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        Text(status.label(for: lang))
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.statusColor(for: status).opacity(0.15))
            .foregroundStyle(Color.statusColor(for: status))
            .clipShape(Capsule())
            .fixedSize()
    }
}
