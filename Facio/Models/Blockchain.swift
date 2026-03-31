import Foundation

// MARK: - Réseau Blockchain (modulaire)

enum Blockchain: String, Codable, CaseIterable, Identifiable {
    case solana = "Solana"
    case ethereum = "Ethereum"
    case bsc = "BSC"
    case polygon = "Polygon"
    case arbitrum = "Arbitrum"
    case base = "Base"
    case avalanche = "Avalanche"
    case bitcoin = "Bitcoin"

    var id: String { rawValue }

    var label: String { rawValue }

    var symboleNatif: String {
        switch self {
        case .solana: return "SOL"
        case .ethereum: return "ETH"
        case .bsc: return "BNB"
        case .polygon: return "MATIC"
        case .arbitrum: return "ETH"
        case .base: return "ETH"
        case .avalanche: return "AVAX"
        case .bitcoin: return "BTC"
        }
    }

    /// URL de base de l'explorateur de transactions
    var explorerTxBaseURL: String {
        switch self {
        case .solana: return "https://solscan.io/tx/"
        case .ethereum: return "https://etherscan.io/tx/"
        case .bsc: return "https://bscscan.com/tx/"
        case .polygon: return "https://polygonscan.com/tx/"
        case .arbitrum: return "https://arbiscan.io/tx/"
        case .base: return "https://basescan.org/tx/"
        case .avalanche: return "https://snowtrace.io/tx/"
        case .bitcoin: return "https://mempool.space/tx/"
        }
    }

    /// URL de base de l'explorateur de wallets
    var explorerWalletBaseURL: String {
        switch self {
        case .solana: return "https://solscan.io/account/"
        case .ethereum: return "https://etherscan.io/address/"
        case .bsc: return "https://bscscan.com/address/"
        case .polygon: return "https://polygonscan.com/address/"
        case .arbitrum: return "https://arbiscan.io/address/"
        case .base: return "https://basescan.org/address/"
        case .avalanche: return "https://snowtrace.io/address/"
        case .bitcoin: return "https://mempool.space/address/"
        }
    }

    /// Nom de l'explorateur
    var explorerName: String {
        switch self {
        case .solana: return "Solscan"
        case .ethereum: return "Etherscan"
        case .bsc: return "BscScan"
        case .polygon: return "Polygonscan"
        case .arbitrum: return "Arbiscan"
        case .base: return "Basescan"
        case .avalanche: return "Snowtrace"
        case .bitcoin: return "Mempool"
        }
    }

    /// Construit l'URL vers la transaction sur l'explorateur
    func explorerURL(signature: String) -> URL? {
        guard let encoded = signature.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: explorerTxBaseURL + encoded)
    }

    /// Construit l'URL vers le wallet sur l'explorateur
    func walletURL(address: String) -> URL? {
        URL(string: explorerWalletBaseURL + address)
    }

    /// Réseaux compatibles avec une devise donnée
    static func compatibleBlockchains(for currency: CurrencyType) -> [Blockchain] {
        switch currency {
        case .usdc:
            return [.solana, .ethereum, .bsc, .polygon, .arbitrum, .base, .avalanche]
        case .usdt:
            return [.solana, .ethereum, .bsc, .polygon, .arbitrum, .avalanche]
        case .btc:
            return [.bitcoin]
        case .eth:
            return [.ethereum, .arbitrum, .base]
        case .eur, .usd:
            return []
        }
    }
}
