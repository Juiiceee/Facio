import Foundation

// MARK: - Labels des enums (DocumentType, DocumentStatus, PaymentMode)

extension L10n {

    // DocumentType
    static func invoice(_ l: AppLanguage) -> String { l == .fr ? "Facture" : "Invoice" }
    static func quote(_ l: AppLanguage) -> String { l == .fr ? "Devis" : "Quote" }

    // DocumentStatus
    static func draft(_ l: AppLanguage) -> String { l == .fr ? "Brouillon" : "Draft" }
    static func sent(_ l: AppLanguage) -> String { l == .fr ? "Envoyée" : "Sent" }
    static func paid(_ l: AppLanguage) -> String { l == .fr ? "Payée" : "Paid" }
    static func cancelled(_ l: AppLanguage) -> String { l == .fr ? "Annulée" : "Cancelled" }

    // PaymentMode
    static func paymentNone(_ l: AppLanguage) -> String { l == .fr ? "Aucun" : "None" }
    static func paymentTransfer(_ l: AppLanguage) -> String { l == .fr ? "Virement" : "Bank transfer" }
    static func paymentCrypto(_ l: AppLanguage) -> String { "Crypto" }
}
