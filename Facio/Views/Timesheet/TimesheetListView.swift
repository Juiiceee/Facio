import SwiftUI

struct TimesheetListView: View {
    @Binding var selectedTimesheetId: UUID?
    @Environment(DataStore.self) private var dataStore

    private var timesheets: [TimesheetPeriod] {
        dataStore.timesheets.sorted { ($0.annee, $0.mois) > ($1.annee, $1.mois) }
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
                    creerPeriode()
                } label: {
                    Label("Nouvelle periode", systemImage: "plus")
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

    private func creerPeriode() {
        let cal = Calendar.current
        let now = Date()
        let mois = cal.component(.month, from: now)
        let annee = cal.component(.year, from: now)

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
