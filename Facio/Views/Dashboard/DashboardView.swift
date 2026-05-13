import SwiftUI

struct DashboardView: View {
    var onSelectDocument: (Document) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }
    private var accountingCurrency: CurrencyType { dataStore.companyInfo.deviseComptable }

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
    private var caMoisEnCours: AccountingRevenueSummary {
        let calendar = Calendar.current
        let now = Date()
        let documents = facturesPayees
            .filter { calendar.isDate($0.dateCreation, equalTo: now, toGranularity: .month) }
        return AccountingRevenueService.summary(
            for: documents,
            referenceCurrency: accountingCurrency
        )
    }

    // CA de l'annee en cours
    private var caAnneeEnCours: AccountingRevenueSummary {
        let calendar = Calendar.current
        let now = Date()
        let documents = facturesPayees
            .filter { calendar.isDate($0.dateCreation, equalTo: now, toGranularity: .year) }
        return AccountingRevenueService.summary(
            for: documents,
            referenceCurrency: accountingCurrency
        )
    }

    // Montant en attente
    private var montantEnAttente: AccountingRevenueSummary {
        AccountingRevenueService.summary(
            for: facturesEnAttente,
            referenceCurrency: accountingCurrency
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Cartes statistiques — adaptive columns
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 180, maximum: 300))
                ], spacing: 16) {
                    StatCard(
                        title: L10n.revenueThisMonth(lang),
                        value: accountingCurrency.formatAccounting(caMoisEnCours.total, lang: numberFormat),
                        subtitle: missingConversionSubtitle(caMoisEnCours),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    )
                    StatCard(
                        title: L10n.revenueThisYear(lang),
                        value: accountingCurrency.formatAccounting(caAnneeEnCours.total, lang: numberFormat),
                        subtitle: missingConversionSubtitle(caAnneeEnCours),
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                    StatCard(
                        title: L10n.pending(lang),
                        value: accountingCurrency.formatAccounting(montantEnAttente.total, lang: numberFormat),
                        subtitle: pendingSubtitle,
                        icon: "clock.fill",
                        color: .orange
                    )
                    StatCard(
                        title: L10n.quotesInProgress(lang),
                        value: "\(devis.filter { $0.status == .envoyee }.count)",
                        icon: "doc.text",
                        color: .purple
                    )
                }

                Divider()

                // Dernieres factures
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(L10n.latestInvoices(lang), systemImage: "doc.text")
                            .font(.headline)

                        if factures.isEmpty {
                            Text(L10n.noInvoicesYet(lang))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(factures.prefix(5)) { doc in
                                Button {
                                    onSelectDocument(doc)
                                } label: {
                                    documentRow(doc)
                                }
                                .buttonStyle(.plain)
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
                        Label(L10n.latestQuotes(lang), systemImage: "doc.text.magnifyingglass")
                            .font(.headline)

                        if devis.isEmpty {
                            Text(L10n.noQuotesYet(lang))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(devis.prefix(5)) { doc in
                                Button {
                                    onSelectDocument(doc)
                                } label: {
                                    documentRow(doc)
                                }
                                .buttonStyle(.plain)
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
        .navigationTitle(L10n.dashboard(lang))
    }

    private var pendingSubtitle: String {
        if montantEnAttente.missingConversionCount > 0 {
            return "\(L10n.pendingInvoices(lang, count: facturesEnAttente.count)) - \(L10n.missingConversions(lang, count: montantEnAttente.missingConversionCount))"
        }
        return L10n.pendingInvoices(lang, count: facturesEnAttente.count)
    }

    private func missingConversionSubtitle(_ summary: AccountingRevenueSummary) -> String? {
        guard summary.missingConversionCount > 0 else { return nil }
        return L10n.missingConversions(lang, count: summary.missingConversionCount)
    }

    private func documentRow(_ doc: Document) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(doc.number)
                    .fontWeight(.medium)
                Text(doc.clientNom)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(doc.currency.formatAccounting(doc.totalTTC, lang: numberFormat))
                .font(.body.monospacedDigit())
                .fontWeight(.medium)
            StatusBadge(status: doc.status, isOverdue: doc.isOverdue)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
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
