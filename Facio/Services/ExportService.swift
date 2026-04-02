import AppKit
import Foundation

struct ExportService {
    /// Exporte des données PDF via un dialogue de sauvegarde
    @MainActor
    @discardableResult
    static func exportPDF(data: Data, defaultFilename: String, language: AppLanguage = .fr) async -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(defaultFilename).pdf"
        panel.title = L10n.exportDocument(language)
        panel.message = L10n.chooseSaveLocation(language)
        panel.canCreateDirectories = true

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return false
        }

        do {
            try data.write(to: url)
            // Ouvrir le fichier dans l'application par défaut
            NSWorkspace.shared.open(url)
            return true
        } catch {
            return false
        }
    }
}
