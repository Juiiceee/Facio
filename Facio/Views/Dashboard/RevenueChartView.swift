import Charts
import SwiftUI

/// La série mensuelle des encaissements.
///
/// **Une seule série** — le titre la nomme, donc pas de légende : une légende
/// pour une seule série est du chrome. Le mois en cours est le seul point
/// étiqueté ; une valeur sur chaque barre serait illisible sur douze mois.
///
/// La grille est récessive, l'axe des montants réduit à trois graduations : ce
/// qu'on lit ici, c'est une forme, pas des nombres au pixel — les nombres exacts
/// vivent dans les tuiles juste au-dessus et dans l'infobulle.
struct RevenueChartView: View {
    let months: [RevenueMonth]
    let currency: CurrencyType
    let lang: AppLanguage
    let numberFormat: AppLanguage

    @Environment(PrivacyMode.self) private var privacy

    private var maximum: Decimal {
        max(months.map(\.collected).max() ?? 0, 1)
    }

    var body: some View {
        Chart(months) { month in
            BarMark(
                x: .value(L10n.month(lang), month.start, unit: .month),
                y: .value(L10n.revenueCollected(lang), (month.collected as NSDecimalNumber).doubleValue)
            )
            // Le mois en cours porte l'aplat, les autres une teinte : la lecture
            // « où j'en suis » commence par lui.
            .foregroundStyle(month.isCurrent ? FacioIntent.info.glyph : Color.accentTint)
            .cornerRadius(FacioLayout.space4)
            .annotation(position: .top, alignment: .center) {
                if month.isCurrent {
                    Text(privacy.format(month.collected, currency, lang: numberFormat))
                        .font(FacioFont.label)
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) {
                AxisGridLine().foregroundStyle(Color.borderDivider)
                AxisValueLabel()
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: 2)) { value in
                AxisValueLabel(format: .dateTime.month(.narrow))
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(height: 160)
        .accessibilityLabel(L10n.revenueSeriesAccessibility(lang, count: months.count))
    }
}
