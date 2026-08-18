import AppKit
import Foundation
import PDFKit

struct ExportService {
    enum ExportResult: Equatable {
        case success
        case cancelled
        case failed
    }

    /// Exporte des données PDF via un dialogue de sauvegarde
    @MainActor
    @discardableResult
    static func exportPDF(data: Data, defaultFilename: String, language: AppLanguage = .fr) async -> ExportResult {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = sanitizedPDFFilename(defaultFilename, language: language)
        panel.title = L10n.exportDocument(language)
        panel.message = L10n.chooseSaveLocation(language)
        panel.canCreateDirectories = true

        let response = panel.runModal()
        guard response == .OK else {
            return .cancelled
        }

        guard let url = panel.url else {
            return .failed
        }

        do {
            try data.write(to: url, options: [.atomic])
            // Ouvrir le fichier dans l'application par défaut
            NSWorkspace.shared.open(url)
            return .success
        } catch {
            return .failed
        }
    }

    /// Envoie le PDF à l'imprimante, via le dialogue d'impression système.
    ///
    /// L'app générait des PDF depuis toujours sans jamais offrir de les
    /// imprimer : il fallait exporter, ouvrir le fichier dans Aperçu, puis
    /// imprimer depuis là — trois étapes pour un geste que ⌘P rend natif
    /// partout ailleurs sur macOS.
    @MainActor
    @discardableResult
    static func printPDF(data: Data, jobName: String) -> ExportResult {
        guard let pdf = PDFDocument(data: data) else { return .failed }

        let info = NSPrintInfo.shared.copy() as? NSPrintInfo ?? NSPrintInfo.shared
        info.jobDisposition = .spool
        // Le PDF est déjà paginé en A4 avec ses marges : le laisser tel quel,
        // sinon l'impression re-marge un document déjà margé.
        info.horizontalPagination = .fit
        info.verticalPagination = .fit
        info.isHorizontallyCentered = true
        info.isVerticallyCentered = true
        info.leftMargin = 0
        info.rightMargin = 0
        info.topMargin = 0
        info.bottomMargin = 0

        guard let operation = pdf.printOperation(for: info, scalingMode: .pageScaleDownToFit, autoRotate: false) else {
            return .failed
        }
        operation.jobTitle = jobName
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        return operation.run() ? .success : .cancelled
    }

    @MainActor
    @discardableResult
    static func exportCSV(data: Data, defaultFilename: String, language: AppLanguage = .fr) async -> ExportResult {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = sanitizedFilename(defaultFilename, fallback: L10n.defaultCSVName(language), extension: "csv")
        panel.title = L10n.exportDocument(language)
        panel.message = L10n.chooseCSVSaveLocation(language)
        panel.canCreateDirectories = true

        let response = panel.runModal()
        guard response == .OK else {
            return .cancelled
        }

        guard let url = panel.url else {
            return .failed
        }

        do {
            try data.write(to: url, options: [.atomic])
            NSWorkspace.shared.open(url)
            return .success
        } catch {
            return .failed
        }
    }

    private static func sanitizedPDFFilename(_ filename: String, language: AppLanguage) -> String {
        sanitizedFilename(filename, fallback: L10n.defaultPDFName(language), extension: "pdf")
    }

    private static func sanitizedFilename(_ filename: String, fallback: String, extension fileExtension: String) -> String {
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

        let safeBase = collapsed.isEmpty ? fallback : String(collapsed.prefix(120))
        return "\(safeBase).\(fileExtension)"
    }
}
