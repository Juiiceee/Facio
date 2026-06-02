import SwiftUI

private enum TimeEntryRange: String, CaseIterable, Identifiable {
    case today
    case week
    case period

    var id: String { rawValue }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .today: return L10n.today(lang)
        case .week: return L10n.thisWeek(lang)
        case .period: return L10n.period(lang)
        }
    }
}

private enum TimeEntryInputMode: String, CaseIterable, Identifiable {
    case timer
    case manual

    var id: String { rawValue }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .timer: return L10n.timerMode(lang)
        case .manual: return L10n.manualMode(lang)
        }
    }
}

private struct DeletedTimeEntryUndo: Identifiable {
    let id: UUID
    let entry: TimeEntry
}

struct TimeTrackerPanel: View {
    let timesheet: TimesheetPeriod
    var onOpenInvoice: (Document) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore
    @State private var inputMode: TimeEntryInputMode = .timer
    @State private var projectName = ""
    @State private var taskName = ""
    @State private var notes = ""
    @State private var tagsText = ""
    @State private var isBillable = true
    @State private var usesCustomStartDate = false
    @State private var customStartDate = Date()
    @State private var manualDate = Date()
    @State private var manualStartTime = Date()
    @State private var manualEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var manualDurationInput = ""
    @State private var range: TimeEntryRange = .period
    @State private var searchText = ""
    @State private var editingEntryId: UUID?
    @State private var validationMessage: String?
    @State private var deletedUndo: DeletedTimeEntryUndo?

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }

    private var activeContext: RunningTimeEntryContext? {
        dataStore.runningTimeEntryContext
    }

    private var activeEntryInThisPeriod: TimeEntry? {
        guard activeContext?.timesheet.id == timesheet.id else { return nil }
        return activeContext?.entry
    }

    private var filteredEntries: [TimeEntry] {
        timesheet.timeEntries
            .filter { !$0.isDeleted && matchesRange($0) && matchesSearch($0) }
            .sorted { $0.startedAt > $1.startedAt }
    }

    private var periodEntries: [TimeEntry] {
        timesheet.timeEntries
            .filter { !$0.isDeleted && timesheet.isBillableDateString($0.dateString) }
            .sorted { $0.startedAt > $1.startedAt }
    }

    private var canUseLiveTimerInPeriod: Bool {
        liveStartDateRange != nil
    }

    private var canStartLiveTimer: Bool {
        canUseLiveTimerInPeriod && activeContext == nil
    }

    private var liveStartDateRange: ClosedRange<Date>? {
        let now = Date()
        let endOfDay = Self.endOfDay(for: timesheet.activeEndDate)
        let upperBound = min(now, endOfDay)
        guard upperBound >= timesheet.activeStartDate else { return nil }
        return timesheet.activeStartDate...upperBound
    }

    var body: some View {
        SectionPanel(L10n.timeTracker(lang), systemImage: "timer") {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    trackerHeader(now: context.date)
                    Divider()
                    filterBar
                    if let validationMessage {
                        InlineWarning(text: validationMessage, tone: .warning)
                    }
                    undoBar
                    statsGrid(now: context.date)
                    entriesList(now: context.date)
                }
            }
        }
        .onAppear {
            let now = Date()
            customStartDate = clampedLiveStartDate(now)
            manualDate = min(max(now, timesheet.activeStartDate), timesheet.activeEndDate)
            manualStartTime = now
            manualEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        }
    }

    private func trackerHeader(now: Date) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space16) {
            HStack(spacing: FacioLayout.space12) {
                Picker("", selection: $inputMode) {
                    ForEach(TimeEntryInputMode.allCases) { mode in
                        Text(mode.label(for: lang)).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 210)

                Spacer()

                if let activeEntryInThisPeriod {
                    Text(DurationFormatter.clock(activeEntryInThisPeriod.duration(at: now)))
                        .font(FacioFont.clock)
                        .lineLimit(1)
                    Button {
                        dataStore.stopTimeEntry(activeEntryInThisPeriod, in: timesheet)
                    } label: {
                        Label(L10n.stopTimer(lang), systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.intentDanger)
                } else {
                    Text("00:00:00")
                        .font(FacioFont.clock)
                        .lineLimit(1)
                }
            }

            if inputMode == .manual, activeEntryInThisPeriod == nil {
                manualControls
            } else {
                timerControls(now: now)
            }

            if !canUseLiveTimerInPeriod {
                InlineWarning(text: L10n.timerOutsidePeriod(lang), tone: .warning)
            }

            if let activeContext, activeContext.timesheet.id != timesheet.id {
                InlineWarning(
                    text: L10n.timerRunningElsewhere(lang, period: activeContext.timesheet.title(for: lang)),
                    tone: .info
                )
            }
        }
    }

    private func timerControls(now: Date) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space12) {
            if let activeEntryInThisPeriod {
                entryFields(for: activeEntryInThisPeriod)
                if let liveStartDateRange {
                    HStack(spacing: FacioLayout.space12) {
                        Label(L10n.startDate(lang), systemImage: "clock.arrow.circlepath")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        DatePicker(
                            L10n.startDate(lang),
                            selection: runningStartDateBinding(for: activeEntryInThisPeriod),
                            in: liveStartDateRange,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .frame(maxWidth: 280)
                        Text(L10n.startedEarlierHint(lang))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            } else {
                inputFields
                HStack(spacing: FacioLayout.space12) {
                    Button {
                        startTimer()
                    } label: {
                        Label(L10n.startTimer(lang), systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canStartLiveTimer)

                    Toggle(L10n.startedEarlier(lang), isOn: $usesCustomStartDate)
                        .toggleStyle(.checkbox)
                    if usesCustomStartDate, let liveStartDateRange {
                        DatePicker(
                            L10n.startDate(lang),
                            selection: $customStartDate,
                            in: liveStartDateRange,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .frame(maxWidth: 280)
                    }
                    Spacer()
                }
                .onChange(of: usesCustomStartDate) { _, isEnabled in
                    if isEnabled {
                        customStartDate = clampedLiveStartDate(customStartDate)
                    }
                }
            }
        }
    }

    private var inputFields: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space10) {
            HStack(spacing: FacioLayout.space10) {
                TextField(L10n.timeEntryDescription(lang), text: $notes)
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.project(lang), text: $projectName)
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.task(lang), text: $taskName)
                    .textFieldStyle(.roundedBorder)
            }
            HStack(spacing: FacioLayout.space10) {
                TextField(L10n.tags(lang), text: $tagsText)
                    .textFieldStyle(.roundedBorder)
                Toggle(L10n.billable(lang), isOn: $isBillable)
                    .toggleStyle(.switch)
                Spacer()
            }
        }
    }

    private func entryFields(for entry: TimeEntry) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space10) {
            HStack(spacing: FacioLayout.space10) {
                TextField(L10n.timeEntryDescription(lang), text: entryStringBinding(entry, \.notes))
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.project(lang), text: entryStringBinding(entry, \.projectName))
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.task(lang), text: entryStringBinding(entry, \.taskName))
                    .textFieldStyle(.roundedBorder)
            }
            HStack(spacing: FacioLayout.space10) {
                TextField(L10n.tags(lang), text: entryStringBinding(entry, \.tagsText))
                    .textFieldStyle(.roundedBorder)
                Toggle(L10n.billable(lang), isOn: entryBoolBinding(entry, \.isBillable))
                    .toggleStyle(.switch)
                Spacer()
            }
        }
    }

    private var manualControls: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space12) {
            inputFields
            HStack(spacing: FacioLayout.space10) {
                DatePicker(
                    L10n.period(lang),
                    selection: $manualDate,
                    in: timesheet.activeStartDate...timesheet.activeEndDate,
                    displayedComponents: [.date]
                )
                .labelsHidden()
                DatePicker(L10n.startDate(lang), selection: $manualStartTime, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                DatePicker(L10n.endDate(lang), selection: $manualEndTime, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                TextField(L10n.duration(lang), text: $manualDurationInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 110)
                Button {
                    addManualEntry()
                } label: {
                    Label(L10n.addTimeEntry(lang), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            Text(L10n.durationExamples(lang))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var filterBar: some View {
        HStack(spacing: FacioLayout.space12) {
            Picker("", selection: $range) {
                ForEach(TimeEntryRange.allCases) { range in
                    Text(range.label(for: lang)).tag(range)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 260)

            TextField(L10n.searchTimeEntries(lang), text: $searchText)
                .textFieldStyle(.roundedBorder)

            Button {
                inputMode = .manual
            } label: {
                Label(L10n.newTimeEntry(lang), systemImage: "plus")
            }

            Button {
                exportCSV()
            } label: {
                Label(L10n.exportCSV(lang), systemImage: "square.and.arrow.down")
            }
            .disabled(filteredEntries.isEmpty)

            if let invoice = dataStore.existingBillableHoursInvoice(for: timesheet) {
                Button {
                    onOpenInvoice(invoice)
                } label: {
                    Label(L10n.openInvoice(lang), systemImage: "doc.text.magnifyingglass")
                }
            } else {
                Button {
                    if let invoice = dataStore.generateInvoiceFromUnbilledTimeEntries(from: timesheet, grouping: .detailed) {
                        onOpenInvoice(invoice)
                    }
                } label: {
                    Label(L10n.invoiceTimeEntries(lang), systemImage: "doc.text")
                }
                .disabled(!dataStore.canGenerateInvoiceFromTimeEntries(for: timesheet))
            }
        }
    }

    @ViewBuilder
    private var undoBar: some View {
        if let deletedUndo {
            HStack(spacing: FacioLayout.space10) {
                Label(L10n.entryDeleted(lang), systemImage: "trash")
                    .font(.subheadline)
                Button(L10n.undo(lang)) {
                    dataStore.restoreTimeEntry(deletedUndo.entry, in: timesheet)
                    self.deletedUndo = nil
                }
                Spacer()
            }
            .padding(FacioLayout.space10)
            .background(Color.intentWarning.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
        }
    }

    private func statsGrid(now: Date) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 220))], spacing: FacioLayout.space12) {
            MetricTile(
                title: L10n.today(lang),
                value: formatHours(totalDuration(for: periodEntries.filter { isToday($0) }, now: now)),
                systemImage: "calendar",
                color: .intentInfo
            )
            MetricTile(
                title: L10n.thisWeek(lang),
                value: formatHours(totalDuration(for: periodEntries.filter { isThisWeek($0) }, now: now)),
                systemImage: "calendar.badge.clock",
                color: .intentWarning
            )
            MetricTile(
                title: L10n.period(lang),
                value: formatHours(totalDuration(for: periodEntries, now: now)),
                systemImage: "clock",
                color: .intentSuccess
            )
            MetricTile(
                title: L10n.estimatedAmount(lang),
                value: dataStore.companyInfo.deviseParDefaut.formatAccounting(estimatedBillableAmount(now: now), lang: numberFormat),
                systemImage: "banknote",
                color: Color.appPrimary(from: dataStore.companyInfo)
            )
        }
    }

    @ViewBuilder
    private func entriesList(now: Date) -> some View {
        if filteredEntries.isEmpty {
            FacioEmptyState(
                title: L10n.noTimeEntries(lang),
                systemImage: "timer",
                message: L10n.noTimeEntriesHint(lang)
            )
            .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            VStack(alignment: .leading, spacing: FacioLayout.space12) {
                ForEach(groupedDateStrings, id: \.self) { dateString in
                    VStack(alignment: .leading, spacing: FacioLayout.space6) {
                        HStack {
                            Text(dateLabel(dateString))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text(DurationFormatter.clock(totalDuration(for: entries(for: dateString), now: now)))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        ForEach(entries(for: dateString)) { entry in
                            VStack(spacing: FacioLayout.space6) {
                                TimeEntryRow(
                                    entry: entry,
                                    now: now,
                                    lang: lang,
                                    numberFormat: numberFormat,
                                    clientName: timesheet.clientDisplayName,
                                    defaultRate: timesheet.tauxNormal,
                                    currency: dataStore.companyInfo.deviseParDefaut,
                                    canContinue: canStartLiveTimer
                                ) {
                                    editingEntryId = editingEntryId == entry.id ? nil : entry.id
                                } onContinue: {
                                    _ = dataStore.continueTimeEntry(entry, in: timesheet)
                                } onDelete: {
                                    deleteWithUndo(entry)
                                }

                                if editingEntryId == entry.id {
                                    TimeEntryInlineEditor(
                                        timesheet: timesheet,
                                        entry: entry,
                                        onClose: { editingEntryId = nil }
                                    )
                                    .environment(dataStore)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var groupedDateStrings: [String] {
        Array(Set(filteredEntries.map(\.dateString))).sorted(by: >)
    }

    private func entries(for dateString: String) -> [TimeEntry] {
        filteredEntries.filter { $0.dateString == dateString }
    }

    private func matchesRange(_ entry: TimeEntry) -> Bool {
        switch range {
        case .today:
            return isToday(entry)
        case .week:
            return isThisWeek(entry)
        case .period:
            return entry.dateString >= timesheet.activeStartDateString && entry.dateString <= timesheet.activeEndDateString
        }
    }

    private func matchesSearch(_ entry: TimeEntry) -> Bool {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        return entry.projectName.localizedCaseInsensitiveContains(needle)
            || entry.taskName.localizedCaseInsensitiveContains(needle)
            || entry.notes.localizedCaseInsensitiveContains(needle)
            || entry.tagsText.localizedCaseInsensitiveContains(needle)
    }

    private func isToday(_ entry: TimeEntry) -> Bool {
        entry.dateString == TimeEntry.dateString(for: Date())
    }

    private func isThisWeek(_ entry: TimeEntry) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        return calendar.isDate(entry.startedAt, equalTo: Date(), toGranularity: .weekOfYear)
            && calendar.isDate(entry.startedAt, equalTo: Date(), toGranularity: .yearForWeekOfYear)
    }

    private func totalDuration(for entries: [TimeEntry], now: Date) -> TimeInterval {
        entries.reduce(0) { $0 + $1.duration(at: now) }
    }

    private func estimatedBillableAmount(now: Date) -> Decimal {
        periodEntries.reduce(Decimal(0)) { total, entry in
            guard entry.isBillable else { return total }
            let hours = Decimal(entry.duration(at: now) / 3600)
            return total + hours * (entry.rateSnapshot ?? timesheet.tauxNormal)
        }
    }

    private func startTimer() {
        validationMessage = nil
        let startDate = usesCustomStartDate ? clampedLiveStartDate(customStartDate) : Date()
        let entry = dataStore.startTimeEntry(
            in: timesheet,
            projectName: projectName,
            taskName: taskName,
            notes: notes,
            tagsText: tagsText,
            isBillable: isBillable,
            at: startDate
        )
        guard entry != nil else {
            validationMessage = activeContext == nil ? L10n.timerOutsidePeriod(lang) : L10n.activeTimerExists(lang)
            return
        }
        taskName = ""
        notes = ""
        tagsText = ""
        usesCustomStartDate = false
        customStartDate = Date()
    }

    private func addManualEntry() {
        validationMessage = nil
        guard let startedAt = manualDateTime(from: manualStartTime) else {
            validationMessage = L10n.invalidTimeRange(lang)
            return
        }

        let endedAt: Date
        do {
            if manualDurationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                guard let end = manualDateTime(from: manualEndTime), end > startedAt else {
                    validationMessage = L10n.invalidTimeRange(lang)
                    return
                }
                endedAt = end
            } else {
                let seconds = try TimeTrackingService.parseDurationInput(manualDurationInput)
                endedAt = startedAt.addingTimeInterval(TimeInterval(seconds))
            }
        } catch {
            validationMessage = L10n.invalidDuration(lang)
            return
        }

        guard endedAt > startedAt else {
            validationMessage = L10n.invalidTimeRange(lang)
            return
        }

        let now = Date()
        let entry = TimeEntry(
            projectName: projectName,
            taskName: taskName,
            notes: notes,
            tagsText: tagsText,
            isBillable: isBillable,
            rateSnapshot: isBillable ? timesheet.tauxNormal : nil,
            currencySnapshot: isBillable ? dataStore.companyInfo.deviseParDefaut : nil,
            source: .manual,
            startedAt: startedAt,
            endedAt: endedAt,
            createdAt: now,
            updatedAt: now
        )
        dataStore.addTimeEntry(entry, to: timesheet)
        notes = ""
        taskName = ""
        tagsText = ""
        manualDurationInput = ""
        manualStartTime = endedAt
        manualEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: endedAt) ?? endedAt
    }

    private func manualDateTime(from time: Date) -> Date? {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        return TimeTrackingService.combine(date: manualDate, time: TimeOfDay(hour: hour, minute: minute))
    }

    private func exportCSV() {
        let csv = TimeTrackingService.csv(
            for: filteredEntries,
            timesheet: timesheet,
            lang: lang,
            numberFormat: numberFormat
        )
        guard let data = csv.data(using: .utf8) else { return }
        Task {
            _ = await ExportService.exportCSV(
                data: data,
                defaultFilename: "\(L10n.defaultCSVName(lang))-\(timesheet.activeStartDateString)-\(timesheet.activeEndDateString)",
                language: lang
            )
        }
    }

    private func deleteWithUndo(_ entry: TimeEntry) {
        dataStore.deleteTimeEntry(entry, from: timesheet)
        deletedUndo = DeletedTimeEntryUndo(id: entry.id, entry: entry)
        let deletedId = entry.id
        Task {
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            await MainActor.run {
                if deletedUndo?.id == deletedId {
                    deletedUndo = nil
                }
            }
        }
    }

    private func entryStringBinding(_ entry: TimeEntry, _ keyPath: ReferenceWritableKeyPath<TimeEntry, String>) -> Binding<String> {
        Binding(
            get: { entry[keyPath: keyPath] },
            set: { value in
                let previousAffectedDates = Set(entry.secondsByDate().keys)
                entry[keyPath: keyPath] = value
                dataStore.timeEntryUpdated(entry, in: timesheet, previousAffectedDateStrings: previousAffectedDates)
            }
        )
    }

    private func entryBoolBinding(_ entry: TimeEntry, _ keyPath: ReferenceWritableKeyPath<TimeEntry, Bool>) -> Binding<Bool> {
        Binding(
            get: { entry[keyPath: keyPath] },
            set: { value in
                let previousAffectedDates = Set(entry.secondsByDate().keys)
                entry[keyPath: keyPath] = value
                dataStore.timeEntryUpdated(entry, in: timesheet, previousAffectedDateStrings: previousAffectedDates)
            }
        )
    }

    private func formatHours(_ seconds: TimeInterval) -> String {
        let hours = Decimal(seconds / 3600)
        return "\(hours.formattedDecimal(maxFractionDigits: 2, for: numberFormat))h"
    }

    private func dateLabel(_ dateString: String) -> String {
        guard let date = TimesheetDay.dateFormatter.date(from: dateString) else { return dateString }
        return date.formattedDate(for: lang)
    }

    private func clampedLiveStartDate(_ date: Date) -> Date {
        guard let liveStartDateRange else { return Date() }
        return min(max(date, liveStartDateRange.lowerBound), liveStartDateRange.upperBound)
    }

    private func runningStartDateBinding(for entry: TimeEntry) -> Binding<Date> {
        Binding(
            get: { entry.startedAt },
            set: { newValue in
                dataStore.updateRunningTimeEntryStart(
                    entry,
                    in: timesheet,
                    startedAt: clampedLiveStartDate(newValue)
                )
            }
        )
    }

    private static func endOfDay(for date: Date) -> Date {
        Calendar(identifier: .gregorian).date(
            byAdding: DateComponents(day: 1, second: -1),
            to: date
        ) ?? date
    }
}

private struct TimeEntryRow: View {
    let entry: TimeEntry
    let now: Date
    let lang: AppLanguage
    let numberFormat: AppLanguage
    let clientName: String
    let defaultRate: Decimal
    let currency: CurrencyType
    let canContinue: Bool
    let onEdit: () -> Void
    let onContinue: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: FacioLayout.space12) {
            Image(systemName: entry.isRunning ? "timer" : "clock")
                .foregroundStyle(entry.isRunning ? Color.intentSuccess : .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: FacioLayout.space4) {
                Text(primaryTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: FacioLayout.space8) {
                    if !clientName.isEmpty {
                        Text(clientName)
                    }
                    if !entry.displayProject.isEmpty {
                        Text(entry.displayProject)
                    }
                    if !entry.displayTask.isEmpty {
                        Text(entry.displayTask)
                    }
                    Text(timeRange)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                HStack(spacing: FacioLayout.space6) {
                    statusBadge(entry.isBillable ? L10n.billable(lang) : L10n.nonBillable(lang), color: entry.isBillable ? .intentSuccess : .secondary)
                    statusBadge(entry.isInvoiced ? L10n.invoiced(lang) : L10n.notInvoiced(lang), color: entry.isInvoiced ? .intentSuccess : .intentWarning)
                    ForEach(entry.tags.prefix(4), id: \.self) { tag in
                        statusBadge(tag, color: .intentInfo)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit()
            }

            Spacer()

            VStack(alignment: .trailing, spacing: FacioLayout.space2) {
                Text(DurationFormatter.clock(entry.duration(at: now)))
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.semibold)
                if entry.isBillable {
                    Text(estimatedAmount)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit()
            }

            HStack(spacing: FacioLayout.space4) {
                FacioIconButton(
                    systemImage: "play.fill",
                    help: canContinue ? L10n.continueTimer(lang) : L10n.timerOutsidePeriod(lang),
                    isEnabled: !entry.isRunning && canContinue,
                    action: onContinue
                )
                FacioIconButton(
                    systemImage: "pencil",
                    help: L10n.editTimeEntry(lang),
                    action: onEdit
                )
                FacioIconButton(
                    systemImage: "trash",
                    tone: .intentDanger,
                    help: L10n.delete(lang),
                    isEnabled: !entry.isInvoiced,
                    action: onDelete
                )
            }
        }
        .padding(FacioLayout.space10)
        .background(Color.surfaceTile)
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
    }

    private var primaryTitle: String {
        if !entry.notes.isEmpty {
            return entry.notes
        }
        if !entry.displayTask.isEmpty {
            return entry.displayTask
        }
        if !entry.displayProject.isEmpty {
            return entry.displayProject
        }
        return L10n.untitledTask(lang)
    }

    private var timeRange: String {
        let start = entry.startedAt.formatted(date: .omitted, time: .shortened)
        guard let endedAt = entry.endedAt else { return "\(start) - \(L10n.now(lang))" }
        return "\(start) - \(endedAt.formatted(date: .omitted, time: .shortened))"
    }

    private var estimatedAmount: String {
        let hours = Decimal(entry.duration(at: now) / 3600)
        let amount = hours * (entry.rateSnapshot ?? defaultRate)
        return currency.formatAccounting(amount, lang: numberFormat)
    }

    private func statusBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, FacioLayout.space6)
            .padding(.vertical, FacioLayout.space4)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusBadge))
    }
}

private struct TimeEntryInlineEditor: View {
    let timesheet: TimesheetPeriod
    let entry: TimeEntry
    let onClose: () -> Void

    @Environment(DataStore.self) private var dataStore
    @State private var projectName: String
    @State private var taskName: String
    @State private var notes: String
    @State private var tagsText: String
    @State private var isBillable: Bool
    @State private var startedAt: Date
    @State private var endedAt: Date
    @State private var statusText: String?

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var editableDateRange: ClosedRange<Date> {
        Self.editableDateRange(for: timesheet)
    }

    init(timesheet: TimesheetPeriod, entry: TimeEntry, onClose: @escaping () -> Void) {
        self.timesheet = timesheet
        self.entry = entry
        self.onClose = onClose
        let range = Self.editableDateRange(for: timesheet)
        let start = Self.clamp(entry.startedAt, to: range)
        let defaultEnd = Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start
        let end = Self.clamp(entry.endedAt ?? defaultEnd, to: range)
        _projectName = State(initialValue: entry.projectName)
        _taskName = State(initialValue: entry.taskName)
        _notes = State(initialValue: entry.notes)
        _tagsText = State(initialValue: entry.tagsText)
        _isBillable = State(initialValue: entry.isBillable)
        _startedAt = State(initialValue: start)
        _endedAt = State(initialValue: max(start, end))
        _statusText = State(initialValue: nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space10) {
            HStack(spacing: FacioLayout.space10) {
                TextField(L10n.timeEntryDescription(lang), text: $notes)
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.project(lang), text: $projectName)
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.task(lang), text: $taskName)
                    .textFieldStyle(.roundedBorder)
            }
            HStack(spacing: FacioLayout.space10) {
                TextField(L10n.tags(lang), text: $tagsText)
                    .textFieldStyle(.roundedBorder)
                Toggle(L10n.billable(lang), isOn: $isBillable)
                    .toggleStyle(.switch)
                DatePicker(L10n.startDate(lang), selection: $startedAt, in: editableDateRange)
                    .labelsHidden()
                DatePicker(L10n.endDate(lang), selection: $endedAt, in: editableDateRange)
                    .labelsHidden()
                    .disabled(entry.isRunning)
            }
            HStack {
                if let statusText {
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(L10n.cancel(lang)) { onClose() }
                Button(L10n.save(lang)) {
                    save()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(FacioLayout.space10)
        .background(Color.surfaceField)
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
        .onChange(of: startedAt) { _, newStart in
            if endedAt < newStart {
                endedAt = newStart
            }
        }
        .onChange(of: endedAt) { _, newEnd in
            if newEnd < startedAt {
                startedAt = newEnd
            }
        }
    }

    private func save() {
        guard entry.isRunning || endedAt > startedAt else {
            statusText = L10n.invalidTimeRange(lang)
            return
        }

        let previousAffectedDates = Set(entry.secondsByDate().keys)
        entry.projectName = projectName
        entry.taskName = taskName
        entry.notes = notes
        entry.tagsText = tagsText
        entry.isBillable = isBillable
        entry.startedAt = startedAt
        if !entry.isRunning {
            entry.endedAt = endedAt
        }
        dataStore.timeEntryUpdated(entry, in: timesheet, previousAffectedDateStrings: previousAffectedDates)
        statusText = L10n.saved(lang)
    }

    private static func editableDateRange(for timesheet: TimesheetPeriod) -> ClosedRange<Date> {
        let endOfDay = Calendar(identifier: .gregorian).date(
            byAdding: DateComponents(day: 1, second: -1),
            to: timesheet.activeEndDate
        ) ?? timesheet.activeEndDate
        return timesheet.activeStartDate...endOfDay
    }

    private static func clamp(_ date: Date, to range: ClosedRange<Date>) -> Date {
        min(max(date, range.lowerBound), range.upperBound)
    }
}
