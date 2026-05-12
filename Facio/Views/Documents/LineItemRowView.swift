import SwiftUI

struct LineItemRowView: View {
    var document: Document
    let ligneId: UUID
    var onDelete: () -> Void
    var onUpdate: () -> Void

    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private static let tvaRates: [Decimal] = [0, 5.5, 10, 20]

    /// Acces securise a la ligne — retourne nil si supprimee
    private var ligne: LineItem? {
        document.lignes.first(where: { $0.id == ligneId })
    }

    /// Index securise — recalcule a chaque acces
    private func safeIndex() -> Int? {
        document.lignes.firstIndex(where: { $0.id == ligneId })
    }

    var body: some View {
        if let currentLigne = ligne {
            HStack(spacing: 8) {
                // Designation
                TextField(L10n.designationLabel(lang), text: Binding(
                    get: { document.lignes.first(where: { $0.id == ligneId })?.designation ?? "" },
                    set: { newVal in
                        if let i = safeIndex() { document.lignes[i].designation = newVal; onUpdate() }
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)

                // Quantite
                DecimalField(
                    placeholder: L10n.qtyShort(lang),
                    value: Binding(
                        get: { document.lignes.first(where: { $0.id == ligneId })?.quantite ?? 0 },
                        set: { newVal in
                            if let i = safeIndex() { document.lignes[i].quantite = newVal; onUpdate() }
                        }
                    )
                )
                .frame(width: 80)

                // Prix unitaire
                DecimalField(
                    placeholder: L10n.priceLabel(lang),
                    value: Binding(
                        get: { document.lignes.first(where: { $0.id == ligneId })?.prixUnitaire ?? 0 },
                        set: { newVal in
                            if let i = safeIndex() { document.lignes[i].prixUnitaire = newVal; onUpdate() }
                        }
                    )
                )
                .frame(width: 110)

                // TVA
                Picker(L10n.vatLabel(lang), selection: Binding(
                    get: { document.lignes.first(where: { $0.id == ligneId })?.tauxTVA ?? 0 },
                    set: { newVal in
                        if let i = safeIndex() { document.lignes[i].tauxTVA = newVal; onUpdate() }
                    }
                )) {
                    ForEach(Self.tvaRates, id: \.self) { rate in
                        Text("\(NSDecimalNumber(decimal: rate))%").tag(rate)
                    }
                }
                .labelsHidden()
                .frame(width: 80)

                // Total (lecture seule)
                Text(currentLigne.totalLigne.formatted2Decimals)
                    .font(.body.monospacedDigit())
                    .frame(width: 110, alignment: .trailing)

                // Supprimer
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 32, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 2)
        }
    }
}

/// TextField custom qui accepte les decimales avec . et ,
struct DecimalField: View {
    let placeholder: String
    @Binding var value: Decimal
    var maximumFractionDigits: Int = 2
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
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = ""
        return formatter.string(from: d as NSDecimalNumber) ?? "\(d)"
    }
}
