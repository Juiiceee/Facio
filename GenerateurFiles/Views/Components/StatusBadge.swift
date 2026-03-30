import SwiftUI

struct StatusBadge: View {
    let status: DocumentStatus

    var body: some View {
        Text(status.label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.statusColor(for: status).opacity(0.15))
            .foregroundStyle(Color.statusColor(for: status))
            .clipShape(Capsule())
    }
}
