import Foundation

enum TimesheetInvoiceDetailMode: String, CaseIterable, Identifiable {
    case summary
    case daily
    case dailyActivity

    var id: String { rawValue }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .summary:
            return L10n.invoiceSummaryMode(lang)
        case .daily:
            return L10n.invoiceDailyMode(lang)
        case .dailyActivity:
            return L10n.invoiceDailyActivityMode(lang)
        }
    }
}

struct TimesheetDailyInvoiceAllocation: Hashable {
    var day: TimesheetDay
    var normalHours: Decimal
    var overtimeHours: Decimal
}

private struct TimesheetActivityInvoiceSlice {
    var activity: String?
    var hours: Decimal
}

struct TimesheetInvoiceService {
    private static let minimumInvoiceActivityHours = Decimal(string: "0.001")!

    static func lineItems(
        for timesheet: TimesheetPeriod,
        company: CompanyInfo,
        invoiceLanguage: AppLanguage,
        detailMode: TimesheetInvoiceDetailMode,
        adjacentHours: [String: Decimal]
    ) -> [LineItem] {
        switch detailMode {
        case .summary:
            return summaryLineItems(
                for: timesheet,
                company: company,
                invoiceLanguage: invoiceLanguage,
                adjacentHours: adjacentHours
            )
        case .daily:
            return dailyLineItems(
                for: timesheet,
                company: company,
                invoiceLanguage: invoiceLanguage,
                adjacentHours: adjacentHours
            )
        case .dailyActivity:
            return dailyActivityLineItems(
                for: timesheet,
                company: company,
                invoiceLanguage: invoiceLanguage,
                adjacentHours: adjacentHours
            )
        }
    }

    static func summaryLineItems(
        for timesheet: TimesheetPeriod,
        company: CompanyInfo,
        invoiceLanguage: AppLanguage,
        adjacentHours: [String: Decimal]
    ) -> [LineItem] {
        let heuresNorm = timesheet.totalHeuresNormalesCrossPeriod(adjacentHours: adjacentHours)
        let heuresSup = timesheet.totalHeuresSupCrossPeriod(adjacentHours: adjacentHours)
        let periodLabel = timesheet.periodLabel(for: invoiceLanguage)
        let workDesignation = timesheet.isCustomRange
            ? L10n.workHoursForPeriod(invoiceLanguage, period: periodLabel)
            : L10n.workHours(invoiceLanguage)
        let overtimeDesignation = timesheet.isCustomRange
            ? L10n.overtimeForPeriod(invoiceLanguage, period: periodLabel)
            : L10n.overtimeLabel(invoiceLanguage)
        var lineItems: [LineItem] = []

        if heuresNorm > 0 {
            lineItems.append(LineItem(
                designation: workDesignation,
                quantite: heuresNorm,
                prixUnitaire: timesheet.tauxNormal,
                tauxTVA: company.tauxTVAParDefaut,
                ordre: lineItems.count
            ))
        }

        if heuresSup > 0 {
            lineItems.append(LineItem(
                designation: overtimeDesignation,
                quantite: heuresSup,
                prixUnitaire: timesheet.tauxSupplementaire,
                tauxTVA: company.tauxTVAParDefaut,
                ordre: lineItems.count
            ))
        }

        return lineItems
    }

    static func dailyAllocations(
        for timesheet: TimesheetPeriod,
        adjacentHours: [String: Decimal]
    ) -> [TimesheetDailyInvoiceAllocation] {
        var allocations: [TimesheetDailyInvoiceAllocation] = []

        for week in timesheet.semaines {
            var hoursBeforeDay: Decimal = 0

            for day in week.jours {
                let dayHours = timesheet.isBillableDay(day)
                    ? day.heures
                    : adjacentHours[day.dateString] ?? 0

                defer {
                    hoursBeforeDay += dayHours
                }

                guard timesheet.isBillableDay(day), dayHours > 0 else { continue }

                let remainingNormalHours = max(timesheet.seuilHebdo - hoursBeforeDay, 0)
                let normalHours = min(dayHours, remainingNormalHours)
                let overtimeHours = dayHours - normalHours

                allocations.append(TimesheetDailyInvoiceAllocation(
                    day: day,
                    normalHours: normalHours,
                    overtimeHours: overtimeHours
                ))
            }
        }

        return allocations
    }

    private static func dailyLineItems(
        for timesheet: TimesheetPeriod,
        company: CompanyInfo,
        invoiceLanguage: AppLanguage,
        adjacentHours: [String: Decimal]
    ) -> [LineItem] {
        var lineItems: [LineItem] = []
        let shouldSplitOvertime = timesheet.tauxNormal != timesheet.tauxSupplementaire

        for week in timesheet.semaines {
            var hoursBeforeDay: Decimal = 0
            var weeklyOvertimeHours: Decimal = 0

            for day in week.jours {
                let dayHours = timesheet.isBillableDay(day)
                    ? day.heures
                    : adjacentHours[day.dateString] ?? 0

                defer {
                    hoursBeforeDay += dayHours
                }

                guard timesheet.isBillableDay(day), dayHours > 0 else { continue }

                let remainingNormalHours = max(timesheet.seuilHebdo - hoursBeforeDay, 0)
                let normalHours = min(dayHours, remainingNormalHours)
                let overtimeHours = dayHours - normalHours
                let billedDayHours = shouldSplitOvertime ? normalHours : dayHours

                if billedDayHours > 0 {
                    lineItems.append(LineItem(
                        designation: L10n.workHoursOnDate(invoiceLanguage, date: day.date.formattedDate(for: invoiceLanguage)),
                        quantite: billedDayHours,
                        prixUnitaire: timesheet.tauxNormal,
                        tauxTVA: company.tauxTVAParDefaut,
                        ordre: lineItems.count
                    ))
                }

                if shouldSplitOvertime {
                    weeklyOvertimeHours += overtimeHours
                }
            }

            if shouldSplitOvertime, weeklyOvertimeHours > 0 {
                lineItems.append(LineItem(
                    designation: L10n.overtimeHoursForWeek(
                        invoiceLanguage,
                        dateRange: weekRangeLabel(week, lang: invoiceLanguage)
                    ),
                    quantite: weeklyOvertimeHours,
                    prixUnitaire: timesheet.tauxSupplementaire,
                    tauxTVA: company.tauxTVAParDefaut,
                    ordre: lineItems.count
                ))
            }
        }

        return lineItems
    }

