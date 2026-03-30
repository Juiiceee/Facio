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

    /// Formatage du montant avec symbole
    func format(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","

        let formatted = formatter.string(from: amount as NSDecimalNumber) ?? "0,00"

        switch self {
        case .eur: return "\(formatted) €"
        case .usd: return "$\(formatted)"
        case .usdc, .usdt: return "\(formatted) \(rawValue)"
        case .btc: return "\(formatted) ₿"
        case .eth: return "\(formatted) Ξ"
        }
    }
}
