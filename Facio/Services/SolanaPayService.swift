import CoreGraphics
import Foundation
import SolKit
import SolKitPay

/// Génère un QR code Solana Pay pour les factures crypto sur Solana
struct SolanaPayService {

    /// Génère un QR code Solana Pay encodant la requête de paiement.
    /// Retourne nil si l'adresse wallet est invalide ou en cas d'erreur.
    static func generateQRCode(
        walletAddress: String,
        amount: Decimal,
        currency: CurrencyType,
        companyName: String,
        documentNumber: String
    ) -> CGImage? {
        do {
            let recipient = try PublicKey(string: walletAddress)

            let splToken: PublicKey? = if let mint = currency.solanaMintAddress {
                try PublicKey(string: mint)
            } else {
                nil
            }

            let request = TransferRequest(
                recipient: recipient,
                amount: amount,
                splToken: splToken,
                reference: [],
                label: companyName,
                message: documentNumber,
                memo: nil
            )

            return try QRCode.generate(from: request, size: 300)
        } catch {
            return nil
        }
    }
}
