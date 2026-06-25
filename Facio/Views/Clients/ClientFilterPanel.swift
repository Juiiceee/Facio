import SwiftUI

/// État de filtre de la liste des clients. Conditions combinées en ET.
struct ClientFilter: Equatable {
    var onlyWithUnpaid = false
    var invoicedMin: Decimal = 0
    var invoicedMax: Decimal = 0

    var activeCount: Int {
        var n = 0
        if onlyWithUnpaid { n += 1 }
        if invoicedMin > 0 || invoicedMax > 0 { n += 1 }
        return n
    }

    /// `totalInvoiced` est fourni par l'appelant (déjà converti en devise comptable).
    func matches(hasUnpaid: Bool, totalInvoiced: Decimal) -> Bool {
        if onlyWithUnpaid && !hasUnpaid { return false }
        if invoicedMin > 0 && totalInvoiced < invoicedMin { return false }
        if invoicedMax > 0 && totalInvoiced > invoicedMax { return false }
        return true
    }
}

/// Panneau de filtres (contenu du popover « Filtrer ») pour les clients.
struct ClientFilterPanel: View {
    @Binding var filter: ClientFilter
    let lang: AppLanguage
    let numberFormat: AppLanguage
    var accent: Color = .accentColor
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space16) {
            HStack {
                Text(L10n.filterButton(lang)).font(.headline)
                Spacer()
                if filter.activeCount > 0 {
                    Button(L10n.filterReset(lang), action: onReset)
                        .buttonStyle(.plain)
                        .font(FacioFont.captionSmall)
                        .foregroundStyle(accent)
                }
            }

            Toggle(isOn: $filter.onlyWithUnpaid) {
                Text(L10n.filterWithUnpaid(lang)).font(FacioFont.captionSmall)
            }
            .toggleStyle(.switch)
            .tint(accent)

            VStack(alignment: .leading, spacing: FacioLayout.space6) {
                Text(L10n.sortTotalInvoiced(lang).uppercased())
                    .font(FacioFont.captionSmall)
                    .foregroundStyle(.secondary)
                HStack(spacing: FacioLayout.space8) {
                    DecimalField(placeholder: L10n.filterMin(lang), value: $filter.invoicedMin, maximumFractionDigits: 2)
                        .format(numberFormat)
                        .density(.regular)
                    Text("–").foregroundStyle(.secondary)
                    DecimalField(placeholder: L10n.filterMax(lang), value: $filter.invoicedMax, maximumFractionDigits: 2)
                        .format(numberFormat)
                        .density(.regular)
                }
            }
        }
        .padding(FacioLayout.space16)
        .frame(width: 300)
    }
}
