import Foundation

enum TimesheetHourInputParser {
    static func parse(_ input: String, mode: TimesheetHourInputMode) -> Decimal? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .zero }

        switch mode {
        case .decimal:
            return parseDecimalHours(trimmed)
        case .time:
            return parseDurationHours(trimmed)
        }
    }

    static func format(_ value: Decimal, mode: TimesheetHourInputMode, lang: AppLanguage) -> String {
        switch mode {
        case .decimal:
            return formatDecimal(value, lang: lang)
        case .time:
            return formatDuration(value, lang: lang)
        }
    }

    private static func parseDecimalHours(_ input: String) -> Decimal? {
        let compact = input
            .replacingOccurrences(of: "\u{00a0}", with: "")
            .replacingOccurrences(of: " ", with: "")
        let separatorCount = compact.filter { $0 == "," || $0 == "." }.count

        guard separatorCount <= 1,
              compact.range(
                of: #"^\d+(?:[\.,]\d*)?$|^[\.,]\d+$"#,
                options: .regularExpression
              ) != nil
        else {
            return nil
        }

        let normalized = compact.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func parseDurationHours(_ input: String) -> Decimal? {
        let compact = input
            .lowercased()
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .replacingOccurrences(of: " ", with: "")

        guard !compact.contains(","),
              !compact.contains("."),
              !compact.isEmpty
        else {
            return nil
        }

        if compact.allSatisfy(\.isNumber) {
            return Decimal(Int(compact) ?? 0)
        }

        let separator: Character
        if compact.contains(":") {
            separator = ":"
        } else if compact.contains("h") {
            separator = "h"
        } else {
            return nil
        }

        let separatorCount = compact.filter { $0 == separator }.count
        let parts = compact.split(separator: separator, maxSplits: 1, omittingEmptySubsequences: false)

        guard separatorCount == 1,
              parts.count == 2,
              !parts[0].isEmpty,
              let hours = Int(parts[0])
        else {
            return nil
        }

        let minuteText = String(parts[1])
        if minuteText.isEmpty {
            guard separator == "h" else { return nil }
            return Decimal(hours)
        }

        guard let minutes = Int(minuteText),
              (0...59).contains(minutes)
        else {
            return nil
        }

        return Decimal(hours) + (Decimal(minutes) / Decimal(60))
    }

    private static func formatDecimal(_ value: Decimal, lang: AppLanguage) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: lang == .fr ? "fr_FR" : "en_US")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    private static func formatDuration(_ value: Decimal, lang: AppLanguage) -> String {
        let doubleVal = NSDecimalNumber(decimal: value).doubleValue
        let totalMinutes = Int(round(doubleVal * 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 {
            return "\(hours)"
        }

        if lang == .fr {
            return String(format: "%dh%02d", hours, minutes)
        }
        return String(format: "%d:%02d", hours, minutes)
    }
}
