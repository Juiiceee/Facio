import SwiftUI

struct TimesheetEditorView: View {
    let timesheet: TimesheetPeriod
    @Environment(DataStore.self) private var dataStore
    @State private var hourInputMode: TimesheetHourInputMode = .decimal
    @State private var showClientPicker = false
    @State private var showInvoiceDetailOptions = false

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    /// Heures des jours hors-mois depuis les périodes adjacentes
    private var adjHours: [String: Decimal] { dataStore.adjacentHours(for: timesheet) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                clientSection
                resumeSection
                hourInputModeControl

                ForEach(Array(timesheet.semaines.enumerated()), id: \.element.id) { weekIndex, week in
                    weekSection(weekIndex: weekIndex, week: week)
                }

                parametresSection
            }
            .padding(24)
        }
        .navigationTitle(timesheet.title(for: lang))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showInvoiceDetailOptions = true
                } label: {
                    Label(L10n.generateInvoice(lang), systemImage: "doc.text")
                }
                .disabled(!dataStore.canGenerateInvoice(for: timesheet))
            }
        }
        .sheet(isPresented: $showClientPicker) {
            ClientPickerSheet(clients: dataStore.clients) { client in
                guard !dataStore.timesheetExists(
                    mois: timesheet.mois,
                    annee: timesheet.annee,
                    clientId: client.id,
                    excluding: timesheet.id
                ) else { return }
                timesheet.applyClient(client)
                if let invoice = dataStore.existingInvoice(for: timesheet) {
                    timesheet.applyClient(to: invoice)
                    dataStore.documentUpdated(invoice)
                }
                dataStore.timesheetUpdated(timesheet, syncSharedWeeks: true)
                showClientPicker = false
            }
        }
        .confirmationDialog(
            L10n.invoiceDetailMode(lang),
            isPresented: $showInvoiceDetailOptions,
            titleVisibility: .visible
        ) {
            Button(TimesheetInvoiceDetailMode.summary.label(for: lang)) {
                genererFacture(detailMode: .summary)
            }
            Button(TimesheetInvoiceDetailMode.daily.label(for: lang)) {
                genererFacture(detailMode: .daily)
            }
            Button(L10n.cancel(lang), role: .cancel) {}
        } message: {
            Text(L10n.chooseInvoiceDetail(lang))
        }
    }

    // MARK: - Resume

    private var clientSection: some View {
        GroupBox(L10n.selectClientForPeriod(lang)) {
            HStack(spacing: 12) {
                Label(
                    timesheet.clientDisplayName.isEmpty ? L10n.noClient(lang) : timesheet.clientDisplayName,
                    systemImage: "person.crop.circle"
                )
                .foregroundStyle(timesheet.clientDisplayName.isEmpty ? .secondary : .primary)

                Spacer()

                if timesheet.hasGeneratedInvoice {
                    Text(L10n.invoiced(lang))
                        .foregroundStyle(.green)
                }

                Button {
                    showClientPicker = true
                } label: {
                    Label(
                        timesheet.hasClient ? L10n.changeClient(lang) : L10n.selectClientForPeriod(lang),
                        systemImage: "person.crop.circle.badge.plus"
                    )
                }
            }
            .padding(8)
        }
    }

    private var resumeSection: some View {
        let adj = adjHours
        let heuresMois = timesheet.totalHeuresDuMois()
        let heuresSup = timesheet.totalHeuresSupCrossPeriod(adjacentHours: adj)
        let heuresNorm = heuresMois - heuresSup
        let coutNorm = heuresNorm * timesheet.tauxNormal
        let coutSup = heuresSup * timesheet.tauxSupplementaire
        let brut = coutNorm + coutSup
        let net = brut * timesheet.coefficientNet

        return GroupBox("\(L10n.summary(lang)) — \(timesheet.moisLabel(for: lang))") {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 160))
            ], spacing: 12) {
                resumeCard(title: L10n.totalHours(lang), value: "\(heuresMois.formatted2Decimals)h", color: .primary)
                resumeCard(title: L10n.normalHours(lang), value: "\(heuresNorm.formatted2Decimals)h", color: .blue)
                resumeCard(title: L10n.overtimeHours(lang), value: "\(heuresSup.formatted2Decimals)h",
                           color: heuresSup > 0 ? .orange : .secondary)
                resumeCard(title: L10n.normalCost(lang), value: coutNorm.formatted2Decimals, color: .secondary)
                resumeCard(title: L10n.overtimeCost(lang), value: coutSup.formatted2Decimals, color: .secondary)
                resumeCard(title: L10n.grossTotal(lang), value: brut.formatted2Decimals, color: .green)
                resumeCard(title: L10n.netTotal(lang), value: net.formatted2Decimals, color: .green)
            }
            .padding(8)
        }
    }

    private func resumeCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospacedDigit())
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var hourInputModeControl: some View {
        HStack(spacing: 12) {
            Label(L10n.hourInputMode(lang), systemImage: "clock.badge")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("", selection: $hourInputMode) {
                Text(L10n.hourInputDecimalMode(lang)).tag(TimesheetHourInputMode.decimal)
                Text(L10n.hourInputTimeMode(lang)).tag(TimesheetHourInputMode.time)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 220)
            .help(L10n.hourInputHelp(lang, mode: hourInputMode))

            Spacer()
        }
    }

    // MARK: - Semaine

    private func weekSection(weekIndex: Int, week: TimesheetWeek) -> some View {
        let seuil = timesheet.seuilHebdo
        let adj = adjHours

        // Heures du mois courant dans cette semaine
        let heuresMoisSemaine = week.jours.filter { $0.mois == timesheet.mois }.reduce(Decimal(0)) { $0 + $1.heures }
        let supSemaine = week.heuresSupPourMois(moisPeriode: timesheet.mois, seuil: seuil, adjacentHours: adj)
        let normSemaine = heuresMoisSemaine - supSemaine

        return GroupBox {
            VStack(spacing: 10) {
                // En-tete
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.week(lang, number: week.numero))
                            .font(.headline)
                        Text(week.label(for: lang))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 16) {
                        Label("\(heuresMoisSemaine.formatted2Decimals)h", systemImage: "clock")
                            .font(.subheadline.monospacedDigit())
                            .fontWeight(.medium)
                        Text(L10n.normalHoursShort(lang, value: normSemaine.formatted2Decimals))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.blue)
                        if supSemaine > 0 {
                            Text(L10n.overtimeHoursShort(lang, value: supSemaine.formatted2Decimals))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.orange)
                                .fontWeight(.medium)
                        }
                        Divider().frame(height: 14)
                        let coutSemaine = normSemaine * timesheet.tauxNormal
                            + supSemaine * timesheet.tauxSupplementaire
                        Text(coutSemaine.formatted2Decimals)
                            .font(.subheadline.monospacedDigit())
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }

                Divider()

                // Grille des jours
                HStack(spacing: 0) {
                    ForEach(Array(week.jours.enumerated()), id: \.offset) { dayIndex, jour in
                        let estDansMois = jour.mois == timesheet.mois
                        VStack(spacing: 4) {
                            Text(jour.jourSemaine.shortLabel(for: lang))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(jour.jourDuMois)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(estDansMois ? .primary : .tertiary)
                            TimeField(
                                placeholder: L10n.hourInputPlaceholder(lang, mode: hourInputMode),
                                value: Binding(
                                    get: {
                                        guard weekIndex < timesheet.semaines.count,
                                              dayIndex < timesheet.semaines[weekIndex].jours.count
                                        else { return 0 }
                                        return timesheet.semaines[weekIndex].jours[dayIndex].heures
                                    },
                                    set: { newVal in
                                        guard weekIndex < timesheet.semaines.count,
                                              dayIndex < timesheet.semaines[weekIndex].jours.count
                                        else { return }
                                        timesheet.semaines[weekIndex].jours[dayIndex].heures = newVal
                                        dataStore.timesheetUpdated(timesheet, syncSharedWeeks: true)
                                    }
                                ),
                                mode: hourInputMode,
                                lang: lang
                            )
                            .opacity(estDansMois ? 1.0 : 0.5)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Parametres

    private var parametresSection: some View {
        GroupBox(L10n.calculationParams(lang)) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150, maximum: 250))
            ], spacing: 12) {
                settingsField(L10n.weeklyThreshold(lang), placeholder: "35", value: Binding(
                    get: { timesheet.seuilHebdo },
                    set: { timesheet.seuilHebdo = $0; dataStore.timesheetUpdated(timesheet) }
                ))
                settingsField(L10n.normalRate(lang), placeholder: "26,39", value: Binding(
                    get: { timesheet.tauxNormal },
                    set: { timesheet.tauxNormal = $0; dataStore.timesheetUpdated(timesheet) }
                ))
                settingsField(L10n.overtimeRate(lang), placeholder: "39,59", value: Binding(
                    get: { timesheet.tauxSupplementaire },
                    set: { timesheet.tauxSupplementaire = $0; dataStore.timesheetUpdated(timesheet) }
                ))
                settingsField(L10n.netCoeff(lang), placeholder: "0,756", value: Binding(
                    get: { timesheet.coefficientNet },
                    set: { timesheet.coefficientNet = $0; dataStore.timesheetUpdated(timesheet) }
                ))
            }
            .padding(8)
        }
    }

    private func settingsField(_ label: String, placeholder: String, value: Binding<Decimal>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            DecimalField(placeholder: placeholder, value: value)
        }
    }

    private func genererFacture(detailMode: TimesheetInvoiceDetailMode) {
        _ = dataStore.generateInvoice(from: timesheet, detailMode: detailMode)
    }
}
