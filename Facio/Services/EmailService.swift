import AppKit
import Foundation

/// Envoi d'un document par email via le composer natif macOS (`NSSharingService`).
/// L'app n'étant pas sandboxée, on attache directement les fichiers du disque.
enum EmailService {
    enum SendResult {
        case composed
        case unavailable
    }

    /// Un justificatif à joindre : fichier source sur disque + nom lisible désiré
    /// (libellé ou nom d'origine), l'extension étant conservée à la copie.
    struct EmailAttachment {
        let sourceURL: URL
        let displayName: String
        let fileExtension: String
    }

    /// Substitue les variables d'un modèle d'email avec les données du document.
    static func resolveTemplate(_ template: String, document: Document, company: CompanyInfo) -> String {
        let amount = document.currency.formatAccounting(document.totalTTC, lang: company.formatNombre)
        let dueDate = document.dateEcheance.formattedDate(for: company.formatDate)
        let attachmentsLine = document.attachments.isEmpty ? "" : L10n.emailAttachmentsLine(document.langue)
        let resolved = template
            .replacingOccurrences(of: "{client}", with: document.clientNom)
            .replacingOccurrences(of: "{number}", with: document.number)
            .replacingOccurrences(of: "{amount}", with: amount)
            .replacingOccurrences(of: "{due_date}", with: dueDate)
            .replacingOccurrences(of: "{company}", with: company.nom)
            .replacingOccurrences(of: "{attachments}", with: attachmentsLine)
        return collapseBlankLines(resolved)
    }

    /// Supprime les lignes vides résiduelles laissées par un placeholder vide.
    private static func collapseBlankLines(_ text: String) -> String {
        var result = text
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Ouvre le composer mail pré-rempli (objet, message, destinataire) avec le
    /// PDF de la facture et les justificatifs en pièces jointes (fichiers séparés).
    @MainActor
    @discardableResult
    static func composeInvoiceEmail(
        document: Document,
        company: CompanyInfo,
        pdfData: Data,
        attachments: [EmailAttachment]
    ) -> SendResult {
        let lang = document.langue
        let subject = resolveTemplate(company.emailSubjectTemplate(for: lang), document: document, company: company)
        let body = resolveTemplate(company.emailBodyTemplate(for: lang), document: document, company: company)

        // PDF de la facture → fichier temporaire (sous-dossier unique pour
        // éviter toute collision entre envois).
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FacioEmail-\(UUID().uuidString)", isDirectory: true)
        let pdfURL = tempDir.appendingPathComponent("\(safeFilename(document.number)).pdf")
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            try pdfData.write(to: pdfURL, options: .atomic)
        } catch {
            return .unavailable
        }

        // Re-vérifie l'existence au dernier moment : un justificatif peut avoir
        // été supprimé entre la construction des URLs et l'ouverture du composer.
        var items: [Any] = [body, pdfURL]
        let existing = attachments.filter { FileManager.default.fileExists(atPath: $0.sourceURL.path) }
        // Copie chaque justificatif dans le dossier temp sous un nom lisible
        // (libellé) plutôt que le nom de stockage en UUID.
        for (attachment, name) in zip(existing, uniqueFilenames(for: existing)) {
            let dest = tempDir.appendingPathComponent(name)
            if (try? FileManager.default.copyItem(at: attachment.sourceURL, to: dest)) != nil {
                items.append(dest)
            }
        }

        guard let service = NSSharingService(named: .composeEmail),
              service.canPerform(withItems: items) else {
            try? FileManager.default.removeItem(at: tempDir)
            return .unavailable
        }
        service.subject = subject
        let recipient = document.clientEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !recipient.isEmpty {
            service.recipients = [recipient]
        }
        service.perform(withItems: items)

        // Nettoyage différé : le composer lit le fichier de façon asynchrone,
        // on ne peut donc pas le supprimer immédiatement après perform().
        DispatchQueue.main.asyncAfter(deadline: .now() + 90) {
            try? FileManager.default.removeItem(at: tempDir)
        }
        return .composed
    }

    /// Noms de fichiers lisibles pour une liste de justificatifs, index-alignés.
    /// Nettoie chaque libellé via `safeFilename`, conserve l'extension, et
    /// dédoublonne les collisions (insensibles à la casse) en suffixant `-2`, `-3`…
    static func uniqueFilenames(for attachments: [EmailAttachment]) -> [String] {
        var used = Set<String>()
        return attachments.map { attachment in
            let cleaned = safeFilename(attachment.displayName)
            let ext = attachment.fileExtension.lowercased()
            // Le libellé n'a pas d'extension, mais `originalFilename` (fallback)
            // l'inclut déjà : on évite ainsi un `recu.jpg.jpg`.
            let hasExt = !ext.isEmpty && cleaned.lowercased().hasSuffix(".\(ext)")
            let base = hasExt ? String(cleaned.dropLast(ext.count + 1)) : cleaned
            let suffix = ext.isEmpty ? "" : ".\(ext)"
            var candidate = base + suffix
            var counter = 2
            while used.contains(candidate.lowercased()) {
                candidate = "\(base)-\(counter)\(suffix)"
                counter += 1
            }
            used.insert(candidate.lowercased())
            return candidate
        }
    }

    static func safeFilename(_ base: String) -> String {
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
