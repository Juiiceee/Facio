import Foundation

// MARK: - Profil & applicabilité

/// Constantes du profil Factur-X visé (EN 16931 / « Comfort »).
/// Voir issue #92 et la spec EN 16931 / FNFE-MPE. Les chaînes (URN, niveau de
/// conformité) sont normatives — ne pas paraphraser.
enum FacturXProfile {
    static let guidelineURN = "urn:cen.eu:en16931:2017"
    static let conformanceLevel = "EN 16931"
    static let version = "1.0"
    /// Texte d'exonération pour la franchise en base de TVA (BT-120).
    static let franchiseExemptionReason = "TVA non applicable, art. 293 B du CGI"
}

/// Indique si un document peut produire une facture électronique Factur-X.
enum FacturXApplicability: Equatable {
    case applicable
    /// Un devis n'est pas une facture électronique.
    case notAnInvoice
    /// Factur-X exige une devise ISO 4217 ; v1 limité à l'EUR (les cryptos sont exclues).
    case unsupportedCurrency(String)
    /// La facture est éligible mais incomplète : on refuse plutôt que d'émettre
    /// un XML invalide qui serait rejeté par une PDP / le destinataire.
    case incomplete(FacturXIncompleteReason)
}

/// Données manquantes empêchant un XML EN 16931 valide.
enum FacturXIncompleteReason: Equatable {
    case noLines
    case missingNumber
    case missingClient
    /// Au moins une ligne avec TVA (catégorie S) mais aucun n° de TVA vendeur
    /// (BT-31), pourtant requis par la règle EN 16931 BR-S-02.
    case missingSellerVAT
}

// MARK: - Générateur XML CII (Cross Industry Invoice, EN 16931)

