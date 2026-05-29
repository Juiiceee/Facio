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

struct TimeTrackerPanel: View {
    let timesheet: TimesheetPeriod

    @Environment(DataStore.self) private var dataStore
    @State private var projectName = ""
    @State private var taskName = ""
    @State private var notes = ""
    @State private var usesCustomStartDate = false
    @State private var customStartDate = Date()
    @State private var range: TimeEntryRange = .period
    @State private var searchText = ""
    @State private var editingEntry: TimeEntry?
    @State private var showEntrySheet = false

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
        let entries = timesheet.timeEntries.filter { entry in
            matchesRange(entry) && matchesSearch(entry)
        }
        return entries.sorted { $0.startedAt > $1.startedAt }
    }

    private var periodEntries: [TimeEntry] {
        timesheet.timeEntries.sorted { $0.startedAt > $1.startedAt }
    }

    private var canStartLiveTimer: Bool {
        liveStartDateRange != nil
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
                VStack(alignment: .leading, spacing: 16) {
                    timerControls(now: context.date)
                    Divider()
                    filterBar
                    statsGrid(now: context.date)
                    entriesList(now: context.date)
                }
            }
        }
        .sheet(isPresented: $showEntrySheet) {
            TimeEntryEditSheet(timesheet: timesheet, entry: editingEntry)
                .environment(dataStore)
        }
        .onAppear {
            customStartDate = clampedLiveStartDate(Date())
        }
    }

    private func timerControls(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    if let activeEntryInThisPeriod {
                        Button {
                            editingEntry = activeEntryInThisPeriod
                            showEntrySheet = true
                        } label: {
                            Text(formatClock(activeEntryInThisPeriod.duration(at: now)))
                                .font(.system(size: 34, weight: .semibold, design: .monospaced))
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                        .help(L10n.editStartTime(lang))
                    } else {
                        Text("00:00:00")
                            .font(.system(size: 34, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                    }
                    Text(activeEntryInThisPeriod == nil ? L10n.readyToTrack(lang) : L10n.timerRunning(lang))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let activeEntryInThisPeriod {
                    Button {
                        dataStore.stopTimeEntry(activeEntryInThisPeriod, in: timesheet)
                    } label: {
                        Label(L10n.stopTimer(lang), systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button {
                        let startDate = usesCustomStartDate ? clampedLiveStartDate(customStartDate) : Date()
                        _ = dataStore.startTimeEntry(
                            in: timesheet,
                            projectName: projectName,
                            taskName: taskName,
                            notes: notes,
                            at: startDate
                        )
                        taskName = ""
                        notes = ""
                        usesCustomStartDate = false
                        customStartDate = Date()
                    } label: {
                        Label(L10n.startTimer(lang), systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        && taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        && timesheet.clientDisplayName.isEmpty
                        || !canStartLiveTimer)
                }
            }

            if !canStartLiveTimer {
                InlineWarning(text: L10n.timerOutsidePeriod(lang), tone: .warning)
            }

            if let activeContext, activeContext.timesheet.id != timesheet.id {
                InlineWarning(
                    text: L10n.timerRunningElsewhere(lang, period: activeContext.timesheet.title(for: lang)),
                    tone: .info
                )
            }

            HStack(spacing: 10) {
                TextField(L10n.project(lang), text: $projectName)
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.task(lang), text: $taskName)
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.notes(lang), text: $notes)
                    .textFieldStyle(.roundedBorder)
            }

            if let activeEntryInThisPeriod, let liveStartDateRange {
                HStack(spacing: 12) {
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
            } else if let liveStartDateRange {
                HStack(spacing: 12) {
                    Toggle(L10n.startedEarlier(lang), isOn: $usesCustomStartDate)
                        .toggleStyle(.checkbox)
                    if usesCustomStartDate {
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

    private var filterBar: some View {
        HStack(spacing: 12) {
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
                editingEntry = nil
                showEntrySheet = true
            } label: {
                Label(L10n.newTimeEntry(lang), systemImage: "plus")
            }
        }
    }

    private func statsGrid(now: Date) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 220))], spacing: 12) {
            MetricTile(
                title: L10n.today(lang),
                value: formatHours(totalDuration(for: periodEntries.filter { isToday($0) }, now: now)),
                systemImage: "calendar",
                color: .blue
            )
            MetricTile(
                title: L10n.thisWeek(lang),
                value: formatHours(totalDuration(for: periodEntries.filter { isThisWeek($0) }, now: now)),
                systemImage: "calendar.badge.clock",
                color: .orange
            )
            MetricTile(
                title: L10n.period(lang),
                value: formatHours(totalDuration(for: periodEntries, now: now)),
                systemImage: "clock",
                color: .green
            )
            MetricTile(
                title: L10n.entries(lang),
                value: "\(periodEntries.count)",
                systemImage: "list.bullet.rectangle",
                color: .purple
            )
        }
    }

    @ViewBuilder
    private func entriesList(now: Date) -> some View {
        if filteredEntries.isEmpty {
            ContentUnavailableView(
                L10n.noTimeEntries(lang),
                systemImage: "timer",
                description: Text(L10n.noTimeEntriesHint(lang))
            )
            .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(groupedDateStrings, id: \.self) { dateString in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dateLabel(dateString))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        ForEach(entries(for: dateString)) { entry in
                            TimeEntryRow(entry: entry, now: now, lang: lang, canContinue: canStartLiveTimer) {
                                editingEntry = entry
                                showEntrySheet = true
                            } onContinue: {
                                _ = dataStore.continueTimeEntry(entry, in: timesheet)
                            } onDelete: {
                                dataStore.deleteTimeEntry(entry, from: timesheet)
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

    private func formatHours(_ seconds: TimeInterval) -> String {
        let hours = Decimal(seconds / 3600)
        return "\(hours.formattedDecimal(maxFractionDigits: 2, for: numberFormat))h"
    }

    private func formatClock(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded(.down)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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
    let canContinue: Bool
    let onEdit: () -> Void
    let onContinue: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: entry.isRunning ? "timer" : "clock")
                    .foregroundStyle(entry.isRunning ? .green : .secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.displayTask.isEmpty ? L10n.untitledTask(lang) : entry.displayTask)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        if !entry.displayProject.isEmpty {
                            Text(entry.displayProject)
                        }
                        Text(timeRange)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    if !entry.notes.isEmpty {
                        Text(entry.notes)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onEdit()
                }
            }

            Spacer()

            Text(formatClock(entry.duration(at: now)))
                .font(.subheadline.monospacedDigit())
                .fontWeight(.semibold)
                .contentShape(Rectangle())
                .onTapGesture {
                    onEdit()
                }

            HStack(spacing: 4) {
                Button {
                    onContinue()
                } label: {
                    Image(systemName: "play.fill")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .help(canContinue ? L10n.continueTimer(lang) : L10n.timerOutsidePeriod(lang))
                .disabled(entry.isRunning || !canContinue)

                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .help(L10n.editTimeEntry(lang))

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .help(L10n.delete(lang))
            }
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.panelRadius))
        .contextMenu {
            Button {
                onContinue()
            } label: {
                Label(L10n.continueTimer(lang), systemImage: "play.fill")
            }
            .disabled(entry.isRunning || !canContinue)
            Button {
                onEdit()
            } label: {
                Label(L10n.editTimeEntry(lang), systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(L10n.delete(lang), systemImage: "trash")
            }
        }
    }

    private var timeRange: String {
        let start = entry.startedAt.formatted(date: .omitted, time: .shortened)
        guard let endedAt = entry.endedAt else { return "\(start) - \(L10n.now(lang))" }
        return "\(start) - \(endedAt.formatted(date: .omitted, time: .shortened))"
    }

    private func formatClock(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded(.down)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

private struct TimeEntryEditSheet: View {
    let timesheet: TimesheetPeriod
    let entry: TimeEntry?

    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore

    @State private var projectName: String
    @State private var taskName: String
    @State private var notes: String
    @State private var startedAt: Date
    @State private var endedAt: Date

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var editableDateRange: ClosedRange<Date> {
        Self.editableDateRange(for: timesheet)
    }

    init(timesheet: TimesheetPeriod, entry: TimeEntry?) {
        self.timesheet = timesheet
        self.entry = entry
        let range = Self.editableDateRange(for: timesheet)
        let start = Self.clamp(entry?.startedAt ?? Date(), to: range)
        let defaultEnd = Calendar.current.date(byAdding: .hour, value: 1, to: start) ?? start
        let end = Self.clamp(entry?.endedAt ?? defaultEnd, to: range)
        _projectName = State(initialValue: entry?.projectName ?? "")
        _taskName = State(initialValue: entry?.taskName ?? "")
        _notes = State(initialValue: entry?.notes ?? "")
        _startedAt = State(initialValue: start)
        _endedAt = State(initialValue: max(start, end))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(entry == nil ? L10n.newTimeEntry(lang) : L10n.editTimeEntry(lang), systemImage: "timer")
                    .font(.headline)
                Spacer()
                Button(L10n.close(lang)) { dismiss() }
            }

            TextField(L10n.project(lang), text: $projectName)
                .textFieldStyle(.roundedBorder)
            TextField(L10n.task(lang), text: $taskName)
                .textFieldStyle(.roundedBorder)
            TextField(L10n.notes(lang), text: $notes)
                .textFieldStyle(.roundedBorder)

            DatePicker(L10n.startDate(lang), selection: $startedAt, in: editableDateRange)
            DatePicker(L10n.endDate(lang), selection: $endedAt, in: editableDateRange)
                .disabled(entry?.isRunning == true)

            HStack {
                Spacer()
                Button(L10n.cancel(lang)) { dismiss() }
                Button(L10n.save(lang)) {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 440)
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
        let normalizedEnd = max(startedAt, endedAt)
        if let entry {
            let previousAffectedDates = Set(entry.secondsByDate().keys)
            entry.projectName = projectName
            entry.taskName = taskName
            entry.notes = notes
            entry.startedAt = startedAt
            if !entry.isRunning {
                entry.endedAt = normalizedEnd
            }
            dataStore.timeEntryUpdated(entry, in: timesheet, previousAffectedDateStrings: previousAffectedDates)
        } else {
            let now = Date()
            let newEntry = TimeEntry(
                projectName: projectName,
                taskName: taskName,
                notes: notes,
                startedAt: startedAt,
                endedAt: normalizedEnd,
                createdAt: now,
                updatedAt: now
            )
            dataStore.addTimeEntry(newEntry, to: timesheet)
        }
        dismiss()
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
