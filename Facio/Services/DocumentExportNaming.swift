import Foundation

/// Le nom de fichier proposé à l'export.
///
/// Les deux exports d'un même document — le PDF simple et le Factur-X — se
/// présentaient sous le MÊME nom (`document.number`). Exporter les deux dans le
/// même dossier proposait donc d'écraser le premier par le second, alors que ce
/// sont deux fichiers différents : l'un porte une facture électronique
/// structurée, l'autre non.
///
/// Le nom ne portait pas non plus le client : un dossier d'exports ne contenait
/// que des `Facture_2026_03.pdf` indistinguables d'un client à l'autre.
enum DocumentExportNaming {
    /// Suffixe qui distingue l'export structuré. Volontairement lisible : c'est
    /// lui qui dit à un comptable lequel des deux fichiers déposer.
    static let facturXSuffix = "Factur-X"

    /// Nom proposé pour un export PDF simple.
    static func pdfFilename(number: String, clientName: String) -> String {
        join([number, slug(clientName)])
    }

    /// Nom proposé pour un export Factur-X.
    static func facturXFilename(number: String, clientName: String) -> String {
        join([number, slug(clientName), facturXSuffix])
    }

    /// Réduit un nom de client à un fragment sûr pour un nom de fichier :
    /// accents conservés (macOS les accepte), séparateurs et ponctuation
    /// remplacés par un tiret, longueur bornée.
    static func slug(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        var out = ""
        var lastWasDash = false
        for character in trimmed {
            if character.isLetter || character.isNumber {
                out.append(character)
                lastWasDash = false
            } else if !lastWasDash, !out.isEmpty {
                out.append("-")
                lastWasDash = true
            }
        }
        while out.hasSuffix("-") { out.removeLast() }
        return String(out.prefix(40))
    }

    private static func join(_ parts: [String]) -> String {
        parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }
}
