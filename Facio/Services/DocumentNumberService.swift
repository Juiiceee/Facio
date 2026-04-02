import Foundation

struct DocumentNumberService {
    /// Genere le prochain numero de document
    /// Format: "Facture_2026_03" ou "Devis_2026_01"
    static func nextNumber(
        type: DocumentType,
        existingDocuments: [Document],
        date: Date = Date(),
        language: AppLanguage = .fr
    ) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)

        // Filtrer les documents du meme type et de la meme annee
        let sameTypeAndYear = existingDocuments.filter { doc in
            doc.type == type &&
            calendar.component(.year, from: doc.dateCreation) == year
        }

        // Trouver le numero le plus eleve
        var maxNumber = 0
        for doc in sameTypeAndYear {
            let parts = doc.number.split(separator: "_")
            if let last = parts.last, let num = Int(last) {
                maxNumber = max(maxNumber, num)
            }
        }

        let nextNum = maxNumber + 1
        return String(format: "%@_%d_%02d", type.prefix(for: language), year, nextNum)
    }
}
