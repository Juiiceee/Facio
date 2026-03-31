import SwiftUI

struct DashboardView: View {
    @Environment(DataStore.self) private var dataStore

    private var allDocuments: [Document] {
        dataStore.documents.sorted { $0.dateCreation > $1.dateCreation }
    }

    private var factures: [Document] {
        allDocuments.filter { $0.type == .facture }
    }

    private var devis: [Document] {
        allDocuments.filter { $0.type == .devis }
    }

    private var facturesPayees: [Document] {
        factures.filter { $0.status == .payee }
    }

    private var facturesEnAttente: [Document] {
        factures.filter { $0.status == .envoyee }
    }

    // CA du mois en cours
    private var caMoisEnCours: Decimal {
        let calendar = Calendar.current
        let now = Date()
        return facturesPayees
            .filter { calendar.isDate($0.dateCreation, equalTo: now, toGranularity: .month) }
            .reduce(Decimal.zero) { $0 + $1.totalTTC }
    }

    // CA de l'annee en cours
    private var caAnneeEnCours: Decimal {
        let calendar = Calendar.current
        let now = Date()
        return facturesPayees
            .filter { calendar.isDate($0.dateCreation, equalTo: now, toGranularity: .year) }
            .reduce(Decimal.zero) { $0 + $1.totalTTC }
    }

    // Montant en attente
    private var montantEnAttente: Decimal {
        facturesEnAttente.reduce(Decimal.zero) { $0 + $1.totalTTC }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Cartes statistiques — adaptive columns
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 180, maximum: 300))
                ], spacing: 16) {
                    StatCard(
                        title: "CA ce mois",
                        value: caMoisEnCours.formatted2Decimals,
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    )
                    StatCard(
                        title: "CA cette annee",
                        value: caAnneeEnCours.formatted2Decimals,
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                    StatCard(
                        title: "En attente",
                        value: montantEnAttente.formatted2Decimals,
                        subtitle: "\(facturesEnAttente.count) facture(s)",
                        icon: "clock.fill",
                        color: .orange
                    )
                    StatCard(
                        title: "Devis en cours",
                        value: "\(devis.filter { $0.status == .envoyee }.count)",
                        icon: "doc.text",
                        color: .purple
                    )
                }

                Divider()

                // Dernieres factures
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Dernieres factures", systemImage: "doc.text")
                            .font(.headline)

                        if factures.isEmpty {
                            Text("Aucune facture pour le moment.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(factures.prefix(5)) { doc in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(doc.number)
                                            .fontWeight(.medium)
                                        Text(doc.clientNom)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(doc.totalFormatted)
                                        .font(.body.monospacedDigit())
                                        .fontWeight(.medium)
                                    StatusBadge(status: doc.status)
                                }
                                .padding(.vertical, 4)
                                if doc.id != factures.prefix(5).last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(8)
                }

                // Derniers devis
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Derniers devis", systemImage: "doc.text.magnifyingglass")
                            .font(.headline)

                        if devis.isEmpty {
                            Text("Aucun devis pour le moment.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(devis.prefix(5)) { doc in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(doc.number)
                                            .fontWeight(.medium)
                                        Text(doc.clientNom)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(doc.totalFormatted)
                                        .font(.body.monospacedDigit())
                                        .fontWeight(.medium)
                                    StatusBadge(status: doc.status)
                                }
                                .padding(.vertical, 4)
                                if doc.id != devis.prefix(5).last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(8)
                }
            }
            .padding(24)
        }
        .navigationTitle("Dashboard")
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
