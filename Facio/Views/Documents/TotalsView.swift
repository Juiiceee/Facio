import SwiftUI

struct TotalsView: View {
    let document: Document
    @Environment(DataStore.self) private var dataStore

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

            GroupBox {
                VStack(alignment: .trailing, spacing: 8) {
                    totalRow(label: L10n.totalHT(lang), value: document.currency.formatAccounting(document.totalHT, lang: numberFormat), isDetail: false)

                    // Ventilation TVA
                    if tvaBreakdown.count > 1 {
                        ForEach(tvaBreakdown, id: \.rate) { entry in
                            totalRow(
                                label: L10n.vatRate(lang, rate: "\(entry.rate as NSDecimalNumber)"),
                                value: document.currency.formatAccounting(entry.amount, lang: numberFormat),
                                isDetail: true
                            )
                        }
                    }

                    totalRow(label: L10n.totalTVA(lang), value: document.currency.formatAccounting(document.totalTVA, lang: numberFormat), isDetail: false)

                    Divider()

                    HStack {
                        Text(L10n.totalTTC(lang))
                            .font(.headline)
                        Spacer()
                        Text(document.currency.formatAccounting(document.totalTTC, lang: numberFormat))
                            .font(.title3.monospacedDigit())
                            .fontWeight(.bold)
                    }
                }
                .padding(8)
            }
            .frame(maxWidth: 350)
        }
    }

    private func totalRow(label: String, value: String, isDetail: Bool) -> some View {
        HStack {
            Text(label)
                .font(isDetail ? Font.caption : Font.body)
                .foregroundStyle(isDetail ? .secondary : .primary)
            Spacer()
            Text(value)
                .font(isDetail ? Font.caption.monospacedDigit() : Font.body.monospacedDigit())
                .foregroundStyle(isDetail ? .secondary : .primary)
        }
    }
}
