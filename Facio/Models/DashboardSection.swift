import Foundation

/// Un bloc du tableau de bord, dans l'ordre où l'utilisateur veut le lire.
///
/// L'écran imposait le même ordre à tout le monde : chiffres, graphique, à
/// traiter, activité récente. Or ce qu'on ouvre le matin dépend du métier —
/// certains veulent d'abord ce qui est en retard, d'autres la courbe.
enum DashboardSection: String, CaseIterable, Identifiable, Codable {
    case kpis
    case chart
    case focus
    case recent

    var id: String { rawValue }

    /// L'ordre livré par défaut, et le repli quand la préférence est illisible.
    static let defaultOrder: [DashboardSection] = [.kpis, .chart, .focus, .recent]

    func label(for l: AppLanguage) -> String {
        switch self {
        case .kpis: return l == .fr ? "Chiffres clés" : "Key figures"
        case .chart: return l == .fr ? "Graphique des encaissements" : "Revenue chart"
        case .focus: return l == .fr ? "À traiter" : "Needs attention"
        case .recent: return l == .fr ? "Activité récente" : "Recent activity"
        }
    }

    var systemImage: String {
        switch self {
        case .kpis: return "square.grid.2x2"
        case .chart: return "chart.bar"
        case .focus: return "exclamationmark.triangle"
        case .recent: return "clock.arrow.circlepath"
        }
    }

    /// Remet une préférence enregistrée en ordre utilisable.
    ///
    /// Une liste persistée peut avoir vieilli : bloc supprimé d'une version à
    /// l'autre, bloc ajouté que l'ancienne préférence ignore, doublon introduit
    /// par une synchronisation. On garde l'ordre voulu pour ce qu'on reconnaît,
    /// puis on ajoute à la fin ce qui manque — jamais d'écran vide.
    static func normalizedOrder(from stored: [String]) -> [DashboardSection] {
        var seen = Set<DashboardSection>()
        var result: [DashboardSection] = []
        for raw in stored {
            guard let section = DashboardSection(rawValue: raw), !seen.contains(section) else { continue }
            seen.insert(section)
            result.append(section)
        }
        for section in defaultOrder where !seen.contains(section) {
            result.append(section)
        }
        return result
    }
}
