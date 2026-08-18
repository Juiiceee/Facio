import SwiftUI

struct DashboardView: View {
    /// Mois ouvert depuis le graphique — la barre devient une porte.
    @State private var selectedMonth: Date?

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
                        subtitle: missingConversionSubtitle(caMoisEnCours)
                            ?? L10n.basisCollected(lang, currency: accountingCurrency.rawValue),
                        systemImage: "chart.line.uptrend.xyaxis",
                        intent: .info
                    )
                    MetricTile(
                        title: L10n.revenueThisYear(lang),
                        value: privacy.format(caAnneeEnCours.total, accountingCurrency, lang: numberFormat),
                        subtitle: missingConversionSubtitle(caAnneeEnCours)
                            ?? L10n.basisCollected(lang, currency: accountingCurrency.rawValue),
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
                    // « Devis en cours » comptait exactement le même filtre que
                    // le groupe « Devis à relancer » juste dessous : le même
                    // ensemble, montré deux fois sous deux noms. La TVA
                    // collectée, elle, a une échéance.
                    MetricTile(
                        title: L10n.vatCollected(lang, quarter: RevenueSeriesService.quarterNumber(of: Date())),
                        value: privacy.format(vatCollectedThisQuarter, accountingCurrency, lang: numberFormat),
                        subtitle: L10n.basisCollected(lang, currency: accountingCurrency.rawValue),
                        systemImage: "percent",
                        intent: .warning
                    )
                }

                revenueSeriesSection

                focusSection
                recentSection
            }
            .padding(FacioLayout.screenPadding)
        }
        .sheet(item: Binding(
            get: { selectedMonth.map(MonthSelection.init(start:)) },
            set: { selectedMonth = $0?.start }
        )) { selection in
            monthCollectionsSheet(selection.start)
        }
    }

    /// `Date` n'est pas `Identifiable` : ce porteur permet de piloter la feuille
    /// par la donnée plutôt que par un booléen doublé d'un état.
    private struct MonthSelection: Identifiable {
        let start: Date
        var id: Date { start }
    }

    /// Les douze derniers mois d'encaissements.
    private var revenueSeriesSection: some View {
        SectionPanel(
            L10n.revenueSeriesTitle(lang, count: 12),
            systemImage: "chart.bar"
        ) {
            RevenueChartView(
                months: monthlySeries,
                currency: accountingCurrency,
                lang: lang,
                numberFormat: numberFormat,
                onSelectMonth: { selectedMonth = $0.start }
            )
        }
    }

    private var monthlySeries: [RevenueMonth] {
        RevenueSeriesService.monthlySeries(
            for: facturesEncaissees,
            referenceCurrency: accountingCurrency
        )
    }

    private var vatCollectedThisQuarter: Decimal {
        RevenueSeriesService.vatCollectedThisQuarter(
            for: facturesEncaissees,
            referenceCurrency: accountingCurrency
        )
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

    /// Les factures qui composent la barre cliquée.
    private func monthCollectionsSheet(_ month: Date) -> some View {
        let rows = RevenueSeriesService.collections(
            for: dataStore.documents,
            referenceCurrency: accountingCurrency,
            in: month
        )
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L10n.monthInvoicesTitle(lang, month: month.formatted(.dateTime.month(.wide).year())))
                    .font(FacioFont.sectionTitle)
                Spacer()
                Text(privacy.format(rows.reduce(Decimal(0)) { $0 + $1.amount }, accountingCurrency, lang: numberFormat))
                    .font(FacioFont.amountHero)
            }
            .padding(FacioLayout.screenPadding)

            Divider()

            if rows.isEmpty {
                FacioEmptyState(title: L10n.monthInvoicesEmpty(lang), systemImage: "tray")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: FacioLayout.space8) {
                        ForEach(rows) { row in
                            Button {
                                selectedMonth = nil
                                onSelectDocument(row.document)
                            } label: {
                                FacioListRow(tone: Color.statusColor(for: row.document.status)) {
                                    VStack(alignment: .leading, spacing: FacioLayout.space2) {
                                        Text(row.document.number)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                        Text(row.document.clientNom)
                                            .font(FacioFont.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: FacioLayout.space10)
                                    // Le montant ENCAISSÉ ce mois-là, pas le
                                    // total de la facture : un acompte de mars
                                    // n'appartient pas à la barre d'avril.
                                    Text(privacy.format(row.amount, accountingCurrency, lang: numberFormat))
                                        .font(FacioFont.amount)
                                        .lineLimit(1)
                                        .frame(width: FacioLayout.rowAmountWidth, alignment: .trailing)
                                }
                            }
                            .buttonStyle(.plain)
                            .help(L10n.openDocument(lang))
                        }
                    }
                    .padding(FacioLayout.screenPadding)
                }
            }

            Divider()

            HStack {
                Spacer()
                FacioButton(L10n.close(lang), role: .secondary) { selectedMonth = nil }
            }
            .padding(FacioLayout.screenPadding)
        }
        .frame(
            minWidth: FacioLayout.sheetMinWidth, idealWidth: FacioLayout.sheetIdealWidth,
            minHeight: FacioLayout.sheetMinHeight, idealHeight: FacioLayout.sheetIdealHeight
        )
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

    /// Compte, base comptable et devise. La base était invisible : cette tuile
    /// est en FACTURÉ (soldes restants) alors que les deux tuiles de CA à côté
    /// sont en encaissé — rien ne le disait, ni dans quelle devise.
    private var pendingSubtitle: String {
        var parts = [L10n.pendingInvoices(lang, count: outstandingInvoices.count)]
        if montantEnAttente.missingConversionCount > 0 {
            parts.append(L10n.missingConversions(lang, count: montantEnAttente.missingConversionCount))
        }
        parts.append(L10n.basisOutstanding(lang, currency: accountingCurrency.rawValue))
        return parts.joined(separator: " · ")
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
            // Le titre s'aligne sur le TEXTE des lignes, pas sur le bord du
            // panneau : une ligne commence par son filet de 3 pt puis son
            // gouttière, le titre était donc décalé de la colonne qu'il coiffe.
            Text(title)
                .font(FacioFont.sectionTitle)
                .padding(.leading, FacioLayout.rowPadding + FacioLayout.space12 + 3)
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

            // Montant et statut à largeur FIXE. Avec un montant élastique
            // (92→130 pt) et un badge dimensionné par son texte
            // (« Payée » / « Envoyée » / « Partiel »), la largeur minimale de
            // chaque ligne variait : les lignes débordaient de leur colonne
            // d'une quantité différente, d'où les bords droits en escalier et
            // les badges rognés en « ✈ En ». À largeur fixe, toutes les lignes
            // s'alignent et le titre reste lisible.
            MoneyText(amount: doc.totalTTC, currency: doc.currency, lang: numberFormat)
                .font(FacioFont.amount)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: FacioLayout.rowAmountWidth, alignment: .trailing)
            StatusBadge(status: doc.status, isOverdue: doc.isOverdue, paidViaInstallments: doc.isPaidViaInstallments)
                .frame(width: FacioLayout.rowStatusWidth, alignment: .leading)
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

