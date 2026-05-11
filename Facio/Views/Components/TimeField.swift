import SwiftUI

enum TimesheetHourInputMode: String, CaseIterable, Identifiable {
    case decimal
    case time

    var id: String { rawValue }
}

/// TextField pour saisir des heures en decimal ou en duree horaire explicite.
/// Les valeurs sont toujours stockees en heures decimales.
struct TimeField: View {
    let placeholder: String
    @Binding var value: Decimal
    let mode: TimesheetHourInputMode
    let lang: AppLanguage

    @State private var text: String = ""
    @State private var validationError: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
            .overlay {
                if validationError != nil {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.red, lineWidth: 1)
                }
            }
            .help(validationError ?? L10n.hourInputHelp(lang, mode: mode))
            .onAppear {
                syncTextFromValue()
            }
            .onChange(of: isFocused) {
                if !isFocused {
                    applyValue()
                } else {
                    validationError = nil
                }
            }
            .onChange(of: mode) {
                validationError = nil
                if !isFocused {
                    syncTextFromValue()
                }
            }
            .onChange(of: value) {
                if !isFocused {
                    syncTextFromValue()
                }
            }
            .onSubmit {
                applyValue()
            }
    }

    private func syncTextFromValue() {
        text = value == 0 ? "" : formatForDisplay(value)
    }

    private func applyValue() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            value = 0
            text = ""
            validationError = nil
            return
        }

        let decimal: Decimal?
        switch mode {
        case .decimal:
            decimal = parseDecimalHours(trimmed)
        case .time:
            decimal = parseDurationHours(trimmed)
        }

        guard let decimal else {
            validationError = mode == .decimal
                ? L10n.hourInputInvalidDecimal(lang)
                : L10n.hourInputInvalidTime(lang)
            return
        }

        value = decimal
        text = formatForDisplay(decimal)
        validationError = nil
    }

    private func parseDecimalHours(_ input: String) -> Decimal? {
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

    private func parseDurationHours(_ input: String) -> Decimal? {
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

    private func formatForDisplay(_ d: Decimal) -> String {
        switch mode {
        case .decimal:
            return formatDecimal(d)
        case .time:
            return formatDuration(d)
        }
    }

    private func formatDecimal(_ d: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: lang == .fr ? "fr_FR" : "en_US")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter.string(from: d as NSDecimalNumber) ?? "\(d)"
    }

    private func formatDuration(_ d: Decimal) -> String {
        let doubleVal = NSDecimalNumber(decimal: d).doubleValue
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
