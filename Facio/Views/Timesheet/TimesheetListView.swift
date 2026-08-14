import SwiftUI

private enum NewTimesheetPeriodMode: String, CaseIterable, Identifiable {
    case month
    case custom

    var id: String { rawValue }
}

struct TimesheetListView: View {
    @Binding var selectedTimesheetId: UUID?
    var onOpenInvoice: (Document) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore
    @State private var showNewPeriod = false
    @State private var timesheetPendingDeletion: TimesheetPeriod?
    @State private var showInvoiceDetailOptions = false
    @State private var newPeriodMode: NewTimesheetPeriodMode = .month
    @State private var selectedMois: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedAnnee: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedStartDate: Date = Date()
    @State private var selectedEndDate: Date = Date()
    @State private var selectedClientId: UUID?
    @State private var pendingInvoiceTimesheet: TimesheetPeriod?

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }

    private var timesheets: [TimesheetPeriod] {
        dataStore.timesheets.sorted {
            if $0.annee != $1.annee { return $0.annee > $1.annee }
            if $0.mois != $1.mois { return $0.mois > $1.mois }
            return $0.clientDisplayName.localizedCaseInsensitiveCompare($1.clientDisplayName) == .orderedAscending
        }
    }

    private var selectedClient: ClientInfo? {
        guard let selectedClientId else { return nil }
        return dataStore.clients.first { $0.id == selectedClientId }
    }

    private var clients: [ClientInfo] {
        dataStore.clients.sorted { $0.nom < $1.nom }
    }

    private var moisLabels: [String] {
        let f = DateFormatter()
        f.locale = Locale(identifier: lang == .fr ? "fr_FR" : "en_US")
        return f.monthSymbols.map { $0.capitalized }
    }

    /// Verifie si une periode existe deja pour ce mois/annee
    private func periodeExiste(mois: Int, annee: Int, clientId: UUID?) -> Bool {
        dataStore.timesheetExists(mois: mois, annee: annee, clientId: clientId)
    }

    private var selectedRangeOverlaps: Bool {
        guard selectedClientId != nil else { return false }
        return dataStore.timesheetOverlaps(
            startDate: selectedPeriodStartDate,
            endDate: selectedPeriodEndDate,
            clientId: selectedClientId
        )
    }

    private var selectedPeriodStartDate: Date {
        switch newPeriodMode {
        case .month:
            return Self.monthStartDate(mois: selectedMois, annee: selectedAnnee)
        case .custom:
            return selectedStartDate
        }
    }

    private var selectedPeriodEndDate: Date {
        switch newPeriodMode {
        case .month:
            return Self.monthEndDate(mois: selectedMois, annee: selectedAnnee)
        case .custom:
            return selectedEndDate
        }
    }

    var body: some View {
        List(selection: $selectedTimesheetId) {
            ForEach(timesheets) { ts in
                TimesheetRowView(
                    timesheet: ts,
                    lang: lang,
                    numberFormat: numberFormat,
                    adjacentHours: dataStore.adjacentHours(for: ts)
                )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .tag(ts.id)
                    .contextMenu {
                        if let invoice = dataStore.existingBillableHoursInvoice(for: ts) {
                            Button {
                                onOpenInvoice(invoice)
                            } label: {
                                Label(L10n.openInvoice(lang), systemImage: "doc.text.magnifyingglass")
                            }
                        } else {
                            Button {
                                presentInvoiceOptions(for: ts)
                            } label: {
                                Label(L10n.generateInvoice(lang), systemImage: "doc.text")
                            }
                            .disabled(!dataStore.canGenerateInvoice(for: ts))
                        }
                        Divider()
                        Button(role: .destructive) {
                            timesheetPendingDeletion = ts
                        } label: {
                            Label(L10n.delete(lang), systemImage: "trash")
                        }
                    }
            }
        }
        .id(timesheets.count)
        .navigationTitle(L10n.sidebarTime(lang))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    presentNewPeriod()
                } label: {
                    Label(L10n.newPeriod(lang), systemImage: "plus")
                }
                .popover(isPresented: $showNewPeriod) {
                    newPeriodPopover
                }
            }
        }
        .confirmationDialog(
            L10n.invoiceDetailMode(lang),
            isPresented: $showInvoiceDetailOptions,
            titleVisibility: .visible,
            presenting: pendingInvoiceTimesheet
        ) { ts in
            Button(TimesheetInvoiceDetailMode.summary.label(for: lang)) {
                genererFacture(ts, detailMode: .summary)
            }
            Button(TimesheetInvoiceDetailMode.daily.label(for: lang)) {
                genererFacture(ts, detailMode: .daily)
            }
            Button(TimesheetInvoiceDetailMode.dailyActivity.label(for: lang)) {
                genererFacture(ts, detailMode: .dailyActivity)
            }
            Button(L10n.cancel(lang), role: .cancel) {}
        } message: { _ in
            Text(L10n.chooseInvoiceDetail(lang))
        }
        .alert(
            L10n.deletePeriodConfirmTitle(lang),
            isPresented: Binding(
                get: { timesheetPendingDeletion != nil },
                set: { if !$0 { timesheetPendingDeletion = nil } }
            )
        ) {
            Button(L10n.cancel(lang), role: .cancel) {
                timesheetPendingDeletion = nil
            }
            Button(L10n.delete(lang), role: .destructive) {
                if let ts = timesheetPendingDeletion {
                    if selectedTimesheetId == ts.id { selectedTimesheetId = nil }
                    dataStore.deleteTimesheet(ts)
                }
                timesheetPendingDeletion = nil
            }
        } message: {
            Text(L10n.deletePeriodConfirmMessage(
                lang,
                label: timesheetPendingDeletion?.periodLabel(for: lang) ?? ""
            ))
        }
        .overlay {
            if timesheets.isEmpty {
                FacioEmptyState(
                    title: L10n.noPeriod(lang),
                    systemImage: "clock",
                    message: L10n.clickToCreatePeriod(lang)
                ) {
                    FacioButton(L10n.newPeriod(lang), systemImage: "plus") {
                        presentNewPeriod()
                    }
                }
            }
        }
    }

    /// Réinitialise le brouillon de période (mois courant) puis ouvre le popover.
    /// Partagé entre le bouton de toolbar et le CTA de l'état vide.
    private func presentNewPeriod() {
        let cal = Calendar.current
        let now = Date()
        newPeriodMode = .month
        selectedMois = cal.component(.month, from: now)
        selectedAnnee = cal.component(.year, from: now)
        selectedStartDate = now
        selectedEndDate = now
        selectedClientId = nil
        showNewPeriod = true
    }

    // MARK: - Popover nouvelle periode

    private var newPeriodPopover: some View {
        VStack(spacing: FacioLayout.space16) {
            Text(L10n.newPeriod(lang))
                .font(FacioFont.sectionTitle)

            Picker("", selection: $newPeriodMode) {
                Text(L10n.monthlyPeriod(lang)).tag(NewTimesheetPeriodMode.month)
                Text(L10n.customPeriod(lang)).tag(NewTimesheetPeriodMode.custom)
            }
            .labelsHidden()
            .pickerStyle(.segmented)

            switch newPeriodMode {
            case .month:
                HStack(spacing: FacioLayout.space12) {
                    Picker(L10n.month(lang), selection: $selectedMois) {
                        ForEach(1...12, id: \.self) { m in
                            Text(moisLabels[m - 1]).tag(m)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)

                    Picker(L10n.year(lang), selection: $selectedAnnee) {
                        ForEach((selectedAnnee - 2)...(selectedAnnee + 1), id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 80)
                }
            case .custom:
                VStack(spacing: FacioLayout.space10) {
                    DatePicker(
                        L10n.startDate(lang),
                        selection: $selectedStartDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        L10n.endDate(lang),
                        selection: $selectedEndDate,
                        displayedComponents: .date
                    )
                }
                .onChange(of: selectedStartDate) { _, startDate in
                    if selectedEndDate < startDate {
                        selectedEndDate = startDate
                    }
                }
                .onChange(of: selectedEndDate) { _, endDate in
                    if endDate < selectedStartDate {
                        selectedStartDate = endDate
                    }
                }
            }

            HStack(spacing: FacioLayout.space12) {
                Text(L10n.selectClientForPeriod(lang))
                    .font(FacioFont.fieldLabel)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker(L10n.selectClientForPeriod(lang), selection: $selectedClientId) {
                    Text(L10n.selectClientForPeriod(lang))
                        .tag(UUID?.none)
                    ForEach(clients) { client in
                        Text(client.displayName)
                            .tag(Optional(client.id))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 220)
            }

            if selectedClientId == nil {
                InlineWarning(text: L10n.clientRequired(lang), tone: .warning)
            } else if selectedRangeOverlaps {
                InlineWarning(text: L10n.periodOverlapsForClient(lang), tone: .warning)
            }

            HStack(spacing: FacioLayout.space12) {
                Button(L10n.cancel(lang)) {
                    showNewPeriod = false
                }
                .buttonStyle(.facio(.secondary))

                Button(L10n.create(lang)) {
                    creerPeriode(client: selectedClient)
                    showNewPeriod = false
                }
                .buttonStyle(.facio(.primary))
                .disabled(selectedClient == nil || selectedRangeOverlaps)
            }
        }
        .padding(FacioLayout.space20)
        // Largeur souple : le popover se resserre sur les petites fenêtres.
        .frame(minWidth: 360, idealWidth: 400, maxWidth: 440)
    }

    private func creerPeriode(client: ClientInfo?) {
        guard let client else { return }
        let ts: TimesheetPeriod
        switch newPeriodMode {
        case .month:
            ts = TimesheetPeriod(mois: selectedMois, annee: selectedAnnee, client: client)
        case .custom:
            ts = TimesheetPeriod(startDate: selectedStartDate, endDate: selectedEndDate, client: client)
        }

        // Copier les taux depuis la derniere periode du meme client.
        if let last = timesheets.first(where: { $0.clientId == client.id }) {
            ts.tauxNormal = last.tauxNormal
            ts.tauxSupplementaire = last.tauxSupplementaire
            ts.coefficientNet = last.coefficientNet
            ts.seuilHebdo = last.seuilHebdo
        }

        dataStore.addTimesheet(ts)
        dataStore.syncSharedWeeks(for: ts)
        selectedTimesheetId = ts.id
    }

    private static func monthStartDate(mois: Int, annee: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: annee, month: mois, day: 1)) ?? Date()
    }

    private static func monthEndDate(mois: Int, annee: Int) -> Date {
        let start = monthStartDate(mois: mois, annee: annee)
        return Calendar(identifier: .gregorian).date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
    }

    private func presentInvoiceOptions(for ts: TimesheetPeriod) {
        pendingInvoiceTimesheet = ts
        showInvoiceDetailOptions = true
    }

    private func genererFacture(_ ts: TimesheetPeriod, detailMode: TimesheetInvoiceDetailMode) {
        if let invoice = dataStore.generateInvoice(from: ts, detailMode: detailMode) {
            onOpenInvoice(invoice)
        }
    }
}

