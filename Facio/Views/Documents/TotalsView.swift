import SwiftUI

struct TotalsView: View {
    let document: Document
    @Environment(DataStore.self) private var dataStore
    @Environment(PrivacyMode.self) private var privacy
    @Environment(\.facioWidthClass) private var widthClass

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }

    /// Ventilation TVA par taux
    private var tvaBreakdown: [(rate: Decimal, amount: Decimal)] {
        var grouped: [Decimal: Decimal] = [:]
        for ligne in document.lignes {
            let key = ligne.tauxTVA
            grouped[key, default: 0] += ligne.montantTVA
        }
        return grouped
            .filter { $0.value != 0 }
            .map { (rate: $0.key, amount: $0.value) }
            .sorted { $0.rate < $1.rate }
    }

    var body: some View {
        HStack {
            Spacer()

            SectionPanel {
                VStack(alignment: .trailing, spacing: FacioLayout.space8) {
                    totalRow(label: L10n.totalHT(lang), value: privacy.format(document.totalHT, document.currency, lang: numberFormat), isDetail: false)

                    // Ventilation TVA
                    if tvaBreakdown.count > 1 {
                        ForEach(tvaBreakdown, id: \.rate) { entry in
                            totalRow(
                                label: L10n.vatRate(lang, rate: "\(entry.rate as NSDecimalNumber)"),
                                value: privacy.format(entry.amount, document.currency, lang: numberFormat),
                                isDetail: true
                            )
                        }
                    }

                    totalRow(label: L10n.totalTVA(lang), value: privacy.format(document.totalTVA, document.currency, lang: numberFormat), isDetail: false)

                    Divider()

                    HStack {
                        Text(L10n.totalTTC(lang))
                            .font(FacioFont.sectionTitle)
                        Spacer()
                        MoneyText(amount: document.totalTTC, currency: document.currency, lang: numberFormat)
                            .font(FacioFont.amountEmphasis)
                    }
                }
            }
            // Pleine largeur en compact, sinon panneau aligné à droite.
            .frame(maxWidth: widthClass == .compact ? .infinity : FacioLayout.totalsMaxWidth)
        }
    }

    private func totalRow(label: String, value: String, isDetail: Bool) -> some View {
        HStack {
            Text(label)
                .font(isDetail ? FacioFont.caption : FacioFont.body)
                .foregroundStyle(isDetail ? .secondary : .primary)
            Spacer()
            Text(value)
                .font(isDetail ? FacioFont.metaValue : FacioFont.amount)
                .foregroundStyle(isDetail ? .secondary : .primary)
        }
    }
}
