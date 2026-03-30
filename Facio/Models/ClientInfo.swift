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
    var createdAt: Date = Date()

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
        email: String = ""
    ) {
        self.id = UUID()
        self.nom = nom
        self.adresse = adresse
        self.codePostal = codePostal
        self.ville = ville
        self.email = email
        self.createdAt = Date()
    }

    /// Nom affiche avec ville
    var displayName: String {
        if ville.isEmpty {
            return nom
        }
        return "\(nom) — \(ville)"
    }

    /// Applique les infos client sur un document
    func appliquer(sur document: Document) {
        document.clientNom = nom
        document.clientAdresse = adresse
        document.clientCodePostal = codePostal
        document.clientVille = ville
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, nom, adresse, codePostal, ville, email, createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        nom = try container.decode(String.self, forKey: .nom)
        adresse = try container.decode(String.self, forKey: .adresse)
        codePostal = try container.decode(String.self, forKey: .codePostal)
        ville = try container.decode(String.self, forKey: .ville)
        email = try container.decode(String.self, forKey: .email)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nom, forKey: .nom)
        try container.encode(adresse, forKey: .adresse)
        try container.encode(codePostal, forKey: .codePostal)
        try container.encode(ville, forKey: .ville)
        try container.encode(email, forKey: .email)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