enum FacturXXMLBuilder {
    static func applicability(for document: Document, company: CompanyInfo) -> FacturXApplicability {
        guard document.type == .facture else { return .notAnInvoice }
        guard document.currency == .eur else { return .unsupportedCurrency(document.currency.rawValue) }

        guard !document.lignesTriees.isEmpty else { return .incomplete(.noLines) }
        guard !document.number.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .incomplete(.missingNumber)
        }
        guard !document.clientNom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .incomplete(.missingClient)
        }
        // Catégorie S (TVA > 0) ⇒ n° TVA vendeur obligatoire (BR-S-02).
        let chargesVAT = document.lignesTriees.contains { $0.tauxTVA > 0 }
        if chargesVAT, company.tvaIntracom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .incomplete(.missingSellerVAT)
        }
        return .applicable
    }

    /// Construit le XML `factur-x.xml` (CII, profil EN 16931).
    /// Précondition : `applicability(for:) == .applicable`.
    static func buildXML(document: Document, company: CompanyInfo) -> String {
        let currency = "EUR"
        let lines = document.lignesTriees
        let totals = InvoiceTotals.canonical(for: lines)
        let sellerCountry = countryCode(forVAT: company.tvaIntracom)
        let buyerCountry = countryCode(forVAT: document.clientTva)

        // Totaux identiques à ceux du PDF (source unique : InvoiceTotals).
        let lineTotal = totals.totalHT
        let taxTotal = totals.totalTVA
        let grandTotal = totals.totalTTC

        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rsm:CrossIndustryInvoice xmlns:rsm="urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100" xmlns:ram="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100" xmlns:qdt="urn:un:unece:uncefact:data:standard:QualifiedDataType:100" xmlns:udt="urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100">
          <rsm:ExchangedDocumentContext>
            <ram:GuidelineSpecifiedDocumentContextParameter>
              <ram:ID>\(FacturXProfile.guidelineURN)</ram:ID>
            </ram:GuidelineSpecifiedDocumentContextParameter>
          </rsm:ExchangedDocumentContext>
          <rsm:ExchangedDocument>
            <ram:ID>\(esc(document.number))</ram:ID>
            <ram:TypeCode>380</ram:TypeCode>
            <ram:IssueDateTime>
              <udt:DateTimeString format="102">\(date102(document.dateCreation))</udt:DateTimeString>
            </ram:IssueDateTime>

        """

        let trimmedNotes = document.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            xml += """
                <ram:IncludedNote>
                  <ram:Content>\(esc(trimmedNotes))</ram:Content>
                </ram:IncludedNote>

            """
        }

        xml += """
          </rsm:ExchangedDocument>
          <rsm:SupplyChainTradeTransaction>

        """

        // Lignes (BG-25)
        for (index, line) in lines.enumerated() {
            let category = vatCategory(for: line.tauxTVA)
            // BT-146 (prix unitaire net) en pleine précision (jusqu'à 4 décimales) :
            // ne pas arrondir à 2 dp, sinon BT-131 ≠ BT-146 × quantité pour qté > 1.
            let lineNet = InvoiceTotals.rounded2(line.totalLigne)
            xml += """
                <ram:IncludedSupplyChainTradeLineItem>
                  <ram:AssociatedDocumentLineDocument>
                    <ram:LineID>\(index + 1)</ram:LineID>
                  </ram:AssociatedDocumentLineDocument>
                  <ram:SpecifiedTradeProduct>
                    <ram:Name>\(esc(line.designation))</ram:Name>
                  </ram:SpecifiedTradeProduct>
                  <ram:SpecifiedLineTradeAgreement>
                    <ram:NetPriceProductTradePrice>
                      <ram:ChargeAmount>\(unitPrice(line.prixUnitaire))</ram:ChargeAmount>
                    </ram:NetPriceProductTradePrice>
                  </ram:SpecifiedLineTradeAgreement>
                  <ram:SpecifiedLineTradeDelivery>
                    <ram:BilledQuantity unitCode="C62">\(amount(line.quantite))</ram:BilledQuantity>
                  </ram:SpecifiedLineTradeDelivery>
                  <ram:SpecifiedLineTradeSettlement>
                    <ram:ApplicableTradeTax>
                      <ram:TypeCode>VAT</ram:TypeCode>
                      <ram:CategoryCode>\(category)</ram:CategoryCode>
                      <ram:RateApplicablePercent>\(amount(line.tauxTVA))</ram:RateApplicablePercent>
                    </ram:ApplicableTradeTax>
                    <ram:SpecifiedTradeSettlementLineMonetarySummation>
                      <ram:LineTotalAmount>\(amount(lineNet))</ram:LineTotalAmount>
                    </ram:SpecifiedTradeSettlementLineMonetarySummation>
                  </ram:SpecifiedLineTradeSettlement>
                </ram:IncludedSupplyChainTradeLineItem>

            """
        }

        // Accord (vendeur / acheteur)
        xml += """
            <ram:ApplicableHeaderTradeAgreement>
              <ram:SellerTradeParty>
                <ram:Name>\(esc(company.nom))</ram:Name>

        """
        if !company.siret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            xml += """
                    <ram:SpecifiedLegalOrganization>
                      <ram:ID schemeID="0002">\(esc(company.siret))</ram:ID>
                    </ram:SpecifiedLegalOrganization>

            """
        }
        xml += """
                <ram:PostalTradeAddress>
                  <ram:PostcodeCode>\(esc(company.codePostal))</ram:PostcodeCode>
                  <ram:LineOne>\(esc(company.adresse))</ram:LineOne>
                  <ram:CityName>\(esc(company.ville))</ram:CityName>
                  <ram:CountryID>\(sellerCountry)</ram:CountryID>
                </ram:PostalTradeAddress>

        """
        if !company.tvaIntracom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            xml += """
                    <ram:SpecifiedTaxRegistration>
                      <ram:ID schemeID="VA">\(esc(company.tvaIntracom))</ram:ID>
                    </ram:SpecifiedTaxRegistration>

            """
        }
        xml += """
              </ram:SellerTradeParty>
              <ram:BuyerTradeParty>
                <ram:Name>\(esc(document.clientNom))</ram:Name>

        """
        if !document.clientSiret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            xml += """
                    <ram:SpecifiedLegalOrganization>
                      <ram:ID schemeID="0002">\(esc(document.clientSiret))</ram:ID>
                    </ram:SpecifiedLegalOrganization>

            """
        }
        xml += """
                <ram:PostalTradeAddress>
                  <ram:PostcodeCode>\(esc(document.clientCodePostal))</ram:PostcodeCode>
                  <ram:LineOne>\(esc(document.clientAdresse))</ram:LineOne>
                  <ram:CityName>\(esc(document.clientVille))</ram:CityName>
                  <ram:CountryID>\(buyerCountry)</ram:CountryID>
                </ram:PostalTradeAddress>

        """
        if !document.clientTva.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            xml += """
                    <ram:SpecifiedTaxRegistration>
                      <ram:ID schemeID="VA">\(esc(document.clientTva))</ram:ID>
                    </ram:SpecifiedTaxRegistration>

            """
        }
        xml += """
              </ram:BuyerTradeParty>
            </ram:ApplicableHeaderTradeAgreement>
            <ram:ApplicableHeaderTradeDelivery/>
            <ram:ApplicableHeaderTradeSettlement>
              <ram:InvoiceCurrencyCode>\(currency)</ram:InvoiceCurrencyCode>

        """

        // Ventilation TVA (BG-23), un bloc par groupe (taux). Catégorie et
        // exonération dérivées du taux (S si > 0, sinon E franchise en base).
        for group in totals.groups {
            let category = vatCategory(for: group.rate)
            xml += """
                <ram:ApplicableTradeTax>
                  <ram:CalculatedAmount>\(amount(group.calculated))</ram:CalculatedAmount>
                  <ram:TypeCode>VAT</ram:TypeCode>

            """
            if category == "E" {
                xml += "          <ram:ExemptionReason>\(esc(FacturXProfile.franchiseExemptionReason))</ram:ExemptionReason>\n"
            }
            xml += """
                  <ram:BasisAmount>\(amount(group.basis))</ram:BasisAmount>
                  <ram:CategoryCode>\(category)</ram:CategoryCode>
                  <ram:RateApplicablePercent>\(amount(group.rate))</ram:RateApplicablePercent>
                </ram:ApplicableTradeTax>

            """
        }

        xml += """
              <ram:SpecifiedTradePaymentTerms>
                <ram:DueDateDateTime>
                  <udt:DateTimeString format="102">\(date102(document.dateEcheance))</udt:DateTimeString>
                </ram:DueDateDateTime>
              </ram:SpecifiedTradePaymentTerms>
              <ram:SpecifiedTradeSettlementHeaderMonetarySummation>
                <ram:LineTotalAmount>\(amount(lineTotal))</ram:LineTotalAmount>
                <ram:ChargeTotalAmount>0.00</ram:ChargeTotalAmount>
                <ram:AllowanceTotalAmount>0.00</ram:AllowanceTotalAmount>
                <ram:TaxBasisTotalAmount>\(amount(lineTotal))</ram:TaxBasisTotalAmount>
                <ram:TaxTotalAmount currencyID="\(currency)">\(amount(taxTotal))</ram:TaxTotalAmount>
                <ram:GrandTotalAmount>\(amount(grandTotal))</ram:GrandTotalAmount>
                <ram:TotalPrepaidAmount>0.00</ram:TotalPrepaidAmount>
                <ram:DuePayableAmount>\(amount(grandTotal))</ram:DuePayableAmount>
              </ram:SpecifiedTradeSettlementHeaderMonetarySummation>
            </ram:ApplicableHeaderTradeSettlement>
          </rsm:SupplyChainTradeTransaction>
        </rsm:CrossIndustryInvoice>
        """
        return xml
    }

    // MARK: - TVA

    /// Code catégorie UNCL5305 : `S` si taux > 0, sinon `E` (franchise en base).
    static func vatCategory(for rate: Decimal) -> String {
        rate > 0 ? "S" : "E"
    }

    /// Pays (ISO 3166-1 alpha-2) déduit du préfixe d'un n° de TVA intracom
    /// (ex. « DE… » → « DE »). Repli sur « FR » si absent/non préfixé — l'app
    /// reste centrée sur le B2B domestique français.
    static func countryCode(forVAT vat: String, fallback: String = "FR") -> String {
        let trimmed = vat.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = trimmed.prefix(2)
        if prefix.count == 2, prefix.allSatisfy({ $0.isLetter }) {
            return prefix.uppercased()
        }
        return fallback
    }

    // MARK: - Formatage

    /// Montant EN 16931 : séparateur `.`, 2 décimales, sans séparateur de milliers,
    /// indépendant de la locale de l'app.
    static func amount(_ value: Decimal) -> String {
        amountFormatter.string(from: InvoiceTotals.rounded2(value) as NSDecimalNumber) ?? "0.00"
    }

    /// Prix unitaire net (BT-146) : 2 à 4 décimales, sans arrondi destructif, pour
    /// que BT-131 (total ligne) reste reproductible par PU × quantité.
    static func unitPrice(_ value: Decimal) -> String {
        unitPriceFormatter.string(from: value as NSDecimalNumber) ?? "0.00"
    }

    private static let amountFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = false
        f.decimalSeparator = "."
        return f
    }()

    private static let unitPriceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 4
        f.usesGroupingSeparator = false
        f.decimalSeparator = "."
        return f
    }()

    /// Date au format UNCL2379 « 102 » : CCYYMMDD.
    static func date102(_ date: Date) -> String {
        date102Formatter.string(from: date)
    }

    private static let date102Formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd"
        return f
    }()

    /// Échappement XML des textes utilisateur. Filtre d'abord les caractères de
    /// contrôle interdits par XML 1.0 (sauf tab/LF/CR), qui rendraient sinon le
    /// `factur-x.xml` non valide, puis échappe les entités.
    static func esc(_ text: String) -> String {
        let cleaned = String(String.UnicodeScalarView(text.unicodeScalars.filter { scalar in
            scalar.value == 0x09 || scalar.value == 0x0A || scalar.value == 0x0D || scalar.value >= 0x20
        }))
        return cleaned
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
