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
}

// MARK: - Générateur XML CII (Cross Industry Invoice, EN 16931)

enum FacturXXMLBuilder {
    static func applicability(for document: Document) -> FacturXApplicability {
        guard document.type == .facture else { return .notAnInvoice }
        guard document.currency == .eur else { return .unsupportedCurrency(document.currency.rawValue) }
        return .applicable
    }

    /// Construit le XML `factur-x.xml` (CII, profil EN 16931).
    /// Précondition : `applicability(for:) == .applicable`.
    static func buildXML(document: Document, company: CompanyInfo) -> String {
        let currency = "EUR"
        let lines = document.lignesTriees
        let groups = vatGroups(for: lines)

        // Totaux (valeurs arrondies à 2 décimales, cohérentes entre elles).
        let lineTotal = lines.reduce(Decimal.zero) { $0 + rounded2($1.totalLigne) }
        let taxTotal = groups.reduce(Decimal.zero) { $0 + $1.calculated }
        let grandTotal = lineTotal + taxTotal

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
            let unitNet = rounded2(line.prixUnitaire)
            let lineNet = rounded2(line.totalLigne)
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
                      <ram:ChargeAmount>\(amount(unitNet))</ram:ChargeAmount>
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
                  <ram:CountryID>FR</ram:CountryID>
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
                  <ram:CountryID>FR</ram:CountryID>
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

        // Ventilation TVA (BG-23), un bloc par groupe (catégorie + taux)
        for group in groups {
            xml += """
                <ram:ApplicableTradeTax>
                  <ram:CalculatedAmount>\(amount(group.calculated))</ram:CalculatedAmount>
                  <ram:TypeCode>VAT</ram:TypeCode>

            """
            if let reason = group.exemptionReason {
                xml += "          <ram:ExemptionReason>\(esc(reason))</ram:ExemptionReason>\n"
            }
            xml += """
                  <ram:BasisAmount>\(amount(group.basis))</ram:BasisAmount>
                  <ram:CategoryCode>\(group.category)</ram:CategoryCode>
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

    // MARK: - Ventilation TVA

    /// Un groupe de ventilation TVA (BG-23) : une catégorie + un taux.
    struct VATGroup {
        let category: String
        let rate: Decimal
        let basis: Decimal
        let calculated: Decimal
        let exemptionReason: String?
    }

    /// Regroupe les lignes par (catégorie, taux) et calcule base + TVA par groupe.
    static func vatGroups(for lines: [LineItem]) -> [VATGroup] {
        // Clé stable : taux (la catégorie en découle). Préserve l'ordre d'apparition.
        var order: [Decimal] = []
        var basisByRate: [Decimal: Decimal] = [:]
        for line in lines {
            let rate = line.tauxTVA
            if basisByRate[rate] == nil { order.append(rate) }
            basisByRate[rate, default: 0] += rounded2(line.totalLigne)
        }
        return order.map { rate in
            let basis = basisByRate[rate] ?? 0
            let category = vatCategory(for: rate)
            return VATGroup(
                category: category,
                rate: rate,
                basis: basis,
                calculated: rounded2(basis * rate / 100),
                exemptionReason: category == "E" ? FacturXProfile.franchiseExemptionReason : nil
            )
        }
    }

    /// Code catégorie UNCL5305 : `S` si taux > 0, sinon `E` (franchise en base).
    static func vatCategory(for rate: Decimal) -> String {
        rate > 0 ? "S" : "E"
    }

    // MARK: - Formatage

    /// Arrondi commercial à 2 décimales (jamais via Double).
    static func rounded2(_ value: Decimal) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 2, .plain)
        return result
    }

    /// Montant EN 16931 : séparateur `.`, 2 décimales, sans séparateur de milliers,
    /// indépendant de la locale de l'app.
    static func amount(_ value: Decimal) -> String {
        amountFormatter.string(from: rounded2(value) as NSDecimalNumber) ?? "0.00"
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

    /// Échappement XML des textes utilisateur.
    static func esc(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
