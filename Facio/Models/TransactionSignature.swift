import Foundation

struct TransactionSignature: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var signature: String = ""
    var date: Date = Date()
    var montant: Decimal = 0
    var blockchainRawValue: String = "Solana"

    // MARK: - Computed

    var blockchain: Blockchain {
        get { Blockchain(rawValue: blockchainRawValue) ?? .solana }
        set { blockchainRawValue = newValue.rawValue }
    }

    /// URL vers la transaction sur l'explorateur blockchain
    var explorerURL: URL? {
        blockchain.explorerURL(signature: signature)
    }

    /// Nom de l'explorateur (ex: "Solscan", "Etherscan")
    var explorerName: String {
        blockchain.explorerName
    }

    // MARK: - Init

    init(
        signature: String = "",
        date: Date = Date(),
        montant: Decimal = 0,
        blockchain: Blockchain = .solana
    ) {
        self.id = UUID()
        self.signature = signature
        self.date = date
        self.montant = montant
        self.blockchainRawValue = blockchain.rawValue
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, signature, date, montant, blockchainRawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        signature = try container.decodeOrDefault(String.self, forKey: .signature, default: "")
        date = try container.decodeOrDefault(Date.self, forKey: .date, default: Date())
        montant = try container.decodeOrDefault(Decimal.self, forKey: .montant, default: 0)
        blockchainRawValue = try container.decodeOrDefault(String.self, forKey: .blockchainRawValue, default: Blockchain.solana.rawValue)
    }
}
