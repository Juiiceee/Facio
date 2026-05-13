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
        if ville.isEmpty {
            return nom
        }
        return "\(nom) — \(ville)"
    }

    /// Vrai quand aucun champ utile n'est renseigne.
    var isEmptyRecord: Bool {
        [nom, adresse, codePostal, ville, email, siret, tva, ape].allSatisfy {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Applique les infos client sur un document
    func appliquer(sur document: Document) {
        document.clientNom = nom
        document.clientAdresse = adresse
        document.clientCodePostal = codePostal
        document.clientVille = ville
        document.clientSiret = siret
        document.clientTva = tva
        document.clientApe = ape
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, nom, adresse, codePostal, ville, email, siret, tva, ape, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        nom = container.decodeOrDefault(String.self, forKey: .nom, default: "")
        adresse = container.decodeOrDefault(String.self, forKey: .adresse, default: "")
        codePostal = container.decodeOrDefault(String.self, forKey: .codePostal, default: "")
        ville = container.decodeOrDefault(String.self, forKey: .ville, default: "")
        email = container.decodeOrDefault(String.self, forKey: .email, default: "")
        siret = container.decodeOrDefault(String.self, forKey: .siret, default: "")
        tva = container.decodeOrDefault(String.self, forKey: .tva, default: "")
        ape = container.decodeOrDefault(String.self, forKey: .ape, default: "")
        createdAt = container.decodeOrDefault(Date.self, forKey: .createdAt, default: Date())
        updatedAt = container.decodeOrDefault(Date.self, forKey: .updatedAt, default: createdAt)
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
