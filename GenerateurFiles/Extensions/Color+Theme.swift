import SwiftUI

extension Color {
    // MARK: - Couleurs principales de l'app

    /// Vert principal (barre de titre, en-tête tableau)
    static let appPrimary = Color(red: 0.33, green: 0.54, blue: 0.19)

    /// Vert clair pour les lignes alternées du tableau
    static let appPrimaryLight = Color(red: 0.33, green: 0.54, blue: 0.19).opacity(0.08)

    /// Fond de la sidebar
    static let sidebarBackground = Color(nsColor: .controlBackgroundColor)

    /// Couleur de texte secondaire
    static let textSecondary = Color.secondary

    // MARK: - Couleurs de statut

    static let statusBrouillon = Color.gray
    static let statusEnvoyee = Color.orange
    static let statusPayee = Color.green
    static let statusAnnulee = Color.red

    static func statusColor(for status: DocumentStatus) -> Color {
        switch status {
        case .brouillon: return .statusBrouillon
        case .envoyee: return .statusEnvoyee
        case .payee: return .statusPayee
        case .annulee: return .statusAnnulee
        }
    }
}
