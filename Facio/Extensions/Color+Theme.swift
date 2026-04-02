import SwiftUI

extension Color {
    // MARK: - Couleurs principales de l'app
    // Note: static var au lieu de static let pour eviter un crash du compilateur Swift 6.0.x en release

    /// Vert principal (barre de titre, en-tete tableau)
    static var appPrimary: Color { Color(red: 0.33, green: 0.54, blue: 0.19) }

    /// Vert clair pour les lignes alternees du tableau
    static var appPrimaryLight: Color { Color(red: 0.33, green: 0.54, blue: 0.19).opacity(0.08) }

    /// Couleur principale dynamique (depuis CompanyInfo)
    static func appPrimary(from company: CompanyInfo) -> Color {
        guard let hex = company.couleurAccentHex,
              let ns = NSColor.fromHex(hex) else { return appPrimary }
        return Color(nsColor: ns)
    }

    /// Fond de la sidebar
    static var sidebarBackground: Color { Color(nsColor: .controlBackgroundColor) }

    // MARK: - Couleurs de statut

    static var statusBrouillon: Color { .gray }
    static var statusEnvoyee: Color { .orange }
    static var statusPayee: Color { .green }
    static var statusAnnulee: Color { .red }

    static func statusColor(for status: DocumentStatus) -> Color {
        switch status {
        case .brouillon: return .statusBrouillon
        case .envoyee: return .statusEnvoyee
        case .payee: return .statusPayee
        case .annulee: return .statusAnnulee
        }
    }
}
