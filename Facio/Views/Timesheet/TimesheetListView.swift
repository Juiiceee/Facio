import SwiftUI

struct TimesheetListView: View {
    @Binding var selectedTimesheetId: UUID?
    @Environment(DataStore.self) private var dataStore
    @State private var showNewPeriod = false
    @State private var selectedMois: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedAnnee: Int = Calendar.current.component(.year, from: Date())

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var timesheets: [TimesheetPeriod] {
        dataStore.timesheets.sorted { ($0.annee, $0.mois) > ($1.annee, $1.mois) }
    }

    private var moisLabels: [String] {
        let f = DateFormatter()
        f.locale = Locale(identifier: lang == .fr ? "fr_FR" : "en_US")
        return f.monthSymbols.map { $0.capitalized }
    }

    /// Verifie si une periode existe deja pour ce mois/annee
    private func periodeExiste(mois: Int, annee: Int) -> Bool {
        dataStore.timesheets.contains { $0.mois == mois && $0.annee == annee }
    }

    var body: some View {
        List(selection: $selectedTimesheetId) {
            ForEach(timesheets) { ts in
                TimesheetRowView(timesheet: ts, lang: lang, adjacentHours: dataStore.adjacentHours(for: ts))
                    .tag(ts.id)
                    .contextMenu {
                        Button {
                            genererFacture(ts)
                        } label: {
                            Label(L10n.generateInvoice(lang), systemImage: "doc.text")
                        }
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
                    showNewPeriod = true
                } label: {
                    Label(L10n.newPeriod(lang), systemImage: "plus")
                }
                .popover(isPresented: $showNewPeriod) {
                    newPeriodPopover
                }
            }
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

            if periodeExiste(mois: selectedMois, annee: selectedAnnee) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(L10n.periodExists(lang))
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
                    creerPeriode(mois: selectedMois, annee: selectedAnnee)
                    showNewPeriod = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(periodeExiste(mois: selectedMois, annee: selectedAnnee))
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    private func creerPeriode(mois: Int, annee: Int) {
        let ts = TimesheetPeriod(mois: mois, annee: annee)

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

    private func genererFacture(_ ts: TimesheetPeriod) {
        let adj = dataStore.adjacentHours(for: ts)
        let heuresNorm = ts.totalHeuresNormalesCrossPeriod(adjacentHours: adj)
        let heuresSup = ts.totalHeuresSupCrossPeriod(adjacentHours: adj)

        let number = DocumentNumberService.nextNumber(
            type: .facture,
            existingDocuments: dataStore.documents,
            language: lang
        )
        let doc = Document(
            type: .facture,
            number: number,
            dateCreation: Date(),
            currency: dataStore.companyInfo.deviseParDefaut,
            blockchain: dataStore.companyInfo.blockchainParDefaut
        )

        if heuresNorm > 0 {
            doc.lignes.append(LineItem(
                designation: L10n.workHours(lang),
                quantite: heuresNorm,
                prixUnitaire: ts.tauxNormal,
                tauxTVA: dataStore.companyInfo.tauxTVAParDefaut,
                ordre: 0
            ))
        }

        if heuresSup > 0 {
            doc.lignes.append(LineItem(
                designation: L10n.overtimeLabel(lang),
                quantite: heuresSup,
                prixUnitaire: ts.tauxSupplementaire,
                tauxTVA: dataStore.companyInfo.tauxTVAParDefaut,
                ordre: 1
            ))
        }

        dataStore.addDocument(doc)
    }
}

// MARK: - Row

private struct TimesheetRowView: View {
    let timesheet: TimesheetPeriod
    let lang: AppLanguage
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
                    Text(brut.formatted2Decimals)
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                Text("\(heuresMois.formatted2Decimals)h")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                if heuresSup > 0 {
                    Text("+\(heuresSup.formatted2Decimals)h sup")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .frame(minHeight: 44)
    }
}
