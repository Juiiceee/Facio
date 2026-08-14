import Foundation

/// Géométrie d'une grille de mois à 7 colonnes, semaine commençant le lundi.
///
/// Sans décalage de tête, une grille de 7 colonnes remplie séquentiellement
/// depuis le 1er ne dit rien : chaque colonne change de jour de la semaine d'un
/// mois à l'autre, alors que la forme se lit sans ambiguïté comme un calendrier.
enum MonthGrid {
    /// Le calendrier de référence, aligné sur le reste de l'app (lundi d'abord).
    static func calendar(_ base: Calendar = .current) -> Calendar {
        var cal = base
        cal.firstWeekday = 2
        return cal
    }

    /// Nombre de cases vides à poser avant le 1er du mois.
    static func leadingBlanks(monthStart: Date, calendar base: Calendar = .current) -> Int {
        let cal = calendar(base)
        let weekday = cal.component(.weekday, from: monthStart)
        return (weekday - cal.firstWeekday + 7) % 7
    }

    /// Initiales des jours dans l'ordre de la grille (lundi en premier).
    static func weekdaySymbols(calendar base: Calendar = .current) -> [String] {
        let cal = calendar(base)
        let symbols = cal.veryShortWeekdaySymbols
        guard symbols.count == 7 else { return symbols }
        let offset = cal.firstWeekday - 1
        return Array(symbols[offset...] + symbols[..<offset])
    }
}

enum TimeHubPeriodMode: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    func interval(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        var cal = calendar
        cal.firstWeekday = 2
        switch self {
        case .day:
            let start = cal.startOfDay(for: date)
            let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
            return DateInterval(start: start, end: end)
        case .week:
            return cal.dateInterval(of: .weekOfYear, for: date)
                ?? TimeHubPeriodMode.day.interval(containing: date, calendar: cal)
        case .month:
            return cal.dateInterval(of: .month, for: date)
                ?? TimeHubPeriodMode.day.interval(containing: date, calendar: cal)
        }
    }

    func shiftedAnchor(from date: Date, value: Int, calendar: Calendar = .current) -> Date {
        switch self {
        case .day:
            return calendar.date(byAdding: .day, value: value, to: date) ?? date
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: value, to: date) ?? date
        case .month:
            return calendar.date(byAdding: .month, value: value, to: date) ?? date
        }
    }
}

struct TimeTrackingFilters: Equatable {
    var clientId: UUID?
    var billable: Bool?
    var invoiced: Bool?
    var searchText: String = ""
}

struct TimeHubEntryContext: Identifiable {
    let timesheet: TimesheetPeriod
    let entry: TimeEntry

    var id: UUID { entry.id }
    var clientName: String { timesheet.clientDisplayName }
    var rate: Decimal { entry.rateSnapshot ?? timesheet.tauxNormal }
    var currency: CurrencyType { entry.currencySnapshot ?? .eur }

    func durationSeconds(at now: Date) -> Int {
        max(0, Int(entry.duration(at: now).rounded(.down)))
    }

    func estimatedAmount(at now: Date) -> Decimal {
        guard entry.isBillable else { return 0 }
        return Decimal(durationSeconds(at: now)) / Decimal(3600) * rate
    }
}

struct TimeHubStats {
    var totalSeconds: Int = 0
    var billableSeconds: Int = 0
    var nonBillableSeconds: Int = 0
    var invoicedSeconds: Int = 0
    var uninvoicedSeconds: Int = 0
    var estimatedAmount: Decimal = 0
    var entriesCount: Int = 0
    var activeTasksCount: Int = 0
}

struct TimeHubDayGroup: Identifiable {
    let id: String
    let date: Date
    let contexts: [TimeHubEntryContext]
    let stats: TimeHubStats
}

struct TimeHubClientGroup: Identifiable {
    let id: String
    let clientId: UUID?
    let clientName: String
    let contexts: [TimeHubEntryContext]
    let stats: TimeHubStats
}

struct TimeHubProjectGroup: Identifiable {
    let id: String
    let projectName: String
    let clientName: String
    let contexts: [TimeHubEntryContext]
    let stats: TimeHubStats
}

struct TimeHubTaskGroup: Identifiable {
    let id: String
    let title: String
    let projectName: String
    let clientName: String
    let contexts: [TimeHubEntryContext]
    let stats: TimeHubStats
}

enum TimeHubAggregationService {
    static func allContexts(from timesheets: [TimesheetPeriod]) -> [TimeHubEntryContext] {
        timesheets.flatMap { timesheet in
            timesheet.timeEntries
                .filter { !$0.isDeleted }
                .map { TimeHubEntryContext(timesheet: timesheet, entry: $0) }
        }
    }

    static func contexts(
        from timesheets: [TimesheetPeriod],
        in interval: DateInterval,
        filters: TimeTrackingFilters,
        now: Date
    ) -> [TimeHubEntryContext] {
        allContexts(from: timesheets)
            .filter { context in
                isInInterval(context.entry, interval: interval, now: now)
                    && matches(context, filters: filters)
            }
            .sorted { $0.entry.startedAt > $1.entry.startedAt }
    }

