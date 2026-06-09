import AppKit
import Foundation

/// Envoi d'un document par email via le composer natif macOS (`NSSharingService`).
/// L'app n'étant pas sandboxée, on attache directement les fichiers du disque.
enum EmailService {
    enum SendResult {
        case composed
        case unavailable
    }

    /// Substitue les variables d'un modèle d'email avec les données du document.
    static func resolveTemplate(_ template: String, document: Document, company: CompanyInfo) -> String {
        let amount = document.currency.formatAccounting(document.totalTTC, lang: company.formatNombre)
        let dueDate = document.dateEcheance.formattedDate(for: company.formatDate)
        return template
            .replacingOccurrences(of: "{client}", with: document.clientNom)
            .replacingOccurrences(of: "{number}", with: document.number)
            .replacingOccurrences(of: "{amount}", with: amount)
            .replacingOccurrences(of: "{due_date}", with: dueDate)
            .replacingOccurrences(of: "{company}", with: company.nom)
    }

    /// Ouvre le composer mail pré-rempli (objet, message, destinataire) avec le
    /// PDF de la facture et les justificatifs en pièces jointes (fichiers séparés).
    @MainActor
    @discardableResult
    static func composeInvoiceEmail(
        document: Document,
        company: CompanyInfo,
        pdfData: Data,
        attachmentURLs: [URL]
    ) -> SendResult {
        let lang = document.langue
        let subject = resolveTemplate(company.emailSubjectTemplate(for: lang), document: document, company: company)
        let body = resolveTemplate(company.emailBodyTemplate(for: lang), document: document, company: company)

        // PDF de la facture → fichier temporaire pour la pièce jointe.
        let pdfURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeFilename(document.number)).pdf")
        do {
            try pdfData.write(to: pdfURL, options: .atomic)
        } catch {
            return .unavailable
        }

        var items: [Any] = [body, pdfURL]
        items.append(contentsOf: attachmentURLs)

        guard let service = NSSharingService(named: .composeEmail),
              service.canPerform(withItems: items) else {
            return .unavailable
        }
        service.subject = subject
        let recipient = document.clientEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !recipient.isEmpty {
            service.recipients = [recipient]
        }
        service.perform(withItems: items)
        return .composed
    }

    private static func safeFilename(_ base: String) -> String {
        let cleaned = base.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar)
                || CharacterSet(charactersIn: " ._-").contains(scalar) {
                return Character(scalar)
            }
            return "-"
        }
        let collapsed = String(cleaned)
            .split(whereSeparator: { $0 == "-" })
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: " ._-"))
        return collapsed.isEmpty ? "document" : String(collapsed.prefix(120))
    }
}
