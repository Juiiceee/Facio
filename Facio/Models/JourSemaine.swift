import Foundation

// MARK: - Jour de la semaine

enum JourSemaine: Int, Codable, CaseIterable, Identifiable {
    case lundi = 0, mardi, mercredi, jeudi, vendredi, samedi, dimanche

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .lundi: return "Lundi"
        case .mardi: return "Mardi"
        case .mercredi: return "Mercredi"
        case .jeudi: return "Jeudi"
        case .vendredi: return "Vendredi"
        case .samedi: return "Samedi"
        case .dimanche: return "Dimanche"
        }
    }

    var shortLabel: String {
        switch self {
        case .lundi: return "Lun"
        case .mardi: return "Mar"
        case .mercredi: return "Mer"
        case .jeudi: return "Jeu"
        case .vendredi: return "Ven"
        case .samedi: return "Sam"
        case .dimanche: return "Dim"
        }
    }

    func label(for lang: AppLanguage) -> String {
        L10n.weekdayLabel(rawValue, lang)
    }

    func shortLabel(for lang: AppLanguage) -> String {
        L10n.weekdayShort(rawValue, lang)
    }
}
