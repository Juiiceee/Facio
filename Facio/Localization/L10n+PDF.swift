import Foundation

// MARK: - Textes du PDF (factures & devis)

extension L10n {

    // Dates
    static func invoiceDate(_ l: AppLanguage) -> String { l == .fr ? "Date de facture: " : "Invoice date: " }
    static func quoteDate(_ l: AppLanguage) -> String { l == .fr ? "Date du devis: " : "Quote date: " }
    static func dueDate(_ l: AppLanguage) -> String { l == .fr ? "Echeance: " : "Due date: " }
    static func recipient(_ l: AppLanguage) -> String { l == .fr ? "DESTINATAIRE" : "RECIPIENT" }

    // Tableau
    static func designation(_ l: AppLanguage) -> String { l == .fr ? "DESIGNATION" : "DESCRIPTION" }
    static func quantity(_ l: AppLanguage) -> String { l == .fr ? "QUANTITE" : "QUANTITY" }
    static func price(_ l: AppLanguage) -> String { l == .fr ? "PRIX" : "PRICE" }
    static func total(_ l: AppLanguage) -> String { "TOTAL" }
    static func vat(_ l: AppLanguage) -> String { l == .fr ? "TVA" : "VAT" }

    // Totaux
    static func totalHT(_ l: AppLanguage) -> String { l == .fr ? "Total HT" : "Subtotal" }
    static func totalVAT(_ l: AppLanguage) -> String { l == .fr ? "TVA" : "VAT" }
    static func vatRate(_ l: AppLanguage, rate: String) -> String { l == .fr ? "TVA \(rate)%" : "VAT \(rate)%" }
    static func totalTVA(_ l: AppLanguage) -> String { l == .fr ? "Total TVA" : "Total VAT" }
    static func totalTTC(_ l: AppLanguage) -> String { l == .fr ? "Total TTC" : "Total incl. tax" }

    // Paiement (PDF footer)
    static func paymentProofs(_ l: AppLanguage) -> String { l == .fr ? "PREUVES DE PAIEMENT" : "PAYMENT PROOFS" }
    static func txPrefix(_ l: AppLanguage) -> String { "TX: " }
    static func bankTransfer(_ l: AppLanguage) -> String { l == .fr ? "Virement bancaire" : "Bank transfer" }
    static func cryptoTransfer(_ l: AppLanguage) -> String { l == .fr ? "Transfert Cryptomonnaie" : "Cryptocurrency transfer" }
    static func walletAddress(_ l: AppLanguage) -> String { l == .fr ? "Wallet adresse:" : "Wallet address:" }
    static func accountHolder(_ l: AppLanguage) -> String { l == .fr ? "Titulaire: " : "Holder: " }
    static func scanToPay(_ l: AppLanguage) -> String { l == .fr ? "Scanner pour payer" : "Scan to pay" }
    static func companyFallback(_ l: AppLanguage) -> String { l == .fr ? "ENTREPRISE" : "COMPANY" }
}
