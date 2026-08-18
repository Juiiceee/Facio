import SwiftUI

struct LineItemRowView: View {
    var document: Document
    let ligneId: UUID
    /// Disposition compacte sur deux niveaux (désignation + actions, puis
    /// qty/prix/TVA/total) — pilotée par `DocumentLineItemsSection`.
    var compact: Bool = false
    var onDelete: () -> Void
    var onDuplicate: () -> Void
    var onInsertBelow: () -> Void
    var onUpdate: () -> Void
    /// Déplacer la ligne. Le modèle porte un champ `ordre` et les lignes sont
    /// triées dessus, mais rien ne permettait de réordonner : il fallait
    /// supprimer et retaper.
    var onMove: (Int) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }

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
            // Le if/else ne duplique que la STRUCTURE : les champs eux-mêmes
            // sont des sous-vues privées partagées entre les deux variantes.
            Group {
                if compact {
                    compactRow(for: currentLigne)
                } else {
                    regularRow(for: currentLigne)
                }
            }
            .padding(.vertical, FacioLayout.space4)
            .padding(.horizontal, FacioLayout.space4)
            .background(incompleteReason(currentLigne) == nil ? Color.clear : FacioIntent.warning.tint)
            .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusSmall))
            .overlay(alignment: .bottomLeading) {
                // La cause ÉCRITE. Le fond orange était le seul signal, donc
                // rien pour un daltonien, rien pour VoiceOver, rien sur une
                // capture d'écran — et la chaîne existait déjà, non rendue.
                if let reason = incompleteReason(currentLigne) {
                    Label(reason, systemImage: "exclamationmark.circle.fill")
                        .font(FacioFont.label)
                        .foregroundStyle(FacioIntent.warning.onTint)
                        .padding(.horizontal, FacioLayout.space4)
                        .offset(y: FacioLayout.space12)
                }
            }
            .padding(.bottom, incompleteReason(currentLigne) == nil ? 0 : FacioLayout.space16)
        }
    }

    // MARK: - Variantes de disposition

    /// Variante régulière : une seule rangée, colonnes fixes alignées sur
    /// l'en-tête de `DocumentLineItemsSection`.
    private func regularRow(for currentLigne: LineItem) -> some View {
        HStack(spacing: FacioLayout.space8) {
            designationField
            qtyField
                .frame(width: LineItemColumns.qty)
            priceField
                .frame(width: LineItemColumns.unitPrice)
            vatPicker
                .frame(width: LineItemColumns.vat)
            totalText(for: currentLigne)
                .frame(width: LineItemColumns.totalHT, alignment: .trailing)
            totalTTCText(for: currentLigne)
                .frame(width: LineItemColumns.totalTTC, alignment: .trailing)
            actionsMenu
        }
    }

    /// Variante compacte : deux niveaux — désignation + actions, puis
    /// quantité / prix / TVA et total calé à droite.
    private func compactRow(for currentLigne: LineItem) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space4) {
            HStack(spacing: FacioLayout.space8) {
                designationField
                actionsMenu
            }
            HStack(spacing: FacioLayout.space8) {
                qtyField
                    .frame(width: LineItemColumns.compactQty)
                priceField
                    .frame(width: LineItemColumns.compactUnitPrice)
                vatPicker
                    .frame(width: LineItemColumns.compactVat)
                Spacer()
                VStack(alignment: .trailing, spacing: FacioLayout.space2) {
                    MoneyText(amount: currentLigne.totalLigne, currency: document.currency, lang: numberFormat)
                        .font(FacioFont.caption)
                        .foregroundStyle(.secondary)
                    totalTTCText(for: currentLigne)
                }
            }
        }
    }

    // MARK: - Champs partagés entre les deux variantes

    /// Designation
    private var designationField: some View {
        TextField(L10n.designationLabel(lang), text: Binding(
            get: { document.lignes.first(where: { $0.id == ligneId })?.designation ?? "" },
            set: { newVal in
                if let i = safeIndex() { document.lignes[i].designation = newVal; onUpdate() }
            }
        ))
        .facioField(density: .compact)
        .frame(maxWidth: .infinity)
    }

    /// Quantite
    private var qtyField: some View {
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
    }

    /// Prix unitaire
    private var priceField: some View {
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
    }

    /// TVA — saisie libre.
    ///
    /// Le taux était figé à 0 / 5,5 / 10 / 20 : impossible de saisir 2,1 %
    /// (presse, médicaments), un taux DOM ou un taux étranger, alors que l'app
    /// est bilingue et facture en USD.
    private var vatPicker: some View {
        DecimalField(
            placeholder: L10n.vatLabel(lang),
            value: Binding(
                get: { document.lignes.first(where: { $0.id == ligneId })?.tauxTVA ?? 0 },
                set: { newVal in
                    if let i = safeIndex() { document.lignes[i].tauxTVA = newVal; onUpdate() }
                }
            ),
            format: numberFormat
        )
    }

    /// Total HT (lecture seule)
    private func totalText(for line: LineItem) -> some View {
        MoneyText(amount: line.totalLigne, currency: document.currency, lang: numberFormat)
            .font(FacioFont.amount)
    }

    /// Total TTC de la ligne (HT + TVA), lecture seule.
    private func totalTTCText(for line: LineItem) -> some View {
        MoneyText(amount: line.totalTTC, currency: document.currency, lang: numberFormat)
            .font(FacioFont.amount)
    }

    /// Menu d'actions de la ligne (insérer / dupliquer / supprimer)
    private var actionsMenu: some View {
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

            Button {
                onMove(-1)
            } label: {
                Label(L10n.moveLineUp(lang), systemImage: "arrow.up")
            }
            Button {
                onMove(1)
            } label: {
                Label(L10n.moveLineDown(lang), systemImage: "arrow.down")
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

    /// Pourquoi cette ligne est incomplète — la cause, pas seulement le fait.
    private func incompleteReason(_ line: LineItem) -> String? {
        var causes: [String] = []
        if line.designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            causes.append(L10n.lineMissingDesignation(lang))
        }
        if line.quantite <= 0 { causes.append(L10n.lineMissingQuantity(lang)) }
        if line.prixUnitaire < 0 { causes.append(L10n.lineMissingPrice(lang)) }
        guard !causes.isEmpty else { return nil }
        return "\(L10n.lineIncomplete(lang)) — \(causes.joined(separator: ", "))"
    }
}

