import Foundation
import Observation

@Observable
final class ClientInfo: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var nom: String = ""
    var adresse: String = ""
    var codePostal: String = ""
    var ville: String = ""
    var email: String = ""
    var siret: String = ""
    var tva: String = ""
    var ape: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Hashable

    static func == (lhs: ClientInfo, rhs: ClientInfo) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init(
        nom: String = "",
        adresse: String = "",
        codePostal: String = "",
        ville: String = "",
        email: String = "",
        siret: String = "",
        tva: String = "",
        ape: String = ""
    ) {
        self.id = UUID()
        self.nom = nom
        self.adresse = adresse
        self.codePostal = codePostal
        self.ville = ville
        self.email = email
        self.siret = siret
        self.tva = tva
        self.ape = ape
        self.createdAt = Date()
    }

    /// Nom affiche avec ville
    var displayName: String {
        let name = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = ville.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty, !city.isEmpty {
            return "\(name) — \(city)"
        }
        if !name.isEmpty { return name }

        let fallback = [email, siret, tva, ape]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        return fallback ?? ""
    }

    /// Vrai quand aucun champ utile n'est renseigne.
    var isEmptyRecord: Bool {
        [nom, adresse, codePostal, ville, email, siret, tva, ape].allSatisfy {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Vrai quand `document` appartient à ce client.
    ///
    /// Le lien stable fait autorité : s'il est posé, il tranche, y compris pour
    /// dire NON (un document explicitement rattaché à un autre client n'est pas
    /// à nous, même si les noms coïncident).
    ///
    /// Les documents créés avant ce lien n'en ont pas : on retombe alors sur la
    /// comparaison de chaînes historique — faillible (renommer détache), mais
    /// c'est le comportement qu'ils ont toujours eu, et le seul disponible.
    func matches(_ document: Document) -> Bool {
        if let linked = document.clientId {
            return linked == id
        }

        let normalized: (String) -> String = { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let mine = normalized(nom)
        if !mine.isEmpty, mine == normalized(document.clientNom) { return true }

        let identifiers = [
            (siret, document.clientSiret),
            (tva, document.clientTva),
            (ape, document.clientApe)
        ]
        return identifiers.contains { lhs, rhs in
            let left = normalized(lhs)
            return !left.isEmpty && left == normalized(rhs)
        }
    }

    /// Applique les infos client sur un document
    func appliquer(sur document: Document) {
        // Le lien stable, en plus de la copie figée : renommer la fiche ensuite
        // ne doit plus détacher le document de son client.
        document.clientId = id
        document.clientNom = nom
        document.clientAdresse = adresse
        document.clientCodePostal = codePostal
        document.clientVille = ville
        document.clientSiret = siret
        document.clientTva = tva
        document.clientApe = ape
        document.clientEmail = email
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, nom, adresse, codePostal, ville, email, siret, tva, ape, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        nom = try container.decodeOrDefault(String.self, forKey: .nom, default: "")
        adresse = try container.decodeOrDefault(String.self, forKey: .adresse, default: "")
        codePostal = try container.decodeOrDefault(String.self, forKey: .codePostal, default: "")
        ville = try container.decodeOrDefault(String.self, forKey: .ville, default: "")
        email = try container.decodeOrDefault(String.self, forKey: .email, default: "")
        siret = try container.decodeOrDefault(String.self, forKey: .siret, default: "")
        tva = try container.decodeOrDefault(String.self, forKey: .tva, default: "")
        ape = try container.decodeOrDefault(String.self, forKey: .ape, default: "")
        createdAt = try container.decodeOrDefault(Date.self, forKey: .createdAt, default: Date())
        updatedAt = try container.decodeOrDefault(Date.self, forKey: .updatedAt, default: createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nom, forKey: .nom)
        try container.encode(adresse, forKey: .adresse)
        try container.encode(codePostal, forKey: .codePostal)
        try container.encode(ville, forKey: .ville)
        try container.encode(email, forKey: .email)
        try container.encode(siret, forKey: .siret)
        try container.encode(tva, forKey: .tva)
        try container.encode(ape, forKey: .ape)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
