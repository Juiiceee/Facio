import Foundation

// MARK: - Devise

enum CurrencyType: String, Codable, CaseIterable, Identifiable {
    case eur = "EUR"
    case usd = "USD"
    case usdc = "USDC"
    case usdt = "USDT"
    case btc = "BTC"
    case eth = "ETH"

    var id: String { rawValue }

    var label: String { rawValue }

    var symbole: String {
        switch self {
        case .eur: return "€"
        case .usd: return "$"
        case .usdc: return "USDC"
        case .usdt: return "USDT"
        case .btc: return "₿"
        case .eth: return "Ξ"
        }
    }

    /// Indique si cette devise nécessite un réseau blockchain
    var requiresBlockchain: Bool {
        switch self {
        case .usdc, .usdt: return true
        case .btc, .eth: return true
        case .eur, .usd: return false
        }
    }

    /// Indique si c'est une cryptomonnaie
    var isCrypto: Bool {
        switch self {
        case .eur, .usd: return false
        default: return true
        }
    }

    /// Adresse du mint SPL sur Solana (mainnet), nil si non applicable
    var solanaMintAddress: String? {
        switch self {
        case .usdc: return "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        case .usdt: return "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"
        default: return nil
        }
    }

    var supportsSolanaPay: Bool {
        solanaMintAddress != nil
    }

    var minimumFractionDigits: Int {
        switch self {
        case .eur, .usd, .usdc, .usdt: return 2
        case .btc, .eth: return 0
        }
    }

    var maximumFractionDigits: Int {
        switch self {
        case .eur, .usd: return 2
        case .usdc, .usdt: return 6
        case .btc, .eth: return 8
        }
    }

    /// Formatage du montant avec symbole
    func format(_ amount: Decimal) -> String {
        format(amount, lang: .fr)
    }

    func format(_ amount: Decimal, lang: AppLanguage) -> String {
        let formatted = formatNumber(amount, lang: lang)

        switch self {
        case .eur: return "\(formatted) €"
        case .usd: return "$\(formatted)"
        case .usdc, .usdt: return "\(formatted) \(rawValue)"
        case .btc: return "\(formatted) ₿"
        case .eth: return "\(formatted) Ξ"
        }
    }

    func formatNumber(_ amount: Decimal, lang: AppLanguage, usesGroupingSeparator: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: lang == .fr ? "fr_FR" : "en_US")
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.usesGroupingSeparator = usesGroupingSeparator
        if lang == .fr, usesGroupingSeparator {
            formatter.groupingSeparator = "\u{202F}" // narrow non-breaking space
        }

        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}
