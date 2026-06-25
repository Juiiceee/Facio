import SwiftUI

/// Préréglages de période pour le filtre des documents.
enum DateFilterPreset: String, CaseIterable, Identifiable {
    case all, thisMonth, thisYear, custom
    var id: String { rawValue }
}

/// État de filtre d'une liste de documents (factures / devis). Conditions
/// combinées en **ET** (style Notion). `matches(_:)` est pur (montant + date
/// fournis) pour rester testable.
struct DocumentFilter: Equatable {
    var statuses: Set<DocumentStatus> = []
    var overdueOnly = false
    var amountMin: Decimal = 0
    var amountMax: Decimal = 0
    var datePreset: DateFilterPreset = .all
    var dateFrom = Date()
    var dateTo = Date()
    var clientName = ""    // "" = tous les clients
    var currencyRaw = ""   // "" = toutes les devises

    var activeCount: Int {
        var n = 0
        if !statuses.isEmpty || overdueOnly { n += 1 }
        if amountMin > 0 || amountMax > 0 { n += 1 }
        if datePreset != .all { n += 1 }
        if !clientName.isEmpty { n += 1 }
        if !currencyRaw.isEmpty { n += 1 }
        return n
    }

    func matches(_ doc: Document, amount: Decimal, calendar: Calendar, now: Date) -> Bool {
        if !statuses.isEmpty && !statuses.contains(doc.status) { return false }
        if overdueOnly && !doc.isOverdue { return false }
        if amountMin > 0 && amount < amountMin { return false }
        if amountMax > 0 && amount > amountMax { return false }
        switch datePreset {
        case .all:
            break
        case .thisMonth:
            if !calendar.isDate(doc.dateCreation, equalTo: now, toGranularity: .month) { return false }
        case .thisYear:
            if !calendar.isDate(doc.dateCreation, equalTo: now, toGranularity: .year) { return false }
        case .custom:
            let start = calendar.startOfDay(for: dateFrom)
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: dateTo)) ?? dateTo
            if doc.dateCreation < start || doc.dateCreation >= end { return false }
        }
        if !clientName.isEmpty && doc.clientNom != clientName { return false }
        if !currencyRaw.isEmpty && doc.currency.rawValue != currencyRaw { return false }
        return true
    }
}

