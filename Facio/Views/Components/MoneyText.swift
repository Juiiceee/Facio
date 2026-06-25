import SwiftUI

/// Affiche un montant formaté, masqué par `••••` quand le mode confidentialité
/// est actif. Remplace `Text(currency.formatAccounting(montant, lang:))` ; les
/// modifieurs habituels (`.font`, `.lineLimit`, `.minimumScaleFactor`,
/// `.foregroundStyle`) se posent sur le `MoneyText` et se propagent au `Text`.
struct MoneyText: View {
    let amount: Decimal
    let currency: CurrencyType
    let lang: AppLanguage

    @Environment(PrivacyMode.self) private var privacy

    var body: some View {
        Text(privacy.format(amount, currency, lang: lang))
    }
}
