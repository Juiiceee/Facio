import Foundation

// MARK: - Textes du PDF (factures & devis)

extension L10n {

    // Dates
    static func invoiceDate(_ l: AppLanguage) -> String { l == .fr ? "Date de facture: " : "Invoice date: " }
    static func quoteDate(_ l: AppLanguage) -> String { l == .fr ? "Date du devis: " : "Quote date: " }
    static func dueDate(_ l: AppLanguage) -> String { l == .fr ? "Échéance: " : "Due date: " }
    static func recipient(_ l: AppLanguage) -> String { l == .fr ? "DESTINATAIRE" : "RECIPIENT" }

    // Tableau
    static func designation(_ l: AppLanguage) -> String { l == .fr ? "DÉSIGNATION" : "DESCRIPTION" }
    static func quantity(_ l: AppLanguage) -> String { l == .fr ? "QUANTITÉ" : "QUANTITY" }
    static func price(_ l: AppLanguage) -> String { l == .fr ? "PRIX" : "PRICE" }
    static func total(_ l: AppLanguage) -> String { "TOTAL" }
    static func vat(_ l: AppLanguage) -> String { l == .fr ? "TVA" : "VAT" }
    /// L'app générait des PDF sans jamais offrir de les imprimer.
    static func printDocument(_ l: AppLanguage) -> String { l == .fr ? "Imprimer" : "Print" }
    static func printFailed(_ l: AppLanguage) -> String {
        l == .fr ? "L'impression n'a pas pu démarrer." : "Printing could not start."
    }

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
    static func walletAddress(_ l: AppLanguage) -> String { l == .fr ? "Adresse wallet:" : "Wallet address:" }
    static func accountHolder(_ l: AppLanguage) -> String { l == .fr ? "Titulaire: " : "Holder: " }
    static func siret(_ l: AppLanguage) -> String { "SIRET" }
    static func phoneShort(_ l: AppLanguage) -> String { l == .fr ? "Tel" : "Phone" }
    static func scanToPay(_ l: AppLanguage) -> String { l == .fr ? "Scanner pour payer" : "Scan to pay" }
    static func companyFallback(_ l: AppLanguage) -> String { l == .fr ? "ENTREPRISE" : "COMPANY" }
    static func notesLabel(_ l: AppLanguage) -> String { l == .fr ? "NOTES" : "NOTES" }
    static func defaultPDFName(_ l: AppLanguage) -> String { l == .fr ? "document" : "document" }
    static func paymentProofVia(_ l: AppLanguage) -> String { l == .fr ? "via" : "via" }
    // MARK: - Mentions légales
    //
    // La page visible n'imprimait RIEN de tout ceci : ni conditions de
    // règlement, ni pénalités de retard, ni indemnité forfaitaire de 40 €, ni
    // TVA de l'émetteur, ni son adresse. Une facture française sans ces mentions
    // n'est pas valide, et l'utilisateur ne l'apprenait nulle part.
    static func pdfLegalHeading(_ l: AppLanguage) -> String {
        l == .fr ? "CONDITIONS DE RÈGLEMENT ET MENTIONS LÉGALES" : "PAYMENT TERMS AND LEGAL NOTICES"
    }
    static func pdfLegalTerms(_ l: AppLanguage, dueDate: String, days: Int) -> String {
        l == .fr
            ? "Paiement à \(days) jours à compter de la date d'émission, soit le \(dueDate). En cas de retard, des pénalités au taux de trois fois le taux d'intérêt légal sont dues, ainsi qu'une indemnité forfaitaire pour frais de recouvrement de 40 € (art. L441-10 du code de commerce). Pas d'escompte pour paiement anticipé."
            : "Payment due \(days) days from the issue date, i.e. \(dueDate). Late payment incurs interest at three times the statutory rate, plus a fixed recovery indemnity of €40 (art. L441-10 French commercial code). No discount for early payment."
    }
    static func pdfTitleNumbered(_ l: AppLanguage, type: String, number: String) -> String {
        l == .fr ? "\(type) n° \(number)" : "\(type) no. \(number)"
    }
    static func pdfIssuerHeading(_ l: AppLanguage) -> String {
        l == .fr ? "ÉMETTEUR" : "ISSUER"
    }
    static func pdfPageOf(_ l: AppLanguage, page: Int, total: Int) -> String {
        l == .fr ? "page \(page) sur \(total)" : "page \(page) of \(total)"
    }
    /// Un brouillon ou une facture annulée s'exportait EXACTEMENT comme une
    /// facture valide : rien sur la page ne les distinguait.
    static func pdfWatermark(_ l: AppLanguage, status: DocumentStatus) -> String? {
        switch status {
        case .brouillon: return l == .fr ? "BROUILLON — NE PAS RÉGLER" : "DRAFT — DO NOT PAY"
        case .annulee: return l == .fr ? "ANNULÉE" : "CANCELLED"
        default: return nil
        }
    }
    static func pdfVatLineLabel(_ l: AppLanguage, rate: String, basis: String) -> String {
        l == .fr ? "TVA \(rate) sur \(basis)" : "VAT \(rate) on \(basis)"
    }
}
