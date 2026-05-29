import SwiftUI

struct SharedTimerBarView: View {
    @Binding var selectedTimesheetId: UUID?

    @Environment(DataStore.self) private var dataStore
    @State private var projectName = ""
    @State private var taskName = ""
    @State private var notes = ""
    @State private var tagsText = ""
    @State private var isBillable = true
    @State private var usesCustomStartDate = false
    @State private var customStartDate = Date()
    @State private var validationMessage: String?

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var activeContext: RunningTimeEntryContext? {
        dataStore.runningTimeEntryContext
    }

    private var selectedTimesheet: TimesheetPeriod? {
        if let selectedTimesheetId,
           let timesheet = dataStore.timesheets.first(where: { $0.id == selectedTimesheetId }) {
            return timesheet
        }
        return preferredTimesheet
    }

    private var preferredTimesheet: TimesheetPeriod? {
        let today = TimeEntry.dateString(for: Date())
        return sortedTimesheets.first { $0.isBillableDateString(today) } ?? sortedTimesheets.first
    }

    private var sortedTimesheets: [TimesheetPeriod] {
        dataStore.timesheets.sorted {
            if $0.activeEndDateString != $1.activeEndDateString {
                return $0.activeEndDateString > $1.activeEndDateString
            }
            return $0.clientDisplayName.localizedCaseInsensitiveCompare($1.clientDisplayName) == .orderedAscending
        }
    }

    private var liveStartDateRange: ClosedRange<Date>? {
        guard let selectedTimesheet else { return nil }
        let now = Date()
        let endOfDay = Calendar(identifier: .gregorian).date(
            byAdding: DateComponents(day: 1, second: -1),
            to: selectedTimesheet.activeEndDate
        ) ?? selectedTimesheet.activeEndDate
        let upperBound = min(now, endOfDay)
        guard upperBound >= selectedTimesheet.activeStartDate else { return nil }
        return selectedTimesheet.activeStartDate...upperBound
    }