/// TextField custom qui accepte les decimales avec . et ,
struct DecimalField: View {
    let placeholder: String
    @Binding var value: Decimal
    var maximumFractionDigits: Int = 2
    var format: AppLanguage = .fr
    /// `.compact` par défaut (lignes de tableau) ; passer en `.regular` via
    /// `.density(.regular)` dans les formulaires.
    var density: FacioFieldDensity = .compact
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
            .facioField(density: density)
            .onAppear {
                text = value == 0 ? "" : formatDecimal(value)
            }
            // Resynchronise le texte quand la valeur liée change de l'extérieur —
            // typiquement quand SwiftUI réutilise cette vue pour un autre document
            // (l'éditeur de facture n'est pas recréé au changement de sélection).
            // Sans ceci, le champ garderait la valeur du document précédent (et
            // pourrait la réécrire sur le document courant). On n'écrase jamais une
            // saisie en cours (champ focus).
            .onChange(of: value) { _, newValue in
                guard !isFocused else { return }
                let formatted = newValue == 0 ? "" : formatDecimal(newValue)
                if formatted != text { text = formatted }
            }
            // Commit à chaque frappe (sans reformater) : si la vue est détruite
            // pendant la saisie (bascule compact/large au franchissement du
            // breakpoint), aucune saisie n'est perdue.
            .onChange(of: text) {
                let cleaned = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
                if let parsed = Decimal(string: cleaned) {
                    value = parsed
                } else if cleaned.isEmpty {
                    value = 0
                }
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

    func density(_ density: FacioFieldDensity) -> Self {
        var copy = self
        copy.density = density
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