/// Panneau de filtres (contenu du popover « Filtrer ») pour les documents.
struct DocumentFilterPanel: View {
    @Binding var filter: DocumentFilter
    let clients: [String]
    let currencies: [CurrencyType]
    let lang: AppLanguage
    let numberFormat: AppLanguage
    var accent: Color = .accentColor
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space16) {
            header

            section(L10n.sortStatus(lang)) { statusGrid }
            section(L10n.filterAmount(lang)) { amountRow }
            section(L10n.filterPeriod(lang)) { periodControls }
            if !clients.isEmpty {
                section(L10n.sortClient(lang)) { clientMenu }
            }
            if currencies.count > 1 {
                section(L10n.filterCurrency(lang)) { currencyMenu }
            }
        }
        .padding(FacioLayout.space16)
        .frame(width: 320)
    }

    private var header: some View {
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
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space6) {
            Text(title.uppercased())
                .font(FacioFont.captionSmall)
                .foregroundStyle(.secondary)
            content()
        }
    }

    // MARK: - Statut

    private var statusGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: FacioLayout.space6)], alignment: .leading, spacing: FacioLayout.space6) {
            ForEach(DocumentStatus.allCases) { status in
                togglePill(
                    label: status.label(for: lang),
                    tone: Color.statusColor(for: status),
                    isOn: filter.statuses.contains(status)
                ) {
                    if filter.statuses.contains(status) { filter.statuses.remove(status) }
                    else { filter.statuses.insert(status) }
                }
            }
            togglePill(label: L10n.filterOverdue(lang), tone: .intentDanger, isOn: filter.overdueOnly) {
                filter.overdueOnly.toggle()
            }
        }
    }

    private func togglePill(label: String, tone: Color, isOn: Bool, toggle: @escaping () -> Void) -> some View {
        Button(action: toggle) {
            Text(label)
                .font(FacioFont.captionSmall)
                .fontWeight(isOn ? .semibold : .regular)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, FacioLayout.space8)
                .padding(.vertical, FacioLayout.space4)
                .foregroundStyle(isOn ? tone : Color.secondary)
                .background((isOn ? tone : Color.secondary).opacity(isOn ? 0.16 : 0.08), in: Capsule())
                .overlay(Capsule().strokeBorder(tone.opacity(isOn ? 0.5 : 0), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Montant

    private var amountRow: some View {
        HStack(spacing: FacioLayout.space8) {
            DecimalField(placeholder: L10n.filterMin(lang), value: $filter.amountMin, maximumFractionDigits: 2)
                .format(numberFormat)
                .density(.regular)
            Text("–").foregroundStyle(.secondary)
            DecimalField(placeholder: L10n.filterMax(lang), value: $filter.amountMax, maximumFractionDigits: 2)
                .format(numberFormat)
                .density(.regular)
        }
    }

    // MARK: - Période

    private var periodControls: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space8) {
            Picker("", selection: $filter.datePreset) {
                Text(L10n.periodAll(lang)).tag(DateFilterPreset.all)
                Text(L10n.periodThisMonth(lang)).tag(DateFilterPreset.thisMonth)
                Text(L10n.periodThisYear(lang)).tag(DateFilterPreset.thisYear)
                Text(L10n.periodCustom(lang)).tag(DateFilterPreset.custom)
            }
            .labelsHidden()
            .pickerStyle(.menu)

            if filter.datePreset == .custom {
                HStack(spacing: FacioLayout.space8) {
                    Text(L10n.filterFrom(lang)).font(FacioFont.captionSmall).foregroundStyle(.secondary)
                    DatePicker("", selection: $filter.dateFrom, displayedComponents: .date).labelsHidden()
                    Text(L10n.filterTo(lang)).font(FacioFont.captionSmall).foregroundStyle(.secondary)
                    DatePicker("", selection: $filter.dateTo, displayedComponents: .date).labelsHidden()
                }
            }
        }
    }

    // MARK: - Client

    private var clientMenu: some View {
        Menu {
            Button(L10n.filterAllClients(lang)) { filter.clientName = "" }
            Divider()
            ForEach(clients, id: \.self) { name in
                Button {
                    filter.clientName = name
                } label: {
                    if filter.clientName == name { Label(name, systemImage: "checkmark") } else { Text(name) }
                }
            }
        } label: {
            menuFieldLabel(filter.clientName.isEmpty ? L10n.filterAllClients(lang) : filter.clientName)
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Devise

    private var currencyMenu: some View {
        Menu {
            Button(L10n.filterAllCurrencies(lang)) { filter.currencyRaw = "" }
            Divider()
            ForEach(currencies) { currency in
                Button {
                    filter.currencyRaw = currency.rawValue
                } label: {
                    if filter.currencyRaw == currency.rawValue { Label(currency.label, systemImage: "checkmark") } else { Text(currency.label) }
                }
            }
        } label: {
            menuFieldLabel(filter.currencyRaw.isEmpty ? L10n.filterAllCurrencies(lang) : (CurrencyType(rawValue: filter.currencyRaw)?.label ?? filter.currencyRaw))
        }
        .menuStyle(.borderlessButton)
    }

    private func menuFieldLabel(_ text: String) -> some View {
        HStack {
            Text(text).lineLimit(1)
            Spacer()
            Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .font(FacioFont.captionSmall)
        .padding(.horizontal, FacioLayout.space10)
        .padding(.vertical, FacioLayout.space6)
        .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: FacioLayout.radiusField))
        .contentShape(Rectangle())
    }
}
