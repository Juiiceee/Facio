import Foundation

// MARK: - Jour de la semaine

enum JourSemaine: Int, Codable, CaseIterable, Identifiable {
    case lundi = 0, mardi, mercredi, jeudi, vendredi, samedi, dimanche

    var id: Int { rawValue }

    var label: String {
        label(for: .fr)
    }

    var shortLabel: String {
        shortLabel(for: .fr)
    }

    func label(for lang: AppLanguage) -> String {
        L10n.weekdayLabel(rawValue, lang)
    }

    func shortLabel(for lang: AppLanguage) -> String {
        L10n.weekdayShort(rawValue, lang)
    }
}
