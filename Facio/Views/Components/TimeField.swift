import SwiftUI

enum TimesheetHourInputMode: String, CaseIterable, Identifiable {
    case decimal
    case time

    var id: String { rawValue }
}

struct TimeFieldFocusRequest: Equatable {
    let id: UUID
    let nonce: Int
}

/// TextField pour saisir des heures en decimal ou en duree horaire explicite.
/// Les valeurs sont toujours stockees en heures decimales.
struct TimeField: View {
    let placeholder: String
    @Binding var value: Decimal
    let mode: TimesheetHourInputMode
    let lang: AppLanguage
    var focusID: UUID? = nil
    var focusRequest: TimeFieldFocusRequest? = nil

    @State private var text: String = ""
    @State private var validationError: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
            .frame(maxWidth: .infinity, minHeight: 28)
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
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
            .onChange(of: focusRequest) { _, request in
                guard let focusID, request?.id == focusID else { return }
                isFocused = true
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

        let decimal = TimesheetHourInputParser.parse(trimmed, mode: mode)

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

    private func formatForDisplay(_ d: Decimal) -> String {
        TimesheetHourInputParser.format(d, mode: mode, lang: lang)
    }
}