    var body: some View {
        SectionPanel(nil) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Label(L10n.timeTracker(lang), systemImage: "timer")
                            .font(.headline)
                        Spacer()
                        Text(formatClock(activeContext?.entry.duration(at: context.date) ?? 0))
                            .font(.system(size: 28, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                        if let activeContext {
                            Button {
                                dataStore.stopTimeEntry(activeContext.entry, in: activeContext.timesheet)
                            } label: {
                                Label(L10n.stopTimer(lang), systemImage: "stop.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .help(L10n.stopTimer(lang))
                        } else {
                            Button {
                                startTimer()
                            } label: {
                                Label(L10n.startTimer(lang), systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedTimesheet == nil || liveStartDateRange == nil)
                            .help(L10n.startTimer(lang))
                        }
                    }

                    if let activeContext {
                        activeTimerFields(context: activeContext)
                    } else {
                        startTimerFields
                    }

                    if let validationMessage {
                        InlineWarning(text: validationMessage, tone: .warning)
                    } else if selectedTimesheet == nil {
                        InlineWarning(text: L10n.noTrackingPeriod(lang), tone: .warning)
                    } else if liveStartDateRange == nil, activeContext == nil {
                        InlineWarning(text: L10n.timerOutsidePeriod(lang), tone: .warning)
                    }
                }
            }
        }
        .onAppear {
            if selectedTimesheetId == nil {
                selectedTimesheetId = preferredTimesheet?.id
            }
            customStartDate = clampedLiveStartDate(Date())
        }
    }

    private var startTimerFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Picker(L10n.selectTrackingPeriod(lang), selection: periodSelectionBinding) {
                    ForEach(sortedTimesheets) { timesheet in
                        Text(timesheet.title(for: lang)).tag(Optional(timesheet.id))
                    }
                }
                .frame(minWidth: 220)
                TextField(L10n.timeEntryDescription(lang), text: $notes)
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.project(lang), text: $projectName)
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.task(lang), text: $taskName)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 10) {
                TextField(L10n.tags(lang), text: $tagsText)
                    .textFieldStyle(.roundedBorder)
                Toggle(L10n.billable(lang), isOn: $isBillable)
                    .toggleStyle(.switch)
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
                    .frame(maxWidth: 260)
                }
                Spacer()
            }
        }
    }

    private func activeTimerFields(context: RunningTimeEntryContext) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(context.timesheet.title(for: lang))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 180, alignment: .leading)
                TextField(L10n.timeEntryDescription(lang), text: entryStringBinding(context, \.notes))
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.project(lang), text: entryStringBinding(context, \.projectName))
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.task(lang), text: entryStringBinding(context, \.taskName))
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 10) {
                TextField(L10n.tags(lang), text: entryStringBinding(context, \.tagsText))
                    .textFieldStyle(.roundedBorder)
                Toggle(L10n.billable(lang), isOn: entryBoolBinding(context, \.isBillable))
                    .toggleStyle(.switch)
                DatePicker(
                    L10n.startDate(lang),
                    selection: runningStartDateBinding(context),
                    in: context.timesheet.activeStartDate...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .frame(maxWidth: 260)
                Spacer()
            }
        }
    }

    private var periodSelectionBinding: Binding<UUID?> {
        Binding(
            get: { selectedTimesheet?.id },
            set: { selectedTimesheetId = $0 }
        )
    }

    private func startTimer() {
        validationMessage = nil
        guard let selectedTimesheet else {
            validationMessage = L10n.noTrackingPeriod(lang)
            return
        }
        guard dataStore.runningTimeEntryContext == nil else {
            validationMessage = L10n.activeTimerExists(lang)
            return
        }

        let startDate = usesCustomStartDate ? clampedLiveStartDate(customStartDate) : Date()
        let entry = dataStore.startTimeEntry(
            in: selectedTimesheet,
            projectName: projectName,
            taskName: taskName,
            notes: notes,
            tagsText: tagsText,
            isBillable: isBillable,
            at: startDate
        )

        guard entry != nil else {
            validationMessage = L10n.timerOutsidePeriod(lang)
            return
        }
        notes = ""
        taskName = ""
        tagsText = ""
        usesCustomStartDate = false
        customStartDate = Date()
    }

    private func entryStringBinding(
        _ context: RunningTimeEntryContext,
        _ keyPath: ReferenceWritableKeyPath<TimeEntry, String>
    ) -> Binding<String> {
        Binding(
            get: { context.entry[keyPath: keyPath] },
            set: { value in
                let previousAffectedDates = Set(context.entry.secondsByDate().keys)
                context.entry[keyPath: keyPath] = value
                dataStore.timeEntryUpdated(
                    context.entry,
                    in: context.timesheet,
                    previousAffectedDateStrings: previousAffectedDates
                )
            }
        )
    }

    private func entryBoolBinding(
        _ context: RunningTimeEntryContext,
        _ keyPath: ReferenceWritableKeyPath<TimeEntry, Bool>
    ) -> Binding<Bool> {
        Binding(
            get: { context.entry[keyPath: keyPath] },
            set: { value in
                let previousAffectedDates = Set(context.entry.secondsByDate().keys)
                context.entry[keyPath: keyPath] = value
                dataStore.timeEntryUpdated(
                    context.entry,
                    in: context.timesheet,
                    previousAffectedDateStrings: previousAffectedDates
                )
            }
        )
    }

    private func runningStartDateBinding(_ context: RunningTimeEntryContext) -> Binding<Date> {
        Binding(
            get: { context.entry.startedAt },
            set: { newValue in
                dataStore.updateRunningTimeEntryStart(
                    context.entry,
                    in: context.timesheet,
                    startedAt: min(max(newValue, context.timesheet.activeStartDate), Date())
                )
            }
        )
    }

    private func clampedLiveStartDate(_ date: Date) -> Date {
        guard let liveStartDateRange else { return Date() }
        return min(max(date, liveStartDateRange.lowerBound), liveStartDateRange.upperBound)
    }

    private func formatClock(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded(.down)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
