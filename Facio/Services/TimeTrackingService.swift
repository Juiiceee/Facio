import Foundation

enum TimeEntryDurationFormat: String, Codable, CaseIterable, Identifiable {
    case full
    case compact
    case decimal

    var id: String { rawValue }
}

enum TimeEntryRoundingMode: String, Codable, CaseIterable, Identifiable {
    case none
    case up
    case down
    case nearest

    var id: String { rawValue }
}

enum TimeEntrySource: String, Codable, CaseIterable, Identifiable {
    case timer
    case manual
    case duplicate

    var id: String { rawValue }
}

enum TimeEntryInvoiceGrouping: String, CaseIterable, Identifiable {
    case detailed
    case byProject
    case singleLine

    var id: String { rawValue }
}

struct TimeOfDay: Equatable {
    let hour: Int
    let minute: Int
}

enum TimeTrackingValidationError: Error, Equatable {
    case invalidDuration
    case invalidTime
    case invalidDateRange
}

enum TimeTrackingService {
    static func parseDurationInput(
        _ input: String,
        format: TimeEntryDurationFormat = .compact
    ) throws -> Int {
        let raw = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")

        guard !raw.isEmpty, !raw.hasPrefix("-") else {
            throw TimeTrackingValidationError.invalidDuration
        }

        let seconds: Int?
        if raw.contains(":") {
            seconds = parseColonDuration(raw)
        } else if raw.contains("h") || raw.contains("m") || raw.contains("s") {
            seconds = parseTokenDuration(raw)
        } else if raw.contains(".") {
            seconds = decimalHoursToSeconds(raw)
        } else {
            seconds = parsePlainNumberDuration(raw, format: format)
        }

        guard let seconds, seconds > 0 else {
            throw TimeTrackingValidationError.invalidDuration
        }
        return seconds
    }

    static func parseTimeOfDayInput(_ input: String) throws -> TimeOfDay {
        let raw = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")

        guard !raw.isEmpty, !raw.hasPrefix("-") else {
            throw TimeTrackingValidationError.invalidTime
        }

        let suffix: String?
        let body: String
        if raw.hasSuffix("am") || raw.hasSuffix("pm") {
            suffix = String(raw.suffix(2))
            body = String(raw.dropLast(2))
        } else {
            suffix = nil
            body = raw
        }

        guard let time = parseClockBody(body, suffix: suffix) else {
            throw TimeTrackingValidationError.invalidTime
        }
        return time
    }

    static func roundDurationSeconds(
        _ seconds: Int,
        mode: TimeEntryRoundingMode,
        intervalMinutes: Int
    ) -> Int {
        guard seconds > 0 else { return 0 }
        guard mode != .none else { return seconds }

        let interval = max(1, intervalMinutes) * 60
        let quotient = Double(seconds) / Double(interval)
        switch mode {
        case .none:
            return seconds
        case .up:
            return Int(ceil(quotient)) * interval
        case .down:
            return Int(floor(quotient)) * interval
        case .nearest:
            return Int(quotient.rounded(.toNearestOrAwayFromZero)) * interval
        }
    }

