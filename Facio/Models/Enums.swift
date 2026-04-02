import Foundation

// MARK: - Mode de paiement

enum PaymentMode: String, Codable, CaseIterable, Identifiable {
    case aucun = "Aucun"
    case virement = "Virement"
    case crypto = "Crypto"

    var id: String { rawValue }
    var label: String { rawValue }

    func label(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.aucun, .fr): return "Aucun"
        case (.aucun, .en): return "None"
        case (.virement, .fr): return "Virement"
        case (.virement, .en): return "Bank transfer"
        case (.crypto, _): return "Crypto"
        }
    }
}

// MARK: - Type de document

enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case facture = "Facture"
    case devis = "Devis"

    var id: String { rawValue }

    var label: String { rawValue }

    func label(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.facture, .fr): return "Facture"
        case (.facture, .en): return "Invoice"
        case (.devis, .fr): return "Devis"
        case (.devis, .en): return "Quote"
        }
    }

    var prefix: String {
        switch self {
        case .facture: return "Facture"
        case .devis: return "Devis"
        }
    }

    func prefix(for lang: AppLanguage) -> String {
        label(for: lang)
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

    func label(for lang: AppLanguage) -> String {
        switch (self, lang) {
        case (.brouillon, .fr): return "Brouillon"
        case (.brouillon, .en): return "Draft"
        case (.envoyee, .fr): return "Envoyee"
        case (.envoyee, .en): return "Sent"
        case (.payee, .fr): return "Payee"
        case (.payee, .en): return "Paid"
        case (.annulee, .fr): return "Annulee"
        case (.annulee, .en): return "Cancelled"
        }
    }

    var color: String {
        switch self {
        case .brouillon: return "gray"
        case .envoyee: return "orange"
        case .payee: return "green"
        case .annulee: return "red"
        }
    }
}
