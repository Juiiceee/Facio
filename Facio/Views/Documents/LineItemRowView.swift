import SwiftUI

struct LineItemRowView: View {
    var document: Document
    let ligneId: UUID
    var onDelete: () -> Void
    var onDuplicate: () -> Void
    var onInsertBelow: () -> Void
    var onUpdate: () -> Void

    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }

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
            HStack(spacing: FacioLayout.space8) {
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
                .format(numberFormat)
                .frame(width: LineItemColumns.qty)

                // Prix unitaire
                DecimalField(
                    placeholder: L10n.priceLabel(lang),
                    value: Binding(
                        get: { document.lignes.first(where: { $0.id == ligneId })?.prixUnitaire ?? 0 },
                        set: { newVal in
                            if let i = safeIndex() { document.lignes[i].prixUnitaire = newVal; onUpdate() }
                        }
                    ),
                    maximumFractionDigits: document.currency.maximumFractionDigits
                )
                .format(numberFormat)
                .frame(width: LineItemColumns.unitPrice)

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
                .frame(width: LineItemColumns.vat)

                // Total (lecture seule)
                Text(document.currency.formatAccounting(currentLigne.totalLigne, lang: numberFormat))
                    .font(.body.monospacedDigit())
                    .frame(width: LineItemColumns.totalHT, alignment: .trailing)

                Menu {
                    Button {
                        onInsertBelow()
                    } label: {
                        Label(L10n.insertLineBelow(lang), systemImage: "plus")
                    }

                    Button {
                        onDuplicate()
                    } label: {
                        Label(L10n.duplicateLine(lang), systemImage: "doc.on.doc")
                    }

                    Divider()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label(L10n.deleteLine(lang), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .frame(width: LineItemColumns.actions, height: FacioLayout.iconHitTarget)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .help(L10n.businessActions(lang))
            }
            .padding(.vertical, FacioLayout.space2)
            .padding(.horizontal, FacioLayout.space4)
            .background(rowNeedsAttention(currentLigne) ? Color.intentWarning.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusField))
        }
    }

    private func rowNeedsAttention(_ line: LineItem) -> Bool {
        line.designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || line.quantite <= 0
            || line.prixUnitaire < 0
    }
}

/// TextField custom qui accepte les decimales avec . et ,
struct DecimalField: View {
    let placeholder: String
    @Binding var value: Decimal
    var maximumFractionDigits: Int = 2
    var format: AppLanguage = .fr
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
            .facioField(density: .compact)
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

    func format(_ format: AppLanguage) -> Self {
        var copy = self
        copy.format = format
        return copy
    }

    private func formatDecimal(_ d: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: format == .fr ? "fr_FR" : "en_US")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.decimalSeparator = format == .fr ? "," : "."
        formatter.groupingSeparator = ""
        return formatter.string(from: d as NSDecimalNumber) ?? "\(d)"
    }
}
