import SwiftUI

private enum TimeHubSection: String, CaseIterable, Identifiable {
    case overview
    case tasks
    case calendar
    case log

    var id: String { rawValue }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .overview: return L10n.timeHubOverview(lang)
        case .tasks: return L10n.timeHubTasks(lang)
        case .calendar: return L10n.timeHubCalendar(lang)
        case .log: return L10n.timeHubLog(lang)
        }
    }
}

private enum TimeHubCalendarMode: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .week: return L10n.weekView(lang)
        case .month: return L10n.monthView(lang)
        }
    }
}

private struct TimeHubDeletedUndo: Identifiable {
    let id: UUID
    let context: TimeHubEntryContext
}

struct TimeHubView: View {
    var onOpenInvoice: (Document) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore
    @Environment(PrivacyMode.self) private var privacy

    @State private var selectedTimesheetId: UUID?
    @State private var selectedSection: TimeHubSection = .overview
    @State private var periodMode: TimeHubPeriodMode = .week
    @State private var calendarMode: TimeHubCalendarMode = .week
    @State private var anchorDate = Date()
    @State private var filters = TimeTrackingFilters()
    @State private var editingEntryId: UUID?
    @State private var deletedUndo: TimeHubDeletedUndo?
    @State private var showManualEntrySheet = false

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }
    private var currency: CurrencyType { dataStore.companyInfo.deviseParDefaut }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let now = timeline.date
            let interval = periodMode.interval(containing: anchorDate)
            let contexts = TimeHubAggregationService.contexts(
                from: dataStore.timesheets,
                in: interval,
                filters: filters,
                now: now
            )
            let stats = TimeHubAggregationService.stats(for: contexts, now: now)

            ScrollView {
                VStack(alignment: .leading, spacing: FacioLayout.sectionSpacing) {
                    header(interval: interval)
                    SharedTimerBarView(selectedTimesheetId: $selectedTimesheetId)
                    undoBar
                    statsGrid(stats: stats)
                    sectionPicker
                    content(section: selectedSection, contexts: contexts, stats: stats, interval: interval, now: now)
                }
                .padding(FacioLayout.screenPadding)
            }
            .navigationTitle(L10n.sidebarPlanning(lang))
            .sheet(isPresented: $showManualEntrySheet) {
                TimeHubManualEntrySheet()
                    .environment(dataStore)
            }
        }
    }

    private func header(interval: DateInterval) -> some View {
        SectionPanel(nil) {
            VStack(alignment: .leading, spacing: FacioLayout.space16) {
                // Rangée titre + contrôles de période : contenu 100 % intrinsèque,
                // ViewThatFits bascule sur la variante empilée quand la largeur manque.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: FacioLayout.space12) {
                        headerTitle(interval: interval)
                        Spacer()
                        periodControls
                    }

                    VStack(alignment: .leading, spacing: FacioLayout.space10) {
                        headerTitle(interval: interval)
                        HStack(spacing: FacioLayout.space12) {
                            periodModePicker
                            Spacer()
                            periodNavigation
                        }
                    }
                }

                // Filtres : la grille adaptative fait wrapper les pickers sous 640 pt,
                // sans branche conditionnelle.
                FormGrid(minimum: 160, maximum: 260, spacing: FacioLayout.space10) {
                    clientFilterPicker
                    billableFilterPicker
                    invoicedFilterPicker
                }

                // Recherche + ajout manuel : pleine largeur sous la grille de filtres.
                HStack(spacing: FacioLayout.space10) {
                    TextField(L10n.searchTimeHub(lang), text: $filters.searchText)
                        .facioField()

                    Button {
                        showManualEntrySheet = true
                    } label: {
                        Label(L10n.timeHubAddManualEntry(lang), systemImage: "plus")
                    }
                }
            }
        }
    }

    /// Bloc titre + sous-titre de période, partagé entre les variantes du header.
    private func headerTitle(interval: DateInterval) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space2) {
            Label(L10n.sidebarPlanning(lang), systemImage: "calendar.badge.clock")
                .font(FacioFont.screenTitle)
            Text(periodTitle(interval))
                .font(FacioFont.screenSubtitle)
                .foregroundStyle(.secondary)
        }
    }

    /// Contrôles de période sur une seule ligne (variante large du header).
    private var periodControls: some View {
        HStack(spacing: FacioLayout.space12) {
            periodModePicker
            periodNavigation
        }
    }

    /// Sélecteur jour / semaine / mois, partagé entre les variantes du header.
    private var periodModePicker: some View {
        Picker("", selection: $periodMode) {
            Text(L10n.periodDay(lang)).tag(TimeHubPeriodMode.day)
            Text(L10n.periodWeek(lang)).tag(TimeHubPeriodMode.week)
            Text(L10n.periodMonth(lang)).tag(TimeHubPeriodMode.month)
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(width: 260)
    }

    /// Navigation temporelle précédent / aujourd'hui / suivant, partagée.
    private var periodNavigation: some View {
        HStack(spacing: FacioLayout.space12) {
            Button {
                anchorDate = periodMode.shiftedAnchor(from: anchorDate, value: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .help(L10n.previousPeriod(lang))

            Button(L10n.today(lang)) {
                anchorDate = Date()
            }

            Button {
                anchorDate = periodMode.shiftedAnchor(from: anchorDate, value: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .help(L10n.nextPeriod(lang))
        }
    }

    /// Filtre par client — la largeur est pilotée par la cellule de la FormGrid.
    private var clientFilterPicker: some View {
        Picker(L10n.sidebarClients(lang), selection: $filters.clientId) {
            Text(L10n.allClients(lang)).tag(Optional<UUID>.none)
            ForEach(dataStore.clients.sorted { $0.displayName < $1.displayName }) { client in
                Text(client.displayName.isEmpty ? L10n.noClient(lang) : client.displayName)
                    .tag(Optional(client.id))
            }
        }
    }

    /// Filtre facturable / non facturable.
    private var billableFilterPicker: some View {
        Picker(L10n.billable(lang), selection: $filters.billable) {
            Text(L10n.allBillableStates(lang)).tag(Optional<Bool>.none)
            Text(L10n.billable(lang)).tag(Optional(true))
            Text(L10n.nonBillable(lang)).tag(Optional(false))
        }
    }

    /// Filtre facturé / non facturé.
    private var invoicedFilterPicker: some View {
        Picker(L10n.invoiced(lang), selection: $filters.invoiced) {
            Text(L10n.allInvoiceStates(lang)).tag(Optional<Bool>.none)
            Text(L10n.invoiced(lang)).tag(Optional(true))
            Text(L10n.notInvoiced(lang)).tag(Optional(false))
        }
    }

    private func statsGrid(stats: TimeHubStats) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 230))], spacing: FacioLayout.space12) {
            MetricTile(
                title: periodMode == .day ? L10n.today(lang) : L10n.trackedTime(lang),
                value: formatDuration(stats.totalSeconds),
                systemImage: "clock",
                intent: .info
            )
            MetricTile(
                title: L10n.billableTime(lang),
                value: formatDuration(stats.billableSeconds),
                systemImage: "dollarsign.circle",
                intent: .success
            )
            MetricTile(
                title: L10n.estimatedAmount(lang),
                value: privacy.format(stats.estimatedAmount, currency, lang: numberFormat),
                systemImage: "banknote",
                intent: .accent(from: dataStore.companyInfo)
            )
            MetricTile(
                title: L10n.uninvoicedTime(lang),
                value: formatDuration(stats.uninvoicedSeconds),
                subtitle: L10n.entriesCount(lang, count: stats.entriesCount),
                systemImage: "tray.full",
                intent: .warning
            )
            MetricTile(
                title: L10n.nonBillableTime(lang),
                value: formatDuration(stats.nonBillableSeconds),
                systemImage: "clock.badge.xmark",
                intent: .neutral
            )
            MetricTile(
                title: L10n.activeTasks(lang),
                value: "\(stats.activeTasksCount)",
                systemImage: "play.circle",
                intent: .danger
            )
        }
    }

    private var sectionPicker: some View {
        Picker("", selection: $selectedSection) {
            ForEach(TimeHubSection.allCases) { section in
                Text(section.label(for: lang)).tag(section)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private func content(
        section: TimeHubSection,
        contexts: [TimeHubEntryContext],
        stats: TimeHubStats,
        interval: DateInterval,
        now: Date
    ) -> some View {
        switch section {
        case .overview:
            overview(contexts: contexts, interval: interval, now: now)
        case .tasks:
            tasks(contexts: contexts, now: now)
        case .calendar:
            calendar(contexts: contexts, interval: interval, now: now)
        case .log:
            log(contexts: contexts, now: now)
        }
    }

    private func overview(contexts: [TimeHubEntryContext], interval: DateInterval, now: Date) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 360, maximum: 620), alignment: .top)], spacing: FacioLayout.space16) {
            todayPanel(now: now)
            uninvoicedPanel(contexts: contexts, now: now)
            groupPanel(
                title: L10n.byClient(lang),
                systemImage: "person.2",
                groups: TimeHubAggregationService.clientGroups(for: contexts, now: now),
                now: now
            )
            projectPanel(groups: TimeHubAggregationService.projectGroups(for: contexts, now: now), now: now)
            recentPanel(contexts: contexts, now: now)
        }
    }

    private func todayPanel(now: Date) -> some View {
        let interval = TimeHubPeriodMode.day.interval(containing: Date())
        let todayContexts = TimeHubAggregationService.contexts(
            from: dataStore.timesheets,
            in: interval,
            filters: filters,
            now: now
        )
        let stats = TimeHubAggregationService.stats(for: todayContexts, now: now)
        return SectionPanel(L10n.todayTimeline(lang), systemImage: "calendar") {
            VStack(alignment: .leading, spacing: FacioLayout.space10) {
                HStack {
                    Text(formatDuration(stats.totalSeconds))
                        .font(FacioFont.metricValue)
                    Spacer()
                    Button(L10n.openLogToday(lang)) {
                        periodMode = .day
                        anchorDate = Date()
                        selectedSection = .log
                    }
                    Button(L10n.openCalendarToday(lang)) {
                        periodMode = .day
                        anchorDate = Date()
                        selectedSection = .calendar
                    }
                }
                if todayContexts.isEmpty {
                    FacioEmptyState(
                        title: L10n.noTimeToday(lang),
                        systemImage: "timer",
                        message: L10n.noTimeTodayHint(lang)
                    )
                    .frame(maxWidth: .infinity, minHeight: 130)
                } else {
                    ForEach(todayContexts.prefix(5)) { context in
                        compactEntryRow(context, now: now)
                    }
                }
            }
        }
    }

    private func groupPanel(
        title: String,
        systemImage: String,
        groups: [TimeHubClientGroup],
        now: Date
    ) -> some View {
        SectionPanel(title, systemImage: systemImage) {
            VStack(alignment: .leading, spacing: FacioLayout.space8) {
                if groups.isEmpty {
                    emptyText(L10n.noTimeEntriesForPeriod(lang))
                } else {
                    ForEach(groups.prefix(6)) { group in
                        metricGroupRow(
                            title: group.clientName.isEmpty ? L10n.noClient(lang) : group.clientName,
                            subtitle: L10n.entriesCount(lang, count: group.contexts.count),
                            stats: group.stats
                        )
                    }
                }
            }
        }
    }

    private func projectPanel(groups: [TimeHubProjectGroup], now: Date) -> some View {
        SectionPanel(L10n.byProject(lang), systemImage: "folder") {
            VStack(alignment: .leading, spacing: FacioLayout.space8) {
                if groups.isEmpty {
                    emptyText(L10n.noTimeEntriesForPeriod(lang))
                } else {
                    ForEach(groups.prefix(6)) { group in
                        metricGroupRow(
                            title: group.projectName.isEmpty ? L10n.project(lang) : group.projectName,
                            subtitle: group.clientName,
                            stats: group.stats
                        )
                    }
                }
            }
        }
    }

    private func uninvoicedPanel(contexts: [TimeHubEntryContext], now: Date) -> some View {
        let uninvoiced = contexts.filter { $0.entry.isBillable && !$0.entry.isInvoiced && !$0.entry.isDeleted && !$0.entry.isRunning }
        let groups = Dictionary(grouping: uninvoiced) { $0.timesheet.id }
            .map { _, contexts in
                (timesheet: contexts[0].timesheet, contexts: contexts, stats: TimeHubAggregationService.stats(for: contexts, now: now))
            }
            .sorted { $0.stats.estimatedAmount > $1.stats.estimatedAmount }

        return SectionPanel(L10n.toInvoice(lang), systemImage: "doc.text") {
            VStack(alignment: .leading, spacing: FacioLayout.space10) {
                if groups.isEmpty {
                    FacioEmptyState(
                        title: L10n.noBillableTimePending(lang),
                        systemImage: "checkmark.circle"
                    )
                    .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    ForEach(groups, id: \.timesheet.id) { group in
                        HStack(spacing: FacioLayout.space12) {
                            metricGroupRow(
                                title: group.timesheet.clientDisplayName.isEmpty ? group.timesheet.periodLabel(for: lang) : group.timesheet.clientDisplayName,
                                subtitle: group.timesheet.periodLabel(for: lang),
                                stats: group.stats
                            )
                            Button {
                                if let invoice = dataStore.generateInvoiceFromTimeEntries(
                                    group.contexts.map(\.entry),
                                    from: group.timesheet,
                                    grouping: .detailed
                                ) {
                                    onOpenInvoice(invoice)
                                }
                            } label: {
                                Label(L10n.createInvoice(lang), systemImage: "doc.badge.plus")
                            }
                            .buttonStyle(.facio(.primary))
                        }
                    }
                }
            }
        }
    }

    private func recentPanel(contexts: [TimeHubEntryContext], now: Date) -> some View {
        SectionPanel(L10n.recentActivity(lang), systemImage: "clock.arrow.circlepath") {
            VStack(alignment: .leading, spacing: FacioLayout.space8) {
                if contexts.isEmpty {
                    emptyText(L10n.noTimeEntriesForPeriod(lang))
                } else {
                    ForEach(contexts.prefix(8)) { context in
                        compactEntryRow(context, now: now)
                    }
                }
            }
        }
    }

    private func tasks(contexts: [TimeHubEntryContext], now: Date) -> some View {
        let groups = TimeHubAggregationService.taskGroups(for: contexts, now: now)
        return SectionPanel(L10n.timeHubTasks(lang), systemImage: "checklist") {
            VStack(alignment: .leading, spacing: FacioLayout.space12) {
                if groups.isEmpty {
                    FacioEmptyState(
                        title: L10n.noTaskYet(lang),
                        systemImage: "checklist",
                        message: L10n.noTaskYetHint(lang)
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 360), alignment: .top)], spacing: FacioLayout.space12) {
                        ForEach(groups) { group in
                            taskCard(group, now: now)
                        }
                    }
                }
            }
        }
    }

    private func taskCard(_ group: TimeHubTaskGroup, now: Date) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: FacioLayout.space2) {
                    Text(group.title == "untitled" ? L10n.untitledTask(lang) : group.title)
                        .font(FacioFont.sectionTitle)
                        .lineLimit(2)
                    Text([group.clientName, group.projectName].filter { !$0.isEmpty }.joined(separator: " / "))
                        .font(FacioFont.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                FacioIconButton(
                    systemImage: "play.fill",
                    tone: .intentSuccess,
                    help: L10n.startThisTask(lang),
                    isEnabled: dataStore.runningTimeEntryContext == nil
                ) {
                    startTask(group)
                }
            }

            HStack {
                Label(formatDuration(group.stats.totalSeconds), systemImage: "clock")
                Spacer()
                MoneyText(amount: group.stats.estimatedAmount, currency: currency, lang: numberFormat)
                    .font(FacioFont.metaValue)
                    .foregroundStyle(.secondary)
            }
            .font(FacioFont.caption)

            ProgressView(value: progressValue(group))
                .tint(Color.intentSuccess)
        }
        .padding(FacioLayout.space12)
        .frame(maxWidth: .infinity, minHeight: 135, alignment: .topLeading)
        .facioCardChrome(surface: .surfaceTile)
    }

    private func calendar(contexts: [TimeHubEntryContext], interval: DateInterval, now: Date) -> some View {
        SectionPanel(L10n.timeHubCalendar(lang), systemImage: "calendar") {
            VStack(alignment: .leading, spacing: FacioLayout.space16) {
                Picker("", selection: $calendarMode) {
                    ForEach(TimeHubCalendarMode.allCases) { mode in
                        Text(mode.label(for: lang)).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 220)

                switch calendarMode {
                case .week:
                    weekCalendar(contexts: contexts, now: now)
                case .month:
                    monthCalendar(contexts: contexts, now: now)
                }
            }
        }
    }

    private func weekCalendar(contexts: [TimeHubEntryContext], now: Date) -> some View {
        let week = TimeHubPeriodMode.week.interval(containing: anchorDate)
        let days = (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: week.start) }
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: FacioLayout.space8), count: 7), spacing: FacioLayout.space8) {
            ForEach(days, id: \.self) { day in
                dayColumn(day: day, contexts: contextsForDay(day, in: contexts), now: now)
            }
        }
    }

    private func monthCalendar(contexts: [TimeHubEntryContext], now: Date) -> some View {
        let month = TimeHubPeriodMode.month.interval(containing: anchorDate)
        let calendar = MonthGrid.calendar()
        let dayCount = calendar.range(of: .day, in: .month, for: month.start)?.count ?? 30
        let days = (0..<dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: month.start) }
        // Sans ces cases vides, la colonne 1 n'est pas le lundi : la grille
        // ressemble à un calendrier sans en être un.
        let leadingBlanks = MonthGrid.leadingBlanks(monthStart: month.start)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: FacioLayout.space8), count: 7), spacing: FacioLayout.space8) {
            ForEach(Array(MonthGrid.weekdaySymbols().enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(FacioFont.captionSmall)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            ForEach(Array(0..<leadingBlanks), id: \.self) { _ in
                Color.clear.frame(height: 1)
            }
            ForEach(days, id: \.self) { day in
                monthDayCell(day: day, contexts: contextsForDay(day, in: contexts), now: now)
            }
        }
    }

    private func dayColumn(day: Date, contexts: [TimeHubEntryContext], now: Date) -> some View {
        let stats = TimeHubAggregationService.stats(for: contexts, now: now)
        return VStack(alignment: .leading, spacing: FacioLayout.space8) {
            Text(day.formatted(.dateTime.weekday(.abbreviated).day()))
                .font(FacioFont.caption)
                .fontWeight(.semibold)
            Text(formatDuration(stats.totalSeconds))
                .font(FacioFont.metaValue)
                .foregroundStyle(.secondary)
            ForEach(contexts.prefix(4)) { context in
                calendarBlock(context, now: now)
            }
            Spacer(minLength: 0)
        }
        .padding(FacioLayout.space8)
        .frame(maxWidth: .infinity, minHeight: 230, alignment: .topLeading)
        .background(Color.surfaceRow)
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
        .onTapGesture {
            anchorDate = day
            periodMode = .day
            selectedSection = .log
        }
    }

    private func monthDayCell(day: Date, contexts: [TimeHubEntryContext], now: Date) -> some View {
        let stats = TimeHubAggregationService.stats(for: contexts, now: now)
        return VStack(alignment: .leading, spacing: FacioLayout.space6) {
            Text(day.formatted(.dateTime.day()))
                .font(FacioFont.caption)
                .fontWeight(.semibold)
            if stats.totalSeconds > 0 {
                Text(formatDuration(stats.totalSeconds))
                    .font(.caption2.monospacedDigit())
                HStack(spacing: FacioLayout.space2) {
                    ForEach(contexts.prefix(3)) { context in
                        Circle()
                            .fill(context.entry.isBillable ? Color.intentSuccess : Color.secondary)
                            .frame(width: 5, height: 5)
                    }
                    if stats.uninvoicedSeconds > 0 {
                        Image(systemName: "tray.full")
                            .font(.caption2)
                            .foregroundStyle(Color.intentWarning)
                    }
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(FacioLayout.space8)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
        .background(Color.surfaceRow)
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
        .onTapGesture {
            anchorDate = day
            periodMode = .day
            selectedSection = .log
        }
    }

    private func calendarBlock(_ context: TimeHubEntryContext, now: Date) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space2) {
            Text(context.entry.notes.isEmpty ? TimeHubAggregationService.taskTitle(for: context.entry) : context.entry.notes)
                .font(FacioFont.captionSmall)
                .fontWeight(.medium)
                .lineLimit(2)
            Text("\(timeRange(context.entry)) - \(formatDuration(context.durationSeconds(at: now)))")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(FacioLayout.space6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((context.entry.isBillable ? Color.intentSuccess : Color.secondary).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusField))
        .onTapGesture {
            editingEntryId = context.entry.id
            selectedSection = .log
        }
    }

    private func log(contexts: [TimeHubEntryContext], now: Date) -> some View {
        let groups = TimeHubAggregationService.dayGroups(for: contexts, now: now)
        return SectionPanel(L10n.timeHubLog(lang), systemImage: "list.bullet.rectangle") {
            VStack(alignment: .leading, spacing: FacioLayout.space16) {
                if groups.isEmpty {
                    FacioEmptyState(
                        title: L10n.noTimeEntriesForPeriod(lang),
                        systemImage: "list.bullet.rectangle"
                    )
                    .frame(maxWidth: .infinity, minHeight: 160)
                } else {
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: FacioLayout.space8) {
                            HStack {
                                Text(group.date.formattedDate(for: lang))
                                    .font(FacioFont.sectionTitle)
                                Text(formatDuration(group.stats.totalSeconds))
                                    .font(FacioFont.rowValue)
                                    .foregroundStyle(.secondary)
                                MoneyText(amount: group.stats.estimatedAmount, currency: currency, lang: numberFormat)
                                    .font(FacioFont.rowValue)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if group.stats.uninvoicedSeconds > 0 {
                                    statusBadge(L10n.notInvoiced(lang), color: .intentWarning)
                                }
                            }
                            ForEach(group.contexts) { context in
                                VStack(spacing: FacioLayout.space6) {
                                    TimeHubEntryRow(
                                        context: context,
                                        now: now,
                                        lang: lang,
                                        numberFormat: numberFormat,
                                        defaultCurrency: currency,
                                        onEdit: { editingEntryId = editingEntryId == context.entry.id ? nil : context.entry.id },
                                        onContinue: { _ = dataStore.continueTimeEntry(context.entry, in: context.timesheet) },
                                        onDelete: { deleteWithUndo(context) },
                                        onInvoice: {
                                            if let invoice = dataStore.generateInvoiceFromTimeEntries([context.entry], from: context.timesheet) {
                                                onOpenInvoice(invoice)
                                            }
                                        }
                                    )
                                    if editingEntryId == context.entry.id {
                                        TimeHubEntryEditor(context: context) {
                                            editingEntryId = nil
                                        }
                                        .environment(dataStore)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var undoBar: some View {
        if let deletedUndo {
            HStack(spacing: FacioLayout.space10) {
                Label(L10n.entryDeleted(lang), systemImage: "trash")
                Button(L10n.undo(lang)) {
                    dataStore.restoreTimeEntry(deletedUndo.context.entry, in: deletedUndo.context.timesheet)
                    self.deletedUndo = nil
                }
                Spacer()
            }
            .font(.subheadline)
            .padding(FacioLayout.space10)
            .background(Color.intentWarning.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
        }
    }

    private func compactEntryRow(_ context: TimeHubEntryContext, now: Date) -> some View {
        HStack(spacing: FacioLayout.space10) {
            VStack(alignment: .leading, spacing: FacioLayout.space2) {
                Text(context.entry.notes.isEmpty ? TimeHubAggregationService.taskTitle(for: context.entry) : context.entry.notes)
                    .font(FacioFont.rowTitle)
                    .lineLimit(1)
                Text([context.clientName, context.entry.displayProject, context.entry.displayTask].filter { !$0.isEmpty }.joined(separator: " / "))
                    .font(FacioFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(formatDuration(context.durationSeconds(at: now)))
                .font(FacioFont.metaValue)
            statusBadge(context.entry.isBillable ? L10n.billable(lang) : L10n.nonBillable(lang), color: context.entry.isBillable ? .intentSuccess : .secondary)
        }
        .padding(FacioLayout.space8)
        .background(Color.surfaceRow)
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusRow))
    }

    private func metricGroupRow(title: String, subtitle: String, stats: TimeHubStats) -> some View {
        HStack(spacing: FacioLayout.space12) {
            VStack(alignment: .leading, spacing: FacioLayout.space2) {
                Text(title.isEmpty ? L10n.noClient(lang) : title)
                    .font(FacioFont.rowTitle)
                    .lineLimit(1)
                Text(subtitle)
                    .font(FacioFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: FacioLayout.space2) {
                Text(formatDuration(stats.totalSeconds))
                    .font(FacioFont.rowValue)
                    .fontWeight(.semibold)
                MoneyText(amount: stats.estimatedAmount, currency: currency, lang: numberFormat)
                    .font(FacioFont.metaValue)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(FacioLayout.space8)
        .background(Color.surfaceRow)
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusRow))
    }

    private func emptyText(_ value: String) -> some View {
        Text(value)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, FacioLayout.space10)
    }

    private func contextsForDay(_ day: Date, in contexts: [TimeHubEntryContext]) -> [TimeHubEntryContext] {
        let dateString = TimeEntry.dateString(for: day)
        return contexts
            .filter { $0.entry.dateString == dateString }
            .sorted { $0.entry.startedAt < $1.entry.startedAt }
    }

    private func startTask(_ group: TimeHubTaskGroup) {
        guard dataStore.runningTimeEntryContext == nil,
              let source = group.contexts.sorted(by: { $0.entry.startedAt > $1.entry.startedAt }).first else {
            return
        }
        _ = dataStore.startTimeEntry(
            in: source.timesheet,
            projectName: source.entry.projectName,
            taskName: source.entry.taskName,
            notes: source.entry.notes.isEmpty ? group.title : source.entry.notes,
            tagsText: source.entry.tagsText,
            isBillable: source.entry.isBillable
        )
    }

    private func deleteWithUndo(_ context: TimeHubEntryContext) {
        dataStore.deleteTimeEntry(context.entry, from: context.timesheet)
        deletedUndo = TimeHubDeletedUndo(id: context.entry.id, context: context)
        let deletedId = context.entry.id
        Task {
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            await MainActor.run {
                if deletedUndo?.id == deletedId {
                    deletedUndo = nil
                }
            }
        }
    }

    private func progressValue(_ group: TimeHubTaskGroup) -> Double {
        guard group.stats.totalSeconds > 0 else { return 0.08 }
        let capped = min(group.stats.totalSeconds, 8 * 3600)
        return Double(capped) / Double(8 * 3600)
    }

    private func periodTitle(_ interval: DateInterval) -> String {
        switch periodMode {
        case .day:
            return interval.start.formattedDate(for: lang)
        case .week, .month:
            return "\(interval.start.formattedDate(for: lang)) - \(Calendar.current.date(byAdding: .day, value: -1, to: interval.end)?.formattedDate(for: lang) ?? interval.end.formattedDate(for: lang))"
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours == 0 {
            return "\(minutes)m"
        }
        return "\(hours)h \(String(format: "%02d", minutes))m"
    }

    private func timeRange(_ entry: TimeEntry) -> String {
        let start = entry.startedAt.formatted(date: .omitted, time: .shortened)
        guard let endedAt = entry.endedAt else { return "\(start) - \(L10n.now(lang))" }
        return "\(start) - \(endedAt.formatted(date: .omitted, time: .shortened))"
    }

    private func statusBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(FacioFont.captionSmall)
            .padding(.horizontal, FacioLayout.space6)
            .padding(.vertical, FacioLayout.space4)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusBadge))
    }
}

private struct TimeHubEntryRow: View {
    let context: TimeHubEntryContext
    let now: Date
    let lang: AppLanguage
    let numberFormat: AppLanguage
    let defaultCurrency: CurrencyType
    let onEdit: () -> Void
    let onContinue: () -> Void
    let onDelete: () -> Void
    let onInvoice: () -> Void

    var body: some View {
        HStack(spacing: FacioLayout.space12) {
            Image(systemName: context.entry.isRunning ? "timer" : "clock")
                .foregroundStyle(context.entry.isRunning ? Color.intentSuccess : .secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: FacioLayout.space4) {
                Text(title)
                    .font(FacioFont.rowTitle)
                Text([context.clientName, context.entry.displayProject, context.entry.displayTask].filter { !$0.isEmpty }.joined(separator: " / "))
                    .font(FacioFont.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: FacioLayout.space6) {
                    badge(context.entry.isBillable ? L10n.billable(lang) : L10n.nonBillable(lang), color: context.entry.isBillable ? .intentSuccess : .secondary)
                    badge(context.entry.isInvoiced ? L10n.invoiced(lang) : L10n.notInvoiced(lang), color: context.entry.isInvoiced ? .intentSuccess : .intentWarning)
                    ForEach(context.entry.tags.prefix(3), id: \.self) { tag in
                        badge(tag, color: .intentInfo)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: FacioLayout.space2) {
                Text(DurationFormatter.clock(context.durationSeconds(at: now)))
                    .font(FacioFont.rowValue)
                    .fontWeight(.semibold)
                if context.entry.isBillable {
                    MoneyText(amount: context.estimatedAmount(at: now), currency: context.entry.currencySnapshot ?? defaultCurrency, lang: numberFormat)
                        .font(FacioFont.metaValue)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: FacioLayout.space4) {
                FacioIconButton(
                    systemImage: "play.fill",
                    help: L10n.continueTimer(lang),
                    isEnabled: !context.entry.isRunning,
                    action: onContinue
                )
                FacioIconButton(
                    systemImage: "pencil",
                    help: L10n.editTimeEntry(lang),
                    action: onEdit
                )
                FacioIconButton(
                    systemImage: "doc.badge.plus",
                    help: L10n.createInvoice(lang),
                    isEnabled: context.entry.isBillable && !context.entry.isInvoiced && !context.entry.isRunning,
                    action: onInvoice
                )
                FacioIconButton(
                    systemImage: "trash",
                    tone: .intentDanger,
                    help: L10n.delete(lang),
                    isEnabled: !context.entry.isInvoiced,
                    action: onDelete
                )
            }
        }
        .padding(FacioLayout.space10)
        .facioCardChrome(surface: .surfaceTile)
    }

    private var title: String {
        if !context.entry.notes.isEmpty { return context.entry.notes }
        let task = TimeHubAggregationService.taskTitle(for: context.entry)
        return task == "untitled" ? L10n.untitledTask(lang) : task
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(FacioFont.captionSmall)
            .padding(.horizontal, FacioLayout.space6)
            .padding(.vertical, FacioLayout.space4)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusBadge))
    }
}

private struct TimeHubEntryEditor: View {
    let context: TimeHubEntryContext
    let onClose: () -> Void

    @Environment(DataStore.self) private var dataStore
    @State private var projectName: String
    @State private var taskName: String
    @State private var notes: String
    @State private var tagsText: String
    @State private var isBillable: Bool
    @State private var startedAt: Date
    @State private var endedAt: Date
    @State private var validationMessage: String?

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    init(context: TimeHubEntryContext, onClose: @escaping () -> Void) {
        self.context = context
        self.onClose = onClose
        _projectName = State(initialValue: context.entry.projectName)
        _taskName = State(initialValue: context.entry.taskName)
        _notes = State(initialValue: context.entry.notes)
        _tagsText = State(initialValue: context.entry.tagsText)
        _isBillable = State(initialValue: context.entry.isBillable)
        _startedAt = State(initialValue: context.entry.startedAt)
        _endedAt = State(initialValue: context.entry.endedAt ?? Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space10) {
            HStack(spacing: FacioLayout.space10) {
                TextField(L10n.timeEntryDescription(lang), text: $notes)
                    .facioField()
                TextField(L10n.project(lang), text: $projectName)
                    .facioField()
                TextField(L10n.task(lang), text: $taskName)
                    .facioField()
            }
            HStack(spacing: FacioLayout.space10) {
                TextField(L10n.tags(lang), text: $tagsText)
                    .facioField()
                Toggle(L10n.billable(lang), isOn: $isBillable)
                    .toggleStyle(.switch)
                DatePicker(L10n.startDate(lang), selection: $startedAt)
                    .labelsHidden()
                DatePicker(L10n.endDate(lang), selection: $endedAt)
                    .labelsHidden()
                    .disabled(context.entry.isRunning)
            }
            if let validationMessage {
                InlineWarning(text: validationMessage, tone: .warning)
            }
            HStack {
                Spacer()
                Button(L10n.cancel(lang), action: onClose)
                Button(L10n.save(lang), action: save)
                    .buttonStyle(.facio(.primary))
            }
        }
        .padding(FacioLayout.space10)
        .facioCardChrome(surface: .surfaceField)
    }

    private func save() {
        guard context.entry.isRunning || endedAt > startedAt else {
            validationMessage = L10n.invalidTimeRange(lang)
            return
        }
        let previousAffectedDates = Set(context.entry.secondsByDate().keys)
        context.entry.projectName = projectName
        context.entry.taskName = taskName
        context.entry.notes = notes
        context.entry.tagsText = tagsText
        context.entry.isBillable = isBillable
        context.entry.startedAt = startedAt
        if !context.entry.isRunning {
            context.entry.endedAt = endedAt
        }
        dataStore.timeEntryUpdated(context.entry, in: context.timesheet, previousAffectedDateStrings: previousAffectedDates)
        onClose()
    }
}

private struct TimeHubManualEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore

    @State private var selectedTimesheetId: UUID?
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var durationInput = ""
    @State private var projectName = ""
    @State private var taskName = ""
    @State private var notes = ""
    @State private var tagsText = ""
    @State private var isBillable = true
    @State private var validationMessage: String?

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var sortedTimesheets: [TimesheetPeriod] {
        dataStore.timesheets.sorted { $0.activeEndDateString > $1.activeEndDateString }
    }

    private var selectedTimesheet: TimesheetPeriod? {
        if let selectedTimesheetId {
            return dataStore.timesheets.first { $0.id == selectedTimesheetId }
        }
        return sortedTimesheets.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space16) {
            HStack {
                Label(L10n.timeHubAddManualEntry(lang), systemImage: "plus")
                    .font(FacioFont.sectionTitle)
                Spacer()
                Button(L10n.close(lang)) { dismiss() }
            }

            Picker(L10n.selectTrackingPeriod(lang), selection: $selectedTimesheetId) {
                ForEach(sortedTimesheets) { timesheet in
                    Text(timesheet.title(for: lang)).tag(Optional(timesheet.id))
                }
            }

            TextField(L10n.timeEntryDescription(lang), text: $notes)
                .facioField()
            HStack {
                TextField(L10n.project(lang), text: $projectName)
                    .facioField()
                TextField(L10n.task(lang), text: $taskName)
                    .facioField()
            }
            TextField(L10n.tags(lang), text: $tagsText)
                .facioField()

            HStack {
                DatePicker(L10n.period(lang), selection: $date, displayedComponents: [.date])
                DatePicker(L10n.startDate(lang), selection: $startTime, displayedComponents: [.hourAndMinute])
                DatePicker(L10n.endDate(lang), selection: $endTime, displayedComponents: [.hourAndMinute])
            }
            TextField(L10n.durationExamples(lang), text: $durationInput)
                .facioField()
            Toggle(L10n.billable(lang), isOn: $isBillable)
                .toggleStyle(.switch)

            if let validationMessage {
                InlineWarning(text: validationMessage, tone: .warning)
            }

            HStack {
                Spacer()
                Button(L10n.cancel(lang)) { dismiss() }
                Button(L10n.addTimeEntry(lang), action: save)
                    .buttonStyle(.facio(.primary))
                    .disabled(selectedTimesheet == nil)
            }
        }
        .padding(FacioLayout.space20)
        .frame(minWidth: FacioLayout.sheetMinWidth, idealWidth: 520, maxWidth: 560)
        .onAppear {
            selectedTimesheetId = selectedTimesheet?.id
        }
    }

    private func save() {
        validationMessage = nil
        guard let selectedTimesheet else {
            validationMessage = L10n.noTrackingPeriod(lang)
            return
        }
        guard selectedTimesheet.isBillableDateString(TimeEntry.dateString(for: date)) else {
            validationMessage = L10n.timerOutsidePeriod(lang)
            return
        }
        guard let startedAt = combine(date: date, time: startTime) else {
            validationMessage = L10n.invalidTimeRange(lang)
            return
        }

        let endedAt: Date
        do {
            if durationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                guard let end = combine(date: date, time: endTime), end > startedAt else {
                    validationMessage = L10n.invalidTimeRange(lang)
                    return
                }
                endedAt = end
            } else {
                let seconds = try TimeTrackingService.parseDurationInput(durationInput)
                endedAt = startedAt.addingTimeInterval(TimeInterval(seconds))
            }
        } catch {
            validationMessage = L10n.invalidDuration(lang)
            return
        }

        let now = Date()
        let entry = TimeEntry(
            projectName: projectName,
            taskName: taskName,
            notes: notes,
            tagsText: tagsText,
            isBillable: isBillable,
            rateSnapshot: isBillable ? selectedTimesheet.tauxNormal : nil,
            currencySnapshot: isBillable ? dataStore.companyInfo.deviseParDefaut : nil,
            source: .manual,
            startedAt: startedAt,
            endedAt: endedAt,
            createdAt: now,
            updatedAt: now
        )
        dataStore.addTimeEntry(entry, to: selectedTimesheet)
        dismiss()
    }

    private func combine(date: Date, time: Date) -> Date? {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        return TimeTrackingService.combine(date: date, time: TimeOfDay(hour: hour, minute: minute))
    }
}
