import AppKit
import Foundation

struct ExportService {
    /// Exporte des données PDF via un dialogue de sauvegarde
    @MainActor
    @discardableResult
    static func exportPDF(data: Data, defaultFilename: String, language: AppLanguage = .fr) async -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = sanitizedPDFFilename(defaultFilename, language: language)
        panel.title = L10n.exportDocument(language)
        panel.message = L10n.chooseSaveLocation(language)
        panel.canCreateDirectories = true

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return false
        }

        do {
            try data.write(to: url, options: [.atomic])
            // Ouvrir le fichier dans l'application par défaut
            NSWorkspace.shared.open(url)
            return true
        } catch {
            return false
        }
    }

    private static func sanitizedPDFFilename(_ filename: String, language: AppLanguage) -> String {
        let baseName = (filename as NSString).deletingPathExtension
        let sanitizedScalars = baseName.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar)
                || CharacterSet(charactersIn: " ._-").contains(scalar) {
                return Character(scalar)
            }
            return "-"
        }

        let collapsed = String(sanitizedScalars)
            .split(whereSeparator: { $0 == "-" })
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: " ._-"))

        let safeBase = collapsed.isEmpty ? L10n.defaultPDFName(language) : String(collapsed.prefix(120))
        return "\(safeBase).pdf"
    }
}