    static func combine(date: Date, time: TimeOfDay, calendar: Calendar = .current) -> Date? {
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: DateComponents(
            year: day.year,
            month: day.month,
            day: day.day,
            hour: time.hour,
            minute: time.minute
        ))
    }

    static func csv(
        for entries: [TimeEntry],
        timesheet: TimesheetPeriod,
        roundingMode: TimeEntryRoundingMode = .none,
        roundingIntervalMinutes: Int = 1,
        lang: AppLanguage
    ) -> String {
        let header = [
            "date",
            "description",
            "client",
            "project",
            "task",
            "tags",
            "start",
            "end",
            "duration_raw",
            "duration_rounded",
            "billable",
            "hourly_rate",
            "amount",
            "currency",
            "invoiced",
            "invoice_number",
        ].joined(separator: ",")

        let rows = entries
            .filter { !$0.isDeleted }
            .sorted { $0.startedAt < $1.startedAt }
            .map { entry -> String in
                let rawSeconds = Int(entry.duration().rounded(.down))
                let roundedSeconds = roundDurationSeconds(
                    rawSeconds,
                    mode: roundingMode,
                    intervalMinutes: roundingIntervalMinutes
                )
                let roundedHours = Decimal(roundedSeconds) / Decimal(3600)
                let rate = entry.rateSnapshot ?? timesheet.tauxNormal
                let amount = entry.isBillable ? roundedHours * rate : 0
                let currency = entry.currencySnapshot?.rawValue ?? ""
                let values = [
                    entry.dateString,
                    entry.notes,
                    timesheet.clientDisplayName,
                    entry.projectName,
                    entry.taskName,
                    entry.tagsText,
                    entry.startedAt.formatted(date: .omitted, time: .standard),
                    entry.endedAt?.formatted(date: .omitted, time: .standard) ?? "",
                    String(rawSeconds),
                    String(roundedSeconds),
                    entry.isBillable ? "true" : "false",
                    rate.formattedDecimal(maxFractionDigits: 2, for: lang),
                    amount.formattedDecimal(maxFractionDigits: 2, for: lang),
                    currency,
                    entry.isInvoiced ? "true" : "false",
                    entry.invoiceDocumentId?.uuidString ?? "",
                ]
                return values.map(csvEscape).joined(separator: ",")
            }

        return ([header] + rows).joined(separator: "\n")
    }

    private static func parseColonDuration(_ raw: String) -> Int? {
        let parts = raw.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2 || parts.count == 3 else { return nil }
        guard parts.allSatisfy({ $0.isEmpty || $0.allSatisfy(\.isNumber) }) else { return nil }

        func intPart(_ index: Int) -> Int? {
            guard index < parts.count, !parts[index].isEmpty else { return 0 }
            return Int(parts[index])
        }

        if parts.count == 2 {
            guard let hours = intPart(0), let minutes = intPart(1) else { return nil }
            return hours * 3600 + minutes * 60
        }

        guard let hours = intPart(0),
              let minutes = intPart(1),
              let seconds = intPart(2) else { return nil }
        return hours * 3600 + minutes * 60 + seconds
    }

    private static func parseTokenDuration(_ raw: String) -> Int? {
        var index = raw.startIndex
        var total = 0.0
        while index < raw.endIndex {
            let numberStart = index
            while index < raw.endIndex, raw[index].isNumber || raw[index] == "." {
                index = raw.index(after: index)
            }
            guard numberStart != index,
                  index < raw.endIndex,
                  let value = Double(raw[numberStart..<index]) else {
                return nil
            }

            let unit = raw[index]
            switch unit {
            case "h": total += value * 3600
            case "m": total += value * 60
            case "s": total += value
            default: return nil
            }
            index = raw.index(after: index)
        }
        guard total.isFinite, total > 0, total < Double(Int.max) else { return nil }
        return Int(total.rounded(.toNearestOrAwayFromZero))
    }

    private static func decimalHoursToSeconds(_ raw: String) -> Int? {
        guard let value = Double(raw), value.isFinite, value > 0 else { return nil }
        return Int((value * 3600).rounded(.toNearestOrAwayFromZero))
    }

    private static func parsePlainNumberDuration(_ raw: String, format: TimeEntryDurationFormat) -> Int? {
        guard raw.allSatisfy(\.isNumber), let value = Int(raw) else { return nil }
        if format == .decimal {
            return value * 3600
        }

        switch raw.count {
        case 1, 2:
            return value * 60
        case 3:
            let hours = value / 100
            let minutes = value % 100
            return hours * 3600 + minutes * 60
        case 4:
            let hours = value / 100
            let minutes = value % 100
            return hours * 3600 + minutes * 60
        default:
            return nil
        }
    }

    private static func parseClockBody(_ body: String, suffix: String?) -> TimeOfDay? {
        guard !body.isEmpty else { return nil }

        let hour: Int
        let minute: Int
        if body.contains(":") || body.contains(".") {
            let separator: Character = body.contains(":") ? ":" : "."
            let parts = body.split(separator: separator, omittingEmptySubsequences: false)
            guard parts.count == 2,
                  let parsedHour = Int(parts[0]),
                  let parsedMinute = Int(parts[1]) else {
                return nil
            }
            hour = parsedHour
            minute = parsedMinute
        } else {
            guard body.allSatisfy(\.isNumber), let numeric = Int(body) else { return nil }
            switch body.count {
            case 1, 2:
                hour = numeric
                minute = 0
            case 3:
                hour = numeric / 100
                minute = numeric % 100
            case 4:
                hour = numeric / 100
                minute = numeric % 100
            default:
                return nil
            }
        }

        guard minute >= 0, minute <= 59 else { return nil }
        var normalizedHour = hour
        if let suffix {
            guard hour >= 1, hour <= 12 else { return nil }
            if suffix == "am" {
                normalizedHour = hour == 12 ? 0 : hour
            } else {
                normalizedHour = hour == 12 ? 12 : hour + 12
            }
        }
        guard normalizedHour >= 0, normalizedHour <= 23 else { return nil }
        return TimeOfDay(hour: normalizedHour, minute: minute)
    }

    private static func csvEscape(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n")
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuotes ? "\"\(escaped)\"" : escaped
    }
}
