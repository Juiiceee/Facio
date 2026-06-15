import Foundation

/// Justificatif (pièce jointe) rattaché à un document : billet de train, note de
/// frais, reçu… Le fichier physique est stocké **localement** par `DataStore`
/// sous `attachments/<documentId>/<id>.<fileExtension>`. Ce modèle ne porte que
/// les métadonnées, sérialisées dans `documents.json` (le binaire ne transite
/// pas par la sync).
struct DocumentAttachment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    /// Nom du fichier d'origine (affiché à l'utilisateur).
    var originalFilename: String = ""
    /// Extension (sans le point), ex. `pdf`, `jpg`.
    var fileExtension: String = ""
    /// Libellé éditable (ex. « Train Nancy⇄Paris »). Vide → on affiche le nom du fichier.
    var label: String = ""
    /// Taille en octets (pour affichage).
    var fileSize: Int = 0
    var addedAt: Date = Date()
    /// Montant du justificatif, reportable en ligne de facture. `0` = non renseigné.
    var montant: Decimal = 0
    /// Taux de TVA (%) appliqué au report.
    var tauxTVA: Decimal = 0
    /// `true` si `montant` est saisi TTC (on calcule le HT à rebours au report),
    /// `false` s'il est saisi HT (utilisé tel quel comme prix unitaire).
    var montantEstTTC: Bool = false

    init(
        id: UUID = UUID(),
        originalFilename: String = "",
        fileExtension: String = "",
        label: String = "",
        fileSize: Int = 0,
        addedAt: Date = Date(),
        montant: Decimal = 0,
        tauxTVA: Decimal = 0,
        montantEstTTC: Bool = false
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.fileExtension = fileExtension
        self.label = label
        self.fileSize = fileSize
        self.addedAt = addedAt
        self.montant = montant
        self.tauxTVA = tauxTVA
        self.montantEstTTC = montantEstTTC
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        originalFilename = try container.decodeOrDefault(String.self, forKey: .originalFilename, default: "")
        fileExtension = try container.decodeOrDefault(String.self, forKey: .fileExtension, default: "")
        label = try container.decodeOrDefault(String.self, forKey: .label, default: "")
        fileSize = try container.decodeOrDefault(Int.self, forKey: .fileSize, default: 0)
        addedAt = try container.decodeOrDefault(Date.self, forKey: .addedAt, default: Date())
        montant = try container.decodeOrDefault(Decimal.self, forKey: .montant, default: 0)
        tauxTVA = try container.decodeOrDefault(Decimal.self, forKey: .tauxTVA, default: 0)
        montantEstTTC = try container.decodeOrDefault(Bool.self, forKey: .montantEstTTC, default: false)
    }

    private enum CodingKeys: String, CodingKey {
        case id, originalFilename, fileExtension, label, fileSize, addedAt, montant, tauxTVA, montantEstTTC
    }

    /// Montant HT effectif pour un report en ligne de facture.
    var montantHT: Decimal {
        guard montantEstTTC else { return montant }
        let diviseur = 1 + tauxTVA / 100
        return diviseur == 0 ? montant : montant / diviseur
    }

    /// Nom du fichier tel que stocké sur disque.
    var storedFilename: String {
        fileExtension.isEmpty ? id.uuidString : "\(id.uuidString).\(fileExtension)"
    }

    /// Libellé d'affichage (label si renseigné, sinon nom de fichier).
    var displayName: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? originalFilename : trimmed
    }

    var isImage: Bool {
        ["png", "jpg", "jpeg", "heic", "heif", "gif", "tiff", "tif", "bmp"].contains(fileExtension.lowercased())
    }

    var isPDF: Bool { fileExtension.lowercased() == "pdf" }

    var iconName: String {
        if isPDF { return "doc.richtext" }
        if isImage { return "photo" }
        return "paperclip"
    }

    /// Taille lisible (Ko/Mo).
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
}
