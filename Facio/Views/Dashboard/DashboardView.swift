import SwiftUI

struct DashboardView: View {
    var onSelectDocument: (Document) -> Void = { _ in }
    var onSelectTimesheet: (TimesheetPeriod) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore
    @Environment(PrivacyMode.self) private var privacy

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

    // Factures dont une part est encaissée (payées + partielles) : elles
    // alimentent le CA à hauteur des encaissements, chacun rattaché à sa date.
    private var facturesEncaissees: [Document] {
        factures.filter { $0.status == .payee || $0.status == .partiel }
    }

    private var facturesEnAttente: [Document] {
        factures.filter { $0.status == .envoyee }
    }

    // Factures avec un solde encore dû : envoyées + partielles dont il reste à
    // payer (une partielle intégralement reçue n'attend plus rien).
    private var outstandingInvoices: [Document] {
        factures.filter { $0.status == .envoyee || ($0.status == .partiel && $0.resteAPayer > 0) }
    }

    /// CA d'une période : on ventile chaque encaissement (total d'une facture
    /// payée, ou chaque versement d'une partielle) dans son propre mois/année.
    private func caSummary(toGranularity granularity: Calendar.Component) -> AccountingRevenueSummary {
        let calendar = Calendar.current
        let now = Date()
        var summary = AccountingRevenueSummary()
        for facture in facturesEncaissees {
            var missingConversion = false
            for event in facture.accountingCashEvents(referenceCurrency: accountingCurrency)
            where calendar.isDate(event.date, equalTo: now, toGranularity: granularity) {
                if let amount = event.amount {
                    summary.total += amount
                    summary.convertedCount += 1
                } else {
                    missingConversion = true
                }
            }
            if missingConversion { summary.missingConversionCount += 1 }
        }
        return summary
    }

    // CA du mois en cours
    private var caMoisEnCours: AccountingRevenueSummary { caSummary(toGranularity: .month) }

    // CA de l'annee en cours
    private var caAnneeEnCours: AccountingRevenueSummary { caSummary(toGranularity: .year) }

    // Montant en attente (solde restant dû, partielles incluses)
    private var montantEnAttente: AccountingRevenueSummary {
        AccountingRevenueService.summary(
            for: outstandingInvoices,
            referenceCurrency: accountingCurrency,
            amount: { $0.accountingOutstandingTotal(referenceCurrency: $1) }
        )
    }

    private var overdueInvoices: [Document] {
        factures.filter(\.isOverdue)
    }

    private var awaitingPaymentInvoices: [Document] {
        outstandingInvoices.filter { !$0.isOverdue }
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
                        value: privacy.format(caMoisEnCours.total, accountingCurrency, lang: numberFormat),
                        subtitle: missingConversionSubtitle(caMoisEnCours),
                        systemImage: "chart.line.uptrend.xyaxis",
                        intent: .info
                    )
                    MetricTile(
                        title: L10n.revenueThisYear(lang),
                        value: privacy.format(caAnneeEnCours.total, accountingCurrency, lang: numberFormat),
                        subtitle: missingConversionSubtitle(caAnneeEnCours),
                        systemImage: "chart.bar.fill",
                        intent: .info
                    )
                    MetricTile(
                        title: L10n.pending(lang),
                        value: privacy.format(montantEnAttente.total, accountingCurrency, lang: numberFormat),
                        subtitle: pendingSubtitle,
                        systemImage: "clock.fill",
                        intent: .warning
                    )
                    MetricTile(
                        title: L10n.quotesInProgress(lang),
                        value: "\(devis.filter { $0.status == .envoyee }.count)",
                        systemImage: "doc.text",
                        intent: .info
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
                    .font(FacioFont.screenTitle)
                Text(L10n.dashboardSubtitle(lang))
                    .font(FacioFont.screenSubtitle)
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
            return "\(L10n.pendingInvoices(lang, count: outstandingInvoices.count)) - \(L10n.missingConversions(lang, count: montantEnAttente.missingConversionCount))"
        }
        return L10n.pendingInvoices(lang, count: outstandingInvoices.count)
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
                    .font(FacioFont.subsectionTitle)
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
                    .font(FacioFont.subsectionTitle)
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
                .font(FacioFont.sectionTitle)
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
                    .font(FacioFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(documentRowDetail(doc))
                    .font(FacioFont.captionSmall)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: FacioLayout.space10)

            MoneyText(amount: doc.totalTTC, currency: doc.currency, lang: numberFormat)
                .font(FacioFont.amount)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(minWidth: 92, maxWidth: 130, alignment: .trailing)
            StatusBadge(status: doc.status, isOverdue: doc.isOverdue, paidViaInstallments: doc.isPaidViaInstallments)
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
                    .font(FacioFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: FacioLayout.space10)

            Text("\(hours)h")
                .font(FacioFont.amount)
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func overflowRow(count: Int) -> some View {
        Text(L10n.moreItems(lang, count: count))
            .font(FacioFont.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, FacioLayout.space10)
            .padding(.vertical, FacioLayout.space4)
    }

    private func documentRowDetail(_ doc: Document) -> String {
        if doc.type == .facture && (doc.status == .envoyee || doc.status == .partiel || doc.isOverdue) {
            return "\(L10n.dueDateLabel(lang)): \(doc.dateEcheance.formattedDate(for: dateFormat))"
        }
        return doc.dateCreation.formattedDate(for: dateFormat)
    }
}

