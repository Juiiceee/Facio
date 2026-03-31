import AppKit
import Foundation

struct ExportService {
    /// Exporte des données PDF via un dialogue de sauvegarde
    @MainActor
    static func exportPDF(data: Data, defaultFilename: String) async -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(defaultFilename).pdf"
        panel.title = "Exporter le document"
        panel.message = "Choisissez où sauvegarder le fichier PDF"
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
