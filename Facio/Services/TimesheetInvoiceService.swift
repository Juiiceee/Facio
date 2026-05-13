import Foundation

enum TimesheetInvoiceDetailMode: String, CaseIterable, Identifiable {
    case summary
    case daily

    var id: String { rawValue }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .summary:
            return L10n.invoiceSummaryMode(lang)
        case .daily:
            return L10n.invoiceDailyMode(lang)
        }
    }
}

struct TimesheetDailyInvoiceAllocation: Hashable {
    var day: TimesheetDay
    var normalHours: Decimal
    var overtimeHours: Decimal
}

struct TimesheetInvoiceService {
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

    private static func weekRangeLabel(_ week: TimesheetWeek, lang: AppLanguage) -> String {
        guard let first = week.jours.first, let last = week.jours.last else {
            return L10n.week(lang, number: week.numero)
        }
        return "\(first.date.formattedDate(for: lang)) - \(last.date.formattedDate(for: lang))"
    }
}
