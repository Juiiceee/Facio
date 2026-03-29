import Foundation

// MARK: - Mode de paiement

enum PaymentMode: String, Codable, CaseIterable, Identifiable {
    case aucun = "Aucun"
    case virement = "Virement"
    case crypto = "Crypto"

    var id: String { rawValue }
    var label: String { rawValue }
}

// MARK: - Type de document

enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case facture = "Facture"
    case devis = "Devis"

    var id: String { rawValue }

    var label: String { rawValue }

    var prefix: String {
        switch self {
        case .facture: return "Facture"
        case .devis: return "Devis"
        }
    }
}

// MARK: - Statut du document

enum DocumentStatus: String, Codable, CaseIterable, Identifiable {
    case brouillon = "Brouillon"
    case envoyee = "Envoyée"
    case payee = "Payée"
    case annulee = "Annulée"

    var id: String { rawValue }

    var label: String { rawValue }

    var color: String {
        switch self {
        case .brouillon: return "gray"
        case .envoyee: return "orange"
        case .payee: return "green"
        case .annulee: return "red"
        }
    }
}
