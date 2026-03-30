import SwiftUI

struct TimesheetEditorView: View {
    let timesheet: TimesheetPeriod
    @Environment(DataStore.self) private var dataStore

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
        .navigationTitle(timesheet.moisLabel)
    }

    // MARK: - Resume

    private var resumeSection: some View {
        GroupBox("Resume — \(timesheet.moisLabel)") {
            HStack(spacing: 0) {
                resumeCard(title: "Total heures", value: "\(timesheet.totalHeures.formatted2Decimals)h", color: .primary)
                Divider().frame(height: 50)
                resumeCard(title: "Normales", value: "\(timesheet.totalHeuresNormales.formatted2Decimals)h", color: .blue)
                Divider().frame(height: 50)
                resumeCard(title: "Supplementaires", value: "\(timesheet.totalHeuresSupplementaires.formatted2Decimals)h",
                           color: timesheet.totalHeuresSupplementaires > 0 ? .orange : .secondary)
                Divider().frame(height: 50)
                resumeCard(title: "Cout normal", value: timesheet.coutNormal.formatted2Decimals, color: .secondary)
                Divider().frame(height: 50)
                resumeCard(title: "Cout sup.", value: timesheet.coutSupplementaire.formatted2Decimals, color: .secondary)
                Divider().frame(height: 50)
                resumeCard(title: "Total brut", value: timesheet.totalBrut.formatted2Decimals, color: .green)
                Divider().frame(height: 50)
                resumeCard(title: "Total net", value: timesheet.totalNet.formatted2Decimals, color: .green)
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
    }

    // MARK: - Semaine

    private func weekSection(weekIndex: Int, week: TimesheetWeek) -> some View {
        let seuil = timesheet.seuilHebdo

        return GroupBox {
            VStack(spacing: 10) {
                // En-tete
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Semaine \(week.numero)")
                            .font(.headline)
                        Text(week.label)
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
                    }
                }

                Divider()

                // Grille des jours
                HStack(spacing: 6) {
                    ForEach(Array(week.jours.enumerated()), id: \.offset) { dayIndex, jour in
                        let estDansMois = jour.mois == timesheet.mois
                        VStack(spacing: 4) {
                            // Nom du jour
                            Text(jour.jourSemaine.shortLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            // Date (numero du jour)
                            Text("\(jour.jourDuMois)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(estDansMois ? .primary : .tertiary)
                            // Champ heures (6.30 = 6h30 → 6.5)
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
                            .frame(width: 58)
                            .opacity(estDansMois ? 1.0 : 0.5)
                        }
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Parametres

    private var parametresSection: some View {
        GroupBox("Parametres de calcul") {
            HStack(spacing: 24) {
                LabeledContent("Seuil hebdo (h)") {
                    DecimalField(placeholder: "35", value: Binding(
                        get: { timesheet.seuilHebdo },
                        set: { timesheet.seuilHebdo = $0; dataStore.save() }
                    ))
                    .frame(width: 70)
                }
                LabeledContent("Taux normal") {
                    DecimalField(placeholder: "26,39", value: Binding(
                        get: { timesheet.tauxNormal },
                        set: { timesheet.tauxNormal = $0; dataStore.save() }
                    ))
                    .frame(width: 80)
                }
                LabeledContent("Taux sup.") {
                    DecimalField(placeholder: "39,59", value: Binding(
                        get: { timesheet.tauxSupplementaire },
                        set: { timesheet.tauxSupplementaire = $0; dataStore.save() }
                    ))
                    .frame(width: 80)
                }
                LabeledContent("Coeff. net") {
                    DecimalField(placeholder: "0,756", value: Binding(
                        get: { timesheet.coefficientNet },
                        set: { timesheet.coefficientNet = $0; dataStore.save() }
                    ))
                    .frame(width: 80)
                }
            }
            .padding(8)
        }
    }
}
