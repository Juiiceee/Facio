import SwiftUI

struct TimesheetEditorView: View {
    let timesheet: TimesheetPeriod
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                resumeSection

                ForEach(Array(timesheet.semaines.enumerated()), id: \.element.id) { weekIndex, week in
                    weekSection(weekIndex: weekIndex, week: week)
                }

                parametresSection
            }
            .padding(24)
        }
        .navigationTitle(timesheet.moisLabel(for: lang))
    }

    // MARK: - Resume

    private var resumeSection: some View {
        GroupBox("\(L10n.summary(lang)) — \(timesheet.moisLabel(for: lang))") {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 160))
            ], spacing: 12) {
                resumeCard(title: L10n.totalHours(lang), value: "\(timesheet.totalHeures.formatted2Decimals)h", color: .primary)
                resumeCard(title: L10n.normalHours(lang), value: "\(timesheet.totalHeuresNormales.formatted2Decimals)h", color: .blue)
                resumeCard(title: L10n.overtimeHours(lang), value: "\(timesheet.totalHeuresSupplementaires.formatted2Decimals)h",
                           color: timesheet.totalHeuresSupplementaires > 0 ? .orange : .secondary)
                resumeCard(title: L10n.normalCost(lang), value: timesheet.coutNormal.formatted2Decimals, color: .secondary)
                resumeCard(title: L10n.overtimeCost(lang), value: timesheet.coutSupplementaire.formatted2Decimals, color: .secondary)
                resumeCard(title: L10n.grossTotal(lang), value: timesheet.totalBrut.formatted2Decimals, color: .green)
                resumeCard(title: L10n.netTotal(lang), value: timesheet.totalNet.formatted2Decimals, color: .green)
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

    // MARK: - Semaine

    private func weekSection(weekIndex: Int, week: TimesheetWeek) -> some View {
        let seuil = timesheet.seuilHebdo

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
                        Label("\(week.totalHeures.formatted2Decimals)h", systemImage: "clock")
                            .font(.subheadline.monospacedDigit())
                            .fontWeight(.medium)
                        Text("N: \(week.heuresNormales(seuil: seuil).formatted2Decimals)h")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.blue)
                        if week.heuresSupplementaires(seuil: seuil) > 0 {
                            Text("S: +\(week.heuresSupplementaires(seuil: seuil).formatted2Decimals)h")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.orange)
                                .fontWeight(.medium)
                        }
                        Divider().frame(height: 14)
                        let coutSemaine = week.heuresNormales(seuil: seuil) * timesheet.tauxNormal
                            + week.heuresSupplementaires(seuil: seuil) * timesheet.tauxSupplementaire
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
                                placeholder: "0",
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
                                        dataStore.save()
                                    }
                                )
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
                    set: { timesheet.seuilHebdo = $0; dataStore.save() }
                ))
                settingsField(L10n.normalRate(lang), placeholder: "26,39", value: Binding(
                    get: { timesheet.tauxNormal },
                    set: { timesheet.tauxNormal = $0; dataStore.save() }
                ))
                settingsField(L10n.overtimeRate(lang), placeholder: "39,59", value: Binding(
                    get: { timesheet.tauxSupplementaire },
                    set: { timesheet.tauxSupplementaire = $0; dataStore.save() }
                ))
                settingsField(L10n.netCoeff(lang), placeholder: "0,756", value: Binding(
                    get: { timesheet.coefficientNet },
                    set: { timesheet.coefficientNet = $0; dataStore.save() }
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
}