    private static func dailyActivityLineItems(
        for timesheet: TimesheetPeriod,
        company: CompanyInfo,
        invoiceLanguage: AppLanguage,
        adjacentHours: [String: Decimal]
    ) -> [LineItem] {
        var lineItems: [LineItem] = []
        let shouldSplitOvertime = timesheet.tauxNormal != timesheet.tauxSupplementaire

        for week in timesheet.semaines {
            var hoursBeforeDay: Decimal = 0

            for day in week.jours {
                let dayHours = timesheet.isBillableDay(day)
                    ? day.heures
                    : adjacentHours[day.dateString] ?? 0

                defer {
                    hoursBeforeDay += dayHours
                }

                guard timesheet.isBillableDay(day), dayHours > 0 else { continue }

                let slices = activitySlices(for: day, in: timesheet, maxHours: dayHours)
                var remainingNormalHours = max(timesheet.seuilHebdo - hoursBeforeDay, 0)

                for slice in slices {
                    let normalHours = shouldSplitOvertime ? min(slice.hours, remainingNormalHours) : slice.hours
                    let overtimeHours = shouldSplitOvertime ? slice.hours - normalHours : 0
                    let dateLabel = day.date.formattedDate(for: invoiceLanguage)

                    if isInvoiceableActivityHours(normalHours) {
                        lineItems.append(LineItem(
                            designation: workHoursDesignation(
                                lang: invoiceLanguage,
                                date: dateLabel,
                                activity: slice.activity
                            ),
                            quantite: normalHours,
                            prixUnitaire: timesheet.tauxNormal,
                            tauxTVA: company.tauxTVAParDefaut,
                            ordre: lineItems.count
                        ))
                    }

                    if isInvoiceableActivityHours(overtimeHours) {
                        lineItems.append(LineItem(
                            designation: overtimeHoursDesignation(
                                lang: invoiceLanguage,
                                date: dateLabel,
                                activity: slice.activity
                            ),
                            quantite: overtimeHours,
                            prixUnitaire: timesheet.tauxSupplementaire,
                            tauxTVA: company.tauxTVAParDefaut,
                            ordre: lineItems.count
                        ))
                    }

                    remainingNormalHours = max(remainingNormalHours - normalHours, 0)
                }
            }
        }

        return lineItems
    }

    private static func activitySlices(
        for day: TimesheetDay,
        in timesheet: TimesheetPeriod,
        maxHours: Decimal
    ) -> [TimesheetActivityInvoiceSlice] {
        let entries = timesheet.timeEntries
            .filter { !$0.isDeleted && $0.dateString == day.dateString && $0.durationHours() > 0 }
            .sorted { $0.startedAt < $1.startedAt }

        var slices: [TimesheetActivityInvoiceSlice] = []
        var consumedHours: Decimal = 0

        for entry in entries {
            let remainingHours = max(maxHours - consumedHours, 0)
            guard isInvoiceableActivityHours(remainingHours) else { break }

            let entryHours = min(entry.durationHours(), remainingHours)
            guard isInvoiceableActivityHours(entryHours) else { continue }

            appendActivitySlice(
                &slices,
                activity: activityTitle(for: entry),
                hours: entryHours
            )
            consumedHours += entryHours
        }

        let remainingHours = max(maxHours - consumedHours, 0)
        if isInvoiceableActivityHours(remainingHours) {
            appendActivitySlice(&slices, activity: nil, hours: remainingHours)
        }

        return slices
    }

    private static func appendActivitySlice(
        _ slices: inout [TimesheetActivityInvoiceSlice],
        activity: String?,
        hours: Decimal
    ) {
        guard isInvoiceableActivityHours(hours) else { return }
        if let last = slices.indices.last, slices[last].activity == activity {
            slices[last].hours += hours
        } else {
            slices.append(TimesheetActivityInvoiceSlice(activity: activity, hours: hours))
        }
    }

    private static func activityTitle(for entry: TimeEntry) -> String? {
        let title = [entry.notes, entry.displayProject, entry.displayTask]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
        return title.isEmpty ? nil : title
    }

    private static func isInvoiceableActivityHours(_ hours: Decimal) -> Bool {
        hours >= minimumInvoiceActivityHours
    }

    private static func workHoursDesignation(lang: AppLanguage, date: String, activity: String?) -> String {
        guard let activity else {
            return L10n.workHoursOnDate(lang, date: date)
        }
        return L10n.workHoursOnDateWithActivity(lang, date: date, activity: activity)
    }

    private static func overtimeHoursDesignation(lang: AppLanguage, date: String, activity: String?) -> String {
        guard let activity else {
            return L10n.overtimeHoursOnDate(lang, date: date)
        }
        return L10n.overtimeHoursOnDateWithActivity(lang, date: date, activity: activity)
    }

    private static func weekRangeLabel(_ week: TimesheetWeek, lang: AppLanguage) -> String {
        guard let first = week.jours.first, let last = week.jours.last else {
            return L10n.week(lang, number: week.numero)
        }
        return "\(first.date.formattedDate(for: lang)) - \(last.date.formattedDate(for: lang))"
    }
}
