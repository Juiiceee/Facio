import Foundation

// MARK: - Justificatifs (pièces jointes) & envoi par email

extension L10n {
    // Section justificatifs (éditeur de document)
    static func attachmentsSection(_ l: AppLanguage) -> String { l == .fr ? "Justificatifs" : "Supporting documents" }
    static func addAttachment(_ l: AppLanguage) -> String { l == .fr ? "Ajouter un justificatif" : "Add a document" }
    static func noAttachments(_ l: AppLanguage) -> String { l == .fr ? "Aucun justificatif" : "No supporting documents" }
    static func noAttachmentsHint(_ l: AppLanguage) -> String {
        l == .fr ? "Glissez un fichier ici, ou cliquez sur Ajouter (PDF, image)." : "Drag a file here, or click Add (PDF, image)."
    }
    static func dropAttachmentHere(_ l: AppLanguage) -> String { l == .fr ? "Déposez vos fichiers ici" : "Drop your files here" }
    static func attachmentLabelPlaceholder(_ l: AppLanguage) -> String { l == .fr ? "Libellé (ex. Train Nancy⇄Paris)" : "Label (e.g. Train Nancy⇄Paris)" }
    static func openAttachment(_ l: AppLanguage) -> String { l == .fr ? "Ouvrir" : "Open" }
    static func openAttachmentExternally(_ l: AppLanguage) -> String { l == .fr ? "Ouvrir dans l'app externe" : "Open in external app" }
    static func attachmentPreviewUnavailable(_ l: AppLanguage) -> String { l == .fr ? "Aperçu indisponible" : "Preview unavailable" }
    static func attachmentPreviewUnavailableHint(_ l: AppLanguage) -> String {
        l == .fr ? "Ce fichier ne peut pas être affiché ici. Ouvrez-le dans l'app externe."
        : "This file cannot be displayed here. Open it in the external app."
    }

    // Montant reportable d'un justificatif
    static func attachmentAmount(_ l: AppLanguage) -> String { l == .fr ? "Montant" : "Amount" }
    static func attachmentAmountHT(_ l: AppLanguage) -> String { l == .fr ? "HT" : "Excl. tax" }
    static func attachmentAmountTTC(_ l: AppLanguage) -> String { l == .fr ? "TTC" : "Incl. tax" }
    static func reportToInvoice(_ l: AppLanguage) -> String { l == .fr ? "Reporter sur la facture" : "Add to invoice" }
    static func toastLineReported(_ l: AppLanguage) -> String { l == .fr ? "Ligne ajoutée à la facture" : "Line added to invoice" }
    static func attachmentImportFailedCount(_ l: AppLanguage, count: Int) -> String {
        if l == .fr {
            return count == 1
                ? "Impossible d'importer ce fichier."
                : "Impossible d'importer \(count) fichiers."
        }
        return count == 1
            ? "Could not import this file."
            : "Could not import \(count) files."
    }

    // Échec de copie des justificatifs lors d'une duplication / conversion
    static func attachmentsCopyFailedTitle(_ l: AppLanguage) -> String {
        l == .fr ? "Justificatifs non copiés" : "Supporting documents not copied"
    }
    static func attachmentsCopyFailedMessage(_ l: AppLanguage, count: Int) -> String {
        if l == .fr {
            return count == 1
                ? "1 justificatif n'a pas pu être copié vers le nouveau document (fichier introuvable ou copie impossible)."
                : "\(count) justificatifs n'ont pas pu être copiés vers le nouveau document (fichiers introuvables ou copie impossible)."
        }
        return count == 1
            ? "1 supporting document could not be copied to the new document (missing file or copy failure)."
            : "\(count) supporting documents could not be copied to the new document (missing files or copy failure)."
    }

    // Envoi par email
    static func sendByEmail(_ l: AppLanguage) -> String { l == .fr ? "Envoyer par email" : "Send by email" }
    static func emailUnavailableTitle(_ l: AppLanguage) -> String { l == .fr ? "Envoi indisponible" : "Send unavailable" }
    static func emailUnavailableMessage(_ l: AppLanguage) -> String {
        l == .fr
            ? "Aucune application de messagerie n'est configurée sur ce Mac. Exportez le PDF à la place."
            : "No email application is configured on this Mac. Export the PDF instead."
    }

    // Réglages — Envoi / Email
    static func settingsEmail(_ l: AppLanguage) -> String { l == .fr ? "Envoi / Email" : "Send / Email" }
    static func settingsEmailHelp(_ l: AppLanguage) -> String {
        l == .fr
            ? "Modèle d'email utilisé pour envoyer vos factures et devis."
            : "Email template used to send your invoices and quotes."
    }
    static func emailTemplateSection(_ l: AppLanguage) -> String { l == .fr ? "Modèle d'email" : "Email template" }
    static func emailTemplateLanguage(_ l: AppLanguage) -> String { l == .fr ? "Langue du modèle" : "Template language" }
    static func emailSubjectLabel(_ l: AppLanguage) -> String { l == .fr ? "Objet" : "Subject" }
    static func emailBodyLabel(_ l: AppLanguage) -> String { l == .fr ? "Message" : "Message" }
    static func emailResetTemplate(_ l: AppLanguage) -> String { l == .fr ? "Réinitialiser le modèle" : "Reset template" }
    static func emailPlaceholdersHelp(_ l: AppLanguage) -> String {
        l == .fr
            ? "Variables disponibles : {client} {number} {amount} {due_date} {company} {attachments}"
            : "Available variables: {client} {number} {amount} {due_date} {company} {attachments}"
    }

    /// Phrase insérée par {attachments} quand le document a des justificatifs.
    static func emailAttachmentsLine(_ l: AppLanguage) -> String {
        l == .fr
            ? "Les justificatifs associés sont également joints à ce message."
            : "The related supporting documents are also attached to this message."
    }

    // Modèles par défaut (utilisés si l'utilisateur n'a rien personnalisé)
    static func emailDefaultSubject(_ l: AppLanguage) -> String {
        l == .fr ? "Facture {number} — {company}" : "Invoice {number} — {company}"
    }
    static func emailDefaultBody(_ l: AppLanguage) -> String {
        l == .fr
            ? """
            Bonjour {client},

            Veuillez trouver ci-joint la facture {number} d'un montant de {amount}, à régler avant le {due_date}.

            {attachments}

            Cordialement,
            {company}
            """
            : """
            Hello {client},

            Please find attached invoice {number} for {amount}, due by {due_date}.

            {attachments}

            Best regards,
            {company}
            """
    }
}
