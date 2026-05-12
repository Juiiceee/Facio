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
        var lineItems: [LineItem] = []

        if heuresNorm > 0 {
            lineItems.append(LineItem(
                designation: L10n.workHours(invoiceLanguage),
                quantite: heuresNorm,
                prixUnitaire: timesheet.tauxNormal,
                tauxTVA: company.tauxTVAParDefaut,
                ordre: lineItems.count
            ))
        }

        if heuresSup > 0 {
            lineItems.append(LineItem(
                designation: L10n.overtimeLabel(invoiceLanguage),
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
                let dayHours = day.mois == timesheet.mois
                    ? day.heures
                    : adjacentHours[day.dateString] ?? day.heures

                defer {
                    hoursBeforeDay += dayHours
                }

                guard day.mois == timesheet.mois, dayHours > 0 else { continue }

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

        for allocation in dailyAllocations(for: timesheet, adjacentHours: adjacentHours) {
            let dateLabel = allocation.day.date.formattedDate(for: invoiceLanguage)

            if allocation.normalHours > 0 {
                lineItems.append(LineItem(
                    designation: L10n.workHoursOnDate(invoiceLanguage, date: dateLabel),
                    quantite: allocation.normalHours,
                    prixUnitaire: timesheet.tauxNormal,
                    tauxTVA: company.tauxTVAParDefaut,
                    ordre: lineItems.count
                ))
            }

            if allocation.overtimeHours > 0 {
                lineItems.append(LineItem(
                    designation: L10n.overtimeHoursOnDate(invoiceLanguage, date: dateLabel),
                    quantite: allocation.overtimeHours,
                    prixUnitaire: timesheet.tauxSupplementaire,
                    tauxTVA: company.tauxTVAParDefaut,
                    ordre: lineItems.count
                ))
            }
        }

        return lineItems
    }
}
