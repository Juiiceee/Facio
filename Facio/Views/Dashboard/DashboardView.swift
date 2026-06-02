import SwiftUI

struct DashboardView: View {
    var onSelectDocument: (Document) -> Void = { _ in }
    var onSelectTimesheet: (TimesheetPeriod) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var dateFormat: AppLanguage { dataStore.companyInfo.formatDate }
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

    private var overdueInvoices: [Document] {
        factures.filter(\.isOverdue)
    }

    private var awaitingPaymentInvoices: [Document] {
        facturesEnAttente.filter { !$0.isOverdue }
    }

    private var quotesToFollowUp: [Document] {
        devis.filter { $0.status == .envoyee }
    }

    private var missingConversionInvoices: [Document] {
        factures.filter {
            $0.needsAccountingConversion(referenceCurrency: accountingCurrency)
                && $0.accountingTotal(referenceCurrency: accountingCurrency) == nil
        }
    }

    private var uninvoicedTimesheets: [TimesheetPeriod] {
        dataStore.timesheets
            .filter { dataStore.canGenerateInvoice(for: $0) && !$0.hasGeneratedInvoice }
            .sorted { $0.activeEndDateString > $1.activeEndDateString }
    }

    private var hasFocusItems: Bool {
        !overdueInvoices.isEmpty
            || !awaitingPaymentInvoices.isEmpty
            || !quotesToFollowUp.isEmpty
            || !missingConversionInvoices.isEmpty
            || !uninvoicedTimesheets.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FacioLayout.sectionSpacing) {
                dashboardHeader

                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 180, maximum: 300))
                ], spacing: FacioLayout.space16) {
                    MetricTile(
                        title: L10n.revenueThisMonth(lang),
                        value: accountingCurrency.formatAccounting(caMoisEnCours.total, lang: numberFormat),
                        subtitle: missingConversionSubtitle(caMoisEnCours),
                        systemImage: "chart.line.uptrend.xyaxis",
                        color: .appRevenue
                    )
                    MetricTile(
                        title: L10n.revenueThisYear(lang),
                        value: accountingCurrency.formatAccounting(caAnneeEnCours.total, lang: numberFormat),
                        subtitle: missingConversionSubtitle(caAnneeEnCours),
                        systemImage: "chart.bar.fill",
                        color: .appRevenue
                    )
                    MetricTile(
                        title: L10n.pending(lang),
                        value: accountingCurrency.formatAccounting(montantEnAttente.total, lang: numberFormat),
                        subtitle: pendingSubtitle,
                        systemImage: "clock.fill",
                        color: .appPending
                    )
                    MetricTile(
                        title: L10n.quotesInProgress(lang),
                        value: "\(devis.filter { $0.status == .envoyee }.count)",
                        systemImage: "doc.text",
                        color: .appQuote
                    )
                }

                focusSection
                recentSection
            }
            .padding(FacioLayout.screenPadding)
        }
    }

    private var dashboardHeader: some View {
        HStack(alignment: .top, spacing: FacioLayout.space16) {
            VStack(alignment: .leading, spacing: FacioLayout.space4) {
                Text(L10n.dashboard(lang))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(L10n.dashboardSubtitle(lang))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: FacioLayout.space8) {
                FacioButton(L10n.quickCreateInvoice(lang), systemImage: "doc.badge.plus", role: .primary) {
                    onSelectDocument(dataStore.createDocument(type: .facture))
                }
                FacioButton(L10n.quickCreateQuote(lang), systemImage: "doc.text", role: .secondary) {
                    onSelectDocument(dataStore.createDocument(type: .devis))
                }
            }
        }
    }

    private var focusSection: some View {
        SectionPanel(L10n.todayFocus(lang), systemImage: "target") {
            if hasFocusItems {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    documentGroup(title: L10n.overdueInvoices(lang), icon: "exclamationmark.triangle.fill", tone: .danger, documents: overdueInvoices)
                    documentGroup(title: L10n.awaitingPayment(lang), icon: "clock.fill", tone: .warning, documents: awaitingPaymentInvoices)
                    documentGroup(title: L10n.quotesToFollowUp(lang), icon: "paperplane.fill", tone: .info, documents: quotesToFollowUp)
                    documentGroup(title: L10n.missingAccountingConversions(lang), icon: "arrow.triangle.2.circlepath", tone: .warning, documents: missingConversionInvoices)
                    timesheetGroup(title: L10n.uninvoicedPeriods(lang), icon: "calendar.badge.clock", tone: .success, timesheets: uninvoicedTimesheets)
                }
            } else {
                FacioEmptyState(
                    title: L10n.nothingToHandle(lang),
                    systemImage: "checkmark.circle",
                    message: L10n.nothingToHandleHint(lang)
                )
                .frame(maxWidth: .infinity, minHeight: 160)
            }
        }
    }

    private var recentSection: some View {
        SectionPanel(L10n.recentWork(lang), systemImage: "clock.arrow.circlepath") {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 320, maximum: 520), alignment: .top)
            ], spacing: FacioLayout.space16) {
                recentDocumentList(title: L10n.latestInvoices(lang), empty: L10n.noInvoicesYet(lang), documents: Array(factures.prefix(5)))
                recentDocumentList(title: L10n.latestQuotes(lang), empty: L10n.noQuotesYet(lang), documents: Array(devis.prefix(5)))
            }
        }
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

    @ViewBuilder
    private func documentGroup(title: String, icon: String, tone: InlineTone, documents: [Document]) -> some View {
        if !documents.isEmpty {
            VStack(alignment: .leading, spacing: FacioLayout.space8) {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(tone.color)
                ForEach(documents.prefix(4)) { doc in
                    Button {
                        onSelectDocument(doc)
                    } label: {
                        documentRow(doc)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.openDocument(lang))
                }
                if documents.count > 4 {
                    overflowRow(count: documents.count - 4)
                }
            }
        }
    }

    @ViewBuilder
    private func timesheetGroup(title: String, icon: String, tone: InlineTone, timesheets: [TimesheetPeriod]) -> some View {
        if !timesheets.isEmpty {
            VStack(alignment: .leading, spacing: FacioLayout.space8) {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(tone.color)
                ForEach(timesheets.prefix(4)) { timesheet in
                    Button {
                        onSelectTimesheet(timesheet)
                    } label: {
                        timesheetRow(timesheet)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.openPeriod(lang))
                }
                if timesheets.count > 4 {
                    overflowRow(count: timesheets.count - 4)
                }
            }
        }
    }

    private func recentDocumentList(title: String, empty: String, documents: [Document]) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space10) {
            Text(title)
                .font(.headline)
            if documents.isEmpty {
                FacioEmptyState(title: empty, systemImage: "tray")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ForEach(documents) { doc in
                    Button {
                        onSelectDocument(doc)
                    } label: {
                        documentRow(doc)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func documentRow(_ doc: Document) -> some View {
        FacioListRow(tone: doc.isOverdue ? Color.intentDanger : Color.statusColor(for: doc.status)) {
            VStack(alignment: .leading) {
                Text(doc.number)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(doc.clientNom)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(documentRowDetail(doc))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: FacioLayout.space10)

            Text(doc.currency.formatAccounting(doc.totalTTC, lang: numberFormat))
                .font(.body.monospacedDigit())
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(minWidth: 92, maxWidth: 130, alignment: .trailing)
            StatusBadge(status: doc.status, isOverdue: doc.isOverdue)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timesheetRow(_ timesheet: TimesheetPeriod) -> some View {
        let hours = timesheet.totalHeuresDuMois().formatted2Decimals(for: numberFormat)
        return FacioListRow(tone: Color.intentSuccess) {
            VStack(alignment: .leading, spacing: FacioLayout.space2) {
                Text(timesheet.periodLabel(for: lang))
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(timesheet.clientDisplayName.isEmpty ? L10n.noClient(lang) : timesheet.clientDisplayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: FacioLayout.space10)

            Text("\(hours)h")
                .font(.body.monospacedDigit())
                .fontWeight(.medium)
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func overflowRow(count: Int) -> some View {
        Text(L10n.moreItems(lang, count: count))
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, FacioLayout.space10)
            .padding(.vertical, FacioLayout.space4)
    }

    private func documentRowDetail(_ doc: Document) -> String {
        if doc.type == .facture && (doc.status == .envoyee || doc.isOverdue) {
            return "\(L10n.dueDateLabel(lang)): \(doc.dateEcheance.formattedDate(for: dateFormat))"
        }
        return doc.dateCreation.formattedDate(for: dateFormat)
    }
}

