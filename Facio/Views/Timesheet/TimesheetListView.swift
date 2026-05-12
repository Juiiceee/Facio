import SwiftUI

struct TimesheetListView: View {
    @Binding var selectedTimesheetId: UUID?
    @Environment(DataStore.self) private var dataStore
    @State private var showNewPeriod = false
    @State private var showClientPicker = false
    @State private var showInvoiceDetailOptions = false
    @State private var selectedMois: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedAnnee: Int = Calendar.current.component(.year, from: Date())
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

    private var moisLabels: [String] {
        let f = DateFormatter()
        f.locale = Locale(identifier: lang == .fr ? "fr_FR" : "en_US")
        return f.monthSymbols.map { $0.capitalized }
    }

    /// Verifie si une periode existe deja pour ce mois/annee
    private func periodeExiste(mois: Int, annee: Int, clientId: UUID?) -> Bool {
        dataStore.timesheetExists(mois: mois, annee: annee, clientId: clientId)
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
                        Button {
                            presentInvoiceOptions(for: ts)
                        } label: {
                            Label(L10n.generateInvoice(lang), systemImage: "doc.text")
                        }
                        .disabled(!dataStore.canGenerateInvoice(for: ts))
                        Divider()
                        Button(role: .destructive) {
                            if selectedTimesheetId == ts.id { selectedTimesheetId = nil }
                            dataStore.deleteTimesheet(ts)
                        } label: {
                            Label(L10n.delete(lang), systemImage: "trash")
                        }
                    }
            }
        }
        .id(timesheets.count)
        .navigationTitle(L10n.sidebarTimeTracking(lang))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Reset au mois courant a chaque ouverture
                    let cal = Calendar.current
                    let now = Date()
                    selectedMois = cal.component(.month, from: now)
                    selectedAnnee = cal.component(.year, from: now)
                    selectedClientId = nil
                    showNewPeriod = true
                } label: {
                    Label(L10n.newPeriod(lang), systemImage: "plus")
                }
                .popover(isPresented: $showNewPeriod) {
                    newPeriodPopover
                }
            }
        }
        .sheet(isPresented: $showClientPicker) {
            ClientPickerSheet(clients: dataStore.clients) { client in
                selectedClientId = client.id
                showClientPicker = false
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
            Button(L10n.cancel(lang), role: .cancel) {}
        } message: { _ in
            Text(L10n.chooseInvoiceDetail(lang))
        }
        .overlay {
            if timesheets.isEmpty {
                ContentUnavailableView(
                    L10n.noPeriod(lang),
                    systemImage: "clock",
                    description: Text(L10n.clickToCreatePeriod(lang))
                )
            }
        }
    }

    // MARK: - Popover nouvelle periode

    private var newPeriodPopover: some View {
        VStack(spacing: 16) {
            Text(L10n.newPeriod(lang))
                .font(.headline)

            HStack(spacing: 12) {
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

            HStack(spacing: 12) {
                Text(L10n.selectClientForPeriod(lang))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showClientPicker = true
                } label: {
                    Label(
                        selectedClient?.displayName ?? L10n.selectClientForPeriod(lang),
                        systemImage: "person.crop.circle"
                    )
                }
            }

            if selectedClientId == nil {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .foregroundStyle(.orange)
                    Text(L10n.clientRequired(lang))
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            } else if periodeExiste(mois: selectedMois, annee: selectedAnnee, clientId: selectedClientId) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(L10n.periodExistsForClient(lang))
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            HStack(spacing: 12) {
                Button(L10n.cancel(lang)) {
                    showNewPeriod = false
                }
                .buttonStyle(.bordered)

                Button(L10n.create(lang)) {
                    creerPeriode(mois: selectedMois, annee: selectedAnnee, client: selectedClient)
                    showNewPeriod = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedClient == nil || periodeExiste(mois: selectedMois, annee: selectedAnnee, clientId: selectedClientId))
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private func creerPeriode(mois: Int, annee: Int, client: ClientInfo?) {
        guard let client else { return }
        let ts = TimesheetPeriod(mois: mois, annee: annee, client: client)

        // Copier les taux depuis la derniere periode
        if let last = timesheets.first {
            ts.tauxNormal = last.tauxNormal
            ts.tauxSupplementaire = last.tauxSupplementaire
            ts.coefficientNet = last.coefficientNet
            ts.seuilHebdo = last.seuilHebdo
        }

        dataStore.addTimesheet(ts)
        dataStore.syncSharedWeeks(for: ts)
        selectedTimesheetId = ts.id
    }

    private func presentInvoiceOptions(for ts: TimesheetPeriod) {
        pendingInvoiceTimesheet = ts
        showInvoiceDetailOptions = true
    }

    private func genererFacture(_ ts: TimesheetPeriod, detailMode: TimesheetInvoiceDetailMode) {
        _ = dataStore.generateInvoice(from: ts, detailMode: detailMode)
    }
}

// MARK: - Row

private struct TimesheetRowView: View {
    let timesheet: TimesheetPeriod
    let lang: AppLanguage
    let numberFormat: AppLanguage
    let adjacentHours: [String: Decimal]

    var body: some View {
        let heuresMois = timesheet.totalHeuresDuMois()
        let heuresSup = timesheet.totalHeuresSupCrossPeriod(adjacentHours: adjacentHours)
        let brut = timesheet.totalBrutCrossPeriod(adjacentHours: adjacentHours)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(timesheet.moisLabel(for: lang))
                    .font(.headline)
                Spacer()
                if brut > 0 {
                    Text(brut.formatted2Decimals(for: numberFormat))
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                Text(timesheet.clientDisplayName.isEmpty ? L10n.noClient(lang) : timesheet.clientDisplayName)
                    .font(.caption)
                    .foregroundStyle(timesheet.clientDisplayName.isEmpty ? .tertiary : .secondary)
                    .lineLimit(1)
                Text("\(heuresMois.formatted2Decimals(for: numberFormat))h")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                if heuresSup > 0 {
                    Text(L10n.overtimeHoursShort(lang, value: heuresSup.formatted2Decimals(for: numberFormat)))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                if timesheet.hasGeneratedInvoice {
                    Text(L10n.invoiced(lang))
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
        .frame(minHeight: 44)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
