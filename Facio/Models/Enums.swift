import Foundation

// MARK: - Mode de paiement

enum PaymentMode: String, Codable, CaseIterable, Identifiable {
    case aucun = "Aucun"
    case virement = "Virement"
    case crypto = "Crypto"

    var id: String { rawValue }
    var label: String { label(for: .fr) }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .aucun: return L10n.paymentNone(lang)
        case .virement: return L10n.paymentTransfer(lang)
        case .crypto: return L10n.paymentCrypto(lang)
        }
    }
}

// MARK: - Type de document

enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case facture = "Facture"
    case devis = "Devis"

    var id: String { rawValue }

    var label: String { label(for: .fr) }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .facture: return L10n.invoice(lang)
        case .devis: return L10n.quote(lang)
        }
    }

    var prefix: String {
        prefix(for: .fr)
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

    var label: String { label(for: .fr) }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .brouillon: return L10n.draft(lang)
        case .envoyee: return L10n.sent(lang)
        case .payee: return L10n.paid(lang)
        case .annulee: return L10n.cancelled(lang)
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