// MARK: - Row

private struct TimesheetRowView: View {
    let timesheet: TimesheetPeriod
    let lang: AppLanguage
    let numberFormat: AppLanguage
    let adjacentHours: [String: Decimal]

    @Environment(PrivacyMode.self) private var privacy

    var body: some View {
        let heuresMois = timesheet.totalHeuresDuMois()
        let heuresSup = timesheet.totalHeuresSupCrossPeriod(adjacentHours: adjacentHours)
        let brut = timesheet.totalBrutCrossPeriod(adjacentHours: adjacentHours)

        FacioListRow(tone: timesheet.hasGeneratedInvoice ? .intentSuccess : .intentWarning) {
            VStack(alignment: .leading, spacing: FacioLayout.space4) {
                HStack {
                    Text(timesheet.periodLabel(for: lang))
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    if brut > 0 {
                        Text(privacy.formatNumber(brut, lang: numberFormat))
                            .font(FacioFont.rowValue)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: FacioLayout.space8) {
                    Text(timesheet.clientDisplayName.isEmpty ? L10n.noClient(lang) : timesheet.clientDisplayName)
                        .font(FacioFont.caption)
                        .foregroundStyle(timesheet.clientDisplayName.isEmpty ? .tertiary : .secondary)
                        .lineLimit(1)
                    Text("\(heuresMois.formatted2Decimals(for: numberFormat))h")
                        .font(FacioFont.metaValue)
                        .foregroundStyle(.secondary)
                    if heuresSup > 0 {
                        Text(L10n.overtimeHoursShort(lang, value: heuresSup.formatted2Decimals(for: numberFormat)))
                            .font(FacioFont.caption)
                            .foregroundStyle(Color.intentWarning)
                    }
                    if timesheet.hasGeneratedInvoice {
                        Text(L10n.invoiced(lang))
                            .font(FacioFont.caption)
                            .foregroundStyle(Color.intentSuccess)
                    }
                }
            }
        }
        .frame(minHeight: 44)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
