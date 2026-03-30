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
}
