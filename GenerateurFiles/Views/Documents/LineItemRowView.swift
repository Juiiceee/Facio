import SwiftUI

struct LineItemRowView: View {
    var document: Document
    let ligneId: UUID
    var onDelete: () -> Void
    var onUpdate: () -> Void

    private static let tvaRates: [Decimal] = [0, 5.5, 10, 20]

    private var ligneIndex: Int? {
        document.lignes.firstIndex(where: { $0.id == ligneId })
    }

    var body: some View {
        if let index = ligneIndex {
            HStack(spacing: 8) {
                // Designation
                TextField("Designation", text: Binding(
                    get: { document.lignes[index].designation },
                    set: { document.lignes[index].designation = $0; onUpdate() }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)

                // Quantite (String pour supporter les decimales)
                DecimalField(
                    placeholder: "Qte",
                    value: Binding(
                        get: { document.lignes[index].quantite },
                        set: { document.lignes[index].quantite = $0; onUpdate() }
                    )
                )
                .frame(width: 80)

                // Prix unitaire
                DecimalField(
                    placeholder: "Prix",
                    value: Binding(
                        get: { document.lignes[index].prixUnitaire },
                        set: { document.lignes[index].prixUnitaire = $0; onUpdate() }
                    )
                )
                .frame(width: 110)

                // TVA
                Picker("TVA", selection: Binding(
                    get: { document.lignes[index].tauxTVA },
                    set: { document.lignes[index].tauxTVA = $0; onUpdate() }
                )) {
                    ForEach(Self.tvaRates, id: \.self) { rate in
                        Text("\(NSDecimalNumber(decimal: rate))%").tag(rate)
                    }
                }
                .labelsHidden()
                .frame(width: 80)

                // Total (lecture seule)
                Text(document.lignes[index].totalLigne.formatted2Decimals)
                    .font(.body.monospacedDigit())
                    .frame(width: 110, alignment: .trailing)

                // Supprimer
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.borderless)
                .frame(width: 32)
            }
            .padding(.vertical, 2)
        }
    }
}

/// TextField custom qui accepte les decimales avec . et ,
struct DecimalField: View {
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
                text = value == 0 ? "" : formatDecimal(value)
            }
            .onChange(of: isFocused) {
                if !isFocused {
                    // Quand on quitte le champ, convertir le texte en Decimal
                    let cleaned = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
                    if let parsed = Decimal(string: cleaned) {
                        value = parsed
                        text = formatDecimal(parsed)
                    } else if text.isEmpty {
                        value = 0
                    }
                }
            }
            .onSubmit {
                let cleaned = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
                if let parsed = Decimal(string: cleaned) {
                    value = parsed
                    text = formatDecimal(parsed)
                }
            }
    }

    private func formatDecimal(_ d: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = ""
        return formatter.string(from: d as NSDecimalNumber) ?? "\(d)"
    }
}
