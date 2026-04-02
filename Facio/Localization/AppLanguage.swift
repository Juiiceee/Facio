import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case fr = "fr"
    case en = "en"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fr: return "Francais"
        case .en: return "English"
        }
    }
}
