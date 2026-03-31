import SwiftUI

struct TimesheetListView: View {
    @Binding var selectedTimesheetId: UUID?
    @Environment(DataStore.self) private var dataStore
    @State private var showNewPeriod = false
    @State private var selectedMois: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedAnnee: Int = Calendar.current.component(.year, from: Date())

    private var timesheets: [TimesheetPeriod] {
        dataStore.timesheets.sorted { ($0.annee, $0.mois) > ($1.annee, $1.mois) }
    }

    private static let moisLabels: [String] = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        return f.monthSymbols.map { $0.capitalized }
    }()

    /// Verifie si une periode existe deja pour ce mois/annee
    private func periodeExiste(mois: Int, annee: Int) -> Bool {
        dataStore.timesheets.contains { $0.mois == mois && $0.annee == annee }
    }

    var body: some View {
        List(timesheets, selection: $selectedTimesheetId) { ts in
            TimesheetRowView(timesheet: ts)
                .tag(ts.id)
                .contextMenu {
                    Button {
                        genererFacture(ts)
                    } label: {
                        Label("Generer une facture", systemImage: "doc.text")
                    }
                    Divider()
                    Button(role: .destructive) {
                        if selectedTimesheetId == ts.id { selectedTimesheetId = nil }
                        dataStore.deleteTimesheet(ts)
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                }
        }
        .navigationTitle("Suivi des heures")
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
                    Label("Nouvelle periode", systemImage: "plus")
                }
                .popover(isPresented: $showNewPeriod) {
                    newPeriodPopover
                }
            }
        }
        .overlay {
            if timesheets.isEmpty {
                ContentUnavailableView(
                    "Aucune periode",
                    systemImage: "clock",
                    description: Text("Cliquez sur + pour creer une nouvelle periode de suivi.")
                )
            }
        }
    }

    // MARK: - Popover nouvelle periode

    private var newPeriodPopover: some View {
        VStack(spacing: 16) {
            Text("Nouvelle periode")
                .font(.headline)

            HStack(spacing: 12) {
                Picker("Mois", selection: $selectedMois) {
                    ForEach(1...12, id: \.self) { m in
                        Text(Self.moisLabels[m - 1]).tag(m)
                    }
                }
                .labelsHidden()
                .frame(width: 140)

                Picker("Annee", selection: $selectedAnnee) {
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
                    Text("Cette periode existe deja")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            HStack(spacing: 12) {
                Button("Annuler") {
                    showNewPeriod = false
                }
                .buttonStyle(.bordered)

                Button("Creer") {
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
        selectedTimesheetId = ts.id
    }

    private func genererFacture(_ ts: TimesheetPeriod) {
        let number = DocumentNumberService.nextNumber(
            type: .facture,
            existingDocuments: dataStore.documents
        )
        let doc = Document(
            type: .facture,
            number: number,
            dateCreation: Date(),
            currency: dataStore.companyInfo.deviseParDefaut,
            blockchain: dataStore.companyInfo.blockchainParDefaut
        )

        if ts.totalHeuresNormales > 0 {
            doc.lignes.append(LineItem(
                designation: "Heures de travail",
                quantite: ts.totalHeuresNormales,
                prixUnitaire: ts.tauxNormal,
                tauxTVA: dataStore.companyInfo.tauxTVAParDefaut,
                ordre: 0
            ))
        }

        if ts.totalHeuresSupplementaires > 0 {
            doc.lignes.append(LineItem(
                designation: "Heures supplementaires",
                quantite: ts.totalHeuresSupplementaires,
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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timesheet.moisLabel)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text("\(timesheet.totalHeures.formatted2Decimals)h")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if timesheet.totalHeuresSupplementaires > 0 {
                        Text("+\(timesheet.totalHeuresSupplementaires.formatted2Decimals)h sup")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            Spacer()
            Text(timesheet.totalBrut.formatted2Decimals)
                .font(.body.monospacedDigit())
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}