    static func stats(for contexts: [TimeHubEntryContext], now: Date) -> TimeHubStats {
        var stats = TimeHubStats()
        stats.entriesCount = contexts.count
        stats.activeTasksCount = contexts.filter { $0.entry.isRunning }.count

        for context in contexts {
            let seconds = context.durationSeconds(at: now)
            stats.totalSeconds += seconds
            if context.entry.isBillable {
                stats.billableSeconds += seconds
                stats.estimatedAmount += context.estimatedAmount(at: now)
                if context.entry.isInvoiced {
                    stats.invoicedSeconds += seconds
                } else {
                    stats.uninvoicedSeconds += seconds
                }
            } else {
                stats.nonBillableSeconds += seconds
            }
        }
        return stats
    }

    static func dayGroups(for contexts: [TimeHubEntryContext], now: Date) -> [TimeHubDayGroup] {
        let grouped = Dictionary(grouping: contexts) { $0.entry.dateString }
        return grouped
            .compactMap { dateString, contexts -> TimeHubDayGroup? in
                guard let date = TimesheetDay.dateFormatter.date(from: dateString) else { return nil }
                let sorted = contexts.sorted { $0.entry.startedAt < $1.entry.startedAt }
                return TimeHubDayGroup(
                    id: dateString,
                    date: date,
                    contexts: sorted,
                    stats: stats(for: sorted, now: now)
                )
            }
            .sorted { $0.id > $1.id }
    }

    static func clientGroups(for contexts: [TimeHubEntryContext], now: Date) -> [TimeHubClientGroup] {
        let grouped = Dictionary(grouping: contexts) { context in
            context.timesheet.clientId?.uuidString ?? context.clientName
        }
        return grouped.map { key, contexts in
            let first = contexts[0]
            return TimeHubClientGroup(
                id: key.isEmpty ? "none" : key,
                clientId: first.timesheet.clientId,
                clientName: first.clientName,
                contexts: contexts,
                stats: stats(for: contexts, now: now)
            )
        }
        .sorted { $0.stats.totalSeconds > $1.stats.totalSeconds }
    }

    static func projectGroups(for contexts: [TimeHubEntryContext], now: Date) -> [TimeHubProjectGroup] {
        let grouped = Dictionary(grouping: contexts) { context in
            context.entry.displayProject.isEmpty ? context.clientName : context.entry.displayProject
        }
        return grouped.map { projectName, contexts in
            let first = contexts[0]
            return TimeHubProjectGroup(
                id: projectName.isEmpty ? "none" : projectName,
                projectName: projectName,
                clientName: first.clientName,
                contexts: contexts,
                stats: stats(for: contexts, now: now)
            )
        }
        .sorted { $0.stats.totalSeconds > $1.stats.totalSeconds }
    }

    static func taskGroups(for contexts: [TimeHubEntryContext], now: Date) -> [TimeHubTaskGroup] {
        let grouped = Dictionary(grouping: contexts) { context in
            taskTitle(for: context.entry)
        }
        return grouped.map { title, contexts in
            let first = contexts.sorted { $0.entry.startedAt > $1.entry.startedAt }[0]
            return TimeHubTaskGroup(
                id: title,
                title: title,
                projectName: first.entry.displayProject,
                clientName: first.clientName,
                contexts: contexts,
                stats: stats(for: contexts, now: now)
            )
        }
        .sorted { $0.stats.totalSeconds > $1.stats.totalSeconds }
    }

    static func taskTitle(for entry: TimeEntry) -> String {
        if !entry.displayTask.isEmpty { return entry.displayTask }
        if !entry.notes.isEmpty { return entry.notes }
        if !entry.displayProject.isEmpty { return entry.displayProject }
        return "untitled"
    }

    private static func isInInterval(_ entry: TimeEntry, interval: DateInterval, now: Date) -> Bool {
        let end = entry.endedAt ?? now
        return entry.startedAt < interval.end && end >= interval.start
    }

    private static func matches(_ context: TimeHubEntryContext, filters: TimeTrackingFilters) -> Bool {
        if let clientId = filters.clientId, context.timesheet.clientId != clientId {
            return false
        }
        if let billable = filters.billable, context.entry.isBillable != billable {
            return false
        }
        if let invoiced = filters.invoiced, context.entry.isInvoiced != invoiced {
            return false
        }

        let search = filters.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return true }
        return context.clientName.localizedCaseInsensitiveContains(search)
            || context.entry.projectName.localizedCaseInsensitiveContains(search)
            || context.entry.taskName.localizedCaseInsensitiveContains(search)
            || context.entry.notes.localizedCaseInsensitiveContains(search)
            || context.entry.tagsText.localizedCaseInsensitiveContains(search)
    }
}
