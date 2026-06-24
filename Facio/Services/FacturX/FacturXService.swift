import Foundation

/// Orchestration de la génération d'une facture électronique **Factur-X** :
/// vérifie l'applicabilité, produit le PDF visuel, construit le XML EN 16931 et
/// l'embarque dans un conteneur PDF/A-3.
@MainActor
enum FacturXService {
    enum Outcome: Equatable {
        /// PDF Factur-X prêt (XML embarqué).
        case success(Data)
        /// Document non éligible (devis, ou devise non ISO/non EUR).
        case notApplicable(FacturXApplicability)
        /// Génération ou embarquage en échec.
        case failed
    }

    static func generate(document: Document, company: CompanyInfo) -> Outcome {
        let applicability = FacturXXMLBuilder.applicability(for: document, company: company)
        guard applicability == .applicable else { return .notApplicable(applicability) }

        let pdf = PDFGenerator(document: document, company: company).generate()
        guard !pdf.isEmpty else { return .failed }

        let xml = FacturXXMLBuilder.buildXML(document: document, company: company)
        guard let embedded = FacturXPDFWriter.embed(
            xml: xml,
            into: pdf,
            invoiceNumber: document.number,
            modDate: document.dateCreation
        ) else { return .failed }

        return .success(embedded)
    }
}
