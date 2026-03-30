import SwiftUI

/// TextField pour saisir des heures au format h.mm (ex: 6.30 = 6h30 → stocke 6.5)
/// La partie apres le point/virgule est interpretee comme des minutes (sur 60)
/// 6.30 → 6.5h | 9.15 → 9.25h | 8.45 → 8.75h | 10.00 → 10h
struct TimeField: View {
    let placeholder: String
    @Binding var value: Decimal
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
            .onAppear {
                text = value == 0 ? "" : formatForDisplay(value)
            }
            .onChange(of: isFocused) {
                if !isFocused {
                    applyValue()
                }
            }
            .onSubmit {
                applyValue()
            }
    }

    private func applyValue() {
        let cleaned = text
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)

        guard !cleaned.isEmpty else {
            value = 0
            return
        }

        // Convertir h.mm → decimal
        let decimal = convertHMToDecimal(cleaned)
        value = decimal
        text = formatForDisplay(decimal)
    }

    /// Convertit "6.30" (6h30min) → 6.5 (decimal)
    /// Si les minutes > 59, on traite comme decimal normal (retro-compatible)
    private func convertHMToDecimal(_ input: String) -> Decimal {
        let parts = input.split(separator: ".", maxSplits: 1)

        guard parts.count == 2,
              let heures = Int(parts[0]),
              let minutesPart = Int(parts[1])
        else {
            // Pas de point ou format invalide → essayer comme nombre brut
            return Decimal(string: input) ?? 0
        }

        // Si la partie minutes a 1 chiffre (ex: "6.3"), on l'interprete comme "6.30" = 30 min
        let minutes: Int
        if parts[1].count == 1 {
            minutes = minutesPart * 10  // "6.3" → 30 minutes
        } else {
            minutes = minutesPart
        }

        // Si minutes > 59, c'est probablement deja decimal (ex: "6.75")
        if minutes > 59 {
            return Decimal(string: input) ?? 0
        }

        // Conversion minutes → fraction decimale
        let fraction = Decimal(minutes) / Decimal(60)
        return Decimal(heures) + fraction
    }

    /// Affiche la valeur decimale en format h.mm pour edition
    /// 6.5 → "6.30" | 9.25 → "9.15" | 8.75 → "8.45"
    private func formatForDisplay(_ d: Decimal) -> String {
        let doubleVal = NSDecimalNumber(decimal: d).doubleValue
        let heures = Int(doubleVal)
        let minutesFraction = doubleVal - Double(heures)
        let minutes = Int(round(minutesFraction * 60))

        if minutes == 0 {
            return "\(heures)"
        }
        return String(format: "%d.%02d", heures, minutes)
    }
}
