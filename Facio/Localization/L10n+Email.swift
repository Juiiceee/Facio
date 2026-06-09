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
    static func attachmentImportFailed(_ l: AppLanguage) -> String {
        l == .fr ? "Impossible d'importer ce fichier." : "Could not import this file."
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
            ? "Variables disponibles : {client} {number} {amount} {due_date} {company}"
            : "Available variables: {client} {number} {amount} {due_date} {company}"
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

            Les justificatifs associés sont également joints à ce message.

            Cordialement,
            {company}
            """
            : """
            Hello {client},

            Please find attached invoice {number} for {amount}, due by {due_date}.

            The related supporting documents are also attached to this message.

            Best regards,
            {company}
            """
    }
}
