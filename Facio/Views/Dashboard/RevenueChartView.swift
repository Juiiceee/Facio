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
    /// Ouvre le mois cliqué. Le graphique ne se contente plus de montrer une
    /// forme : chaque barre est une porte vers les factures qu'elle agrège.
    var onSelectMonth: (RevenueMonth) -> Void = { _ in }

    @Environment(PrivacyMode.self) private var privacy
    /// Mois survolé — pilote l'infobulle et le liseré de la barre visée.
    @State private var hovered: RevenueMonth?

    private var maximum: Decimal {
        max(months.map(\.collected).max() ?? 0, 1)
    }

    /// Le mois survolé prime sur le mois courant : c'est lui que l'œil suit.
    private func barStyle(for month: RevenueMonth) -> Color {
        if hovered?.id == month.id { return FacioIntent.info.glyph }
        return month.isCurrent ? FacioIntent.info.glyph : Color.accentTint
    }

    /// Le mois sous le pointeur, ou `nil` hors de la zone traçable.
    private func month(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> RevenueMonth? {
        guard let plotFrame = proxy.plotFrame else { return nil }
        let origin = geometry[plotFrame].origin
        let x = location.x - origin.x
        guard let date: Date = proxy.value(atX: x) else { return nil }
        // La barre couvre son mois : on cherche celui qui CONTIENT la date, au
        // lieu du plus proche — sinon les bords retombent sur le mois voisin.
        let calendar = Calendar.current
        return months.first { candidate in
            guard let interval = calendar.dateInterval(of: .month, for: candidate.start) else { return false }
            return interval.contains(date)
        }
    }

    private func tooltip(for month: RevenueMonth) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space2) {
            Text(month.start.formatted(.dateTime.month(.wide).year()))
                .font(FacioFont.label)
                .foregroundStyle(Color.textSecondary)
            Text(privacy.format(month.collected, currency, lang: numberFormat))
                .font(FacioFont.amount)
                .foregroundStyle(Color.textPrimary)
            Text(L10n.chartOpenMonthHint(lang))
                .font(FacioFont.label)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(FacioLayout.space8)
        .background(Color.surfaceFloat)
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusMedium))
        .facioElevation(.e2, radius: FacioLayout.radiusMedium)
        .fixedSize()
        .allowsHitTesting(false)
    }

    var body: some View {
        Chart(months) { month in
            BarMark(
                x: .value(L10n.month(lang), month.start, unit: .month),
                y: .value(L10n.revenueCollected(lang), (month.collected as NSDecimalNumber).doubleValue)
            )
            // Le mois en cours porte l'aplat, les autres une teinte : la lecture
            // « où j'en suis » commence par lui.
            .foregroundStyle(barStyle(for: month))
            .cornerRadius(FacioLayout.space4)
            // L'infobulle est une ANNOTATION de la barre, pas un calque au coin
            // du graphique : Charts la place au-dessus de la barre visée, la
            // centre, et `overflowResolution` la ramène dans le cadre quand la
            // barre est en bord de série. Aucune géométrie à recalculer à la
            // main, et l'information reste là où l'œil est déjà.
            .annotation(
                position: .top,
                alignment: .center,
                spacing: FacioLayout.space4,
                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            ) {
                if hovered?.id == month.id {
                    tooltip(for: month)
                } else if month.isCurrent {
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
        // Survol et clic passent par une surface posée SUR la zone traçable :
        // `chartOverlay` donne les coordonnées du graphique, donc la date sous
        // le pointeur, sans avoir à deviner la géométrie des barres.
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case let .active(location):
                            hovered = month(at: location, proxy: proxy, geometry: geometry)
                        case .ended:
                            hovered = nil
                        }
                    }
                    .onTapGesture { location in
                        if let month = month(at: location, proxy: proxy, geometry: geometry) {
                            onSelectMonth(month)
                        }
                    }
            }
        }
        .frame(height: 160)
        .accessibilityLabel(L10n.revenueSeriesAccessibility(lang, count: months.count))
    }
}
