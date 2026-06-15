import SwiftUI

/// Largeurs de colonnes du tableau de lignes, partagées entre l'en-tête
/// (`DocumentLineItemsSection.header`) et les lignes (`LineItemRowView`).
enum LineItemColumns {
    static let qty: CGFloat = 80
    static let unitPrice: CGFloat = 110
    static let vat: CGFloat = 80
    static let totalHT: CGFloat = 110
    static let totalTTC: CGFloat = 110
    static let actions: CGFloat = 32

    // Variante compacte (ligne sur deux niveaux, sous
    // `FacioLayout.lineItemsCompactBreakpoint`) : champs resserrés,
    // le total prend la place restante en fin de rangée.
    static let compactQty: CGFloat = 64
    static let compactUnitPrice: CGFloat = 100
    static let compactVat: CGFloat = 76
}

struct DocumentLineItemsSection: View {
    let document: Document
    let company: CompanyInfo
    let lang: AppLanguage
    let onSave: () -> Void

    @Environment(\.facioContainerWidth) private var containerWidth

    /// Bascule en disposition compacte (ligne sur deux niveaux) quand la largeur
    /// ne permet plus les colonnes fixes + une désignation lisible (≈ 620 pt).
    private var compact: Bool { containerWidth < FacioLayout.lineItemsCompactBreakpoint }

    var body: some View {
        SectionPanel(L10n.linesSection(lang), systemImage: "list.bullet.rectangle") {
            VStack(alignment: .leading, spacing: FacioLayout.space8) {
                // En compact, l'en-tête de colonnes n'a plus de colonnes à titrer.
                if !compact {
                    header
                    Divider()
                }
                content
                Divider()
                addLineButton
            }
        }
    }

    private var header: some View {
        HStack(spacing: FacioLayout.space8) {
            Text(L10n.designationLabel(lang))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.quantityLabel(lang))
                .frame(width: LineItemColumns.qty, alignment: .trailing)
            Text(L10n.unitPrice(lang))
                .frame(width: LineItemColumns.unitPrice, alignment: .trailing)
            Text(L10n.vatLabel(lang))
                .frame(width: LineItemColumns.vat, alignment: .center)
            Text(L10n.totalHTLabel(lang))
                .frame(width: LineItemColumns.totalHT, alignment: .trailing)
            Text(L10n.totalTTCLabel(lang))
                .frame(width: LineItemColumns.totalTTC, alignment: .trailing)
            Spacer().frame(width: LineItemColumns.actions)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, FacioLayout.space4)
    }

    private var content: some View {
        Group {
            ForEach(document.lignesTriees) { ligne in
                LineItemRowView(
                    document: document,
                    ligneId: ligne.id,
                    compact: compact,
                    onDelete: {
                        document.supprimerLigne(ligne)
                        onSave()
                    },
                    onDuplicate: {
                        duplicateLine(ligne)
                    },
                    onInsertBelow: {
                        insertLineBelow(ligne)
                    },
                    onUpdate: onSave
                )
            }

            if document.lignes.isEmpty {
                Text(L10n.noLines(lang))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, FacioLayout.space12)
            }
        }
    }

    private var addLineButton: some View {
        HStack(spacing: FacioLayout.space12) {
            Button {
                let ligne = LineItem(
                    designation: "",
                    quantite: 1,
                    prixUnitaire: 0,
                    tauxTVA: company.tauxTVAParDefaut,
                    ordre: document.lignes.count
                )
                document.ajouterLigne(ligne)
                onSave()
            } label: {
                Label(L10n.addEmptyLine(lang), systemImage: "plus.circle")
            }
            .buttonStyle(.borderless)

            if !company.prestations.isEmpty {
                Menu {
                    ForEach(company.prestations) { preset in
                        Button {
                            addPreset(preset)
                        } label: {
                            HStack {
                                Text(preset.designation)
                                Spacer()
                                Text("\(document.currency.formatAccounting(preset.prixUnitaire, lang: company.formatNombre))/\(L10n.unitShort(lang))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } label: {
                    Label(L10n.favoriteService(lang), systemImage: "star.fill")
                }
                .menuStyle(.borderlessButton)
            }
        }
    }

    private func addPreset(_ preset: DesignationPreset) {
        let ligne = LineItem(
            designation: preset.designation,
            quantite: 1,
            prixUnitaire: preset.prixUnitaire,
            tauxTVA: preset.tauxTVA,
            ordre: document.lignes.count
        )
        document.ajouterLigne(ligne)
        onSave()
    }

    private func duplicateLine(_ line: LineItem) {
        let copy = LineItem(
            designation: line.designation,
            quantite: line.quantite,
            prixUnitaire: line.prixUnitaire,
            tauxTVA: line.tauxTVA,
            ordre: line.ordre + 1
        )
        insert(copy, after: line)
    }

    private func insertLineBelow(_ line: LineItem) {
        let newLine = LineItem(
            designation: "",
            quantite: 1,
            prixUnitaire: 0,
            tauxTVA: company.tauxTVAParDefaut,
            ordre: line.ordre + 1
        )
        insert(newLine, after: line)
    }

    private func insert(_ line: LineItem, after reference: LineItem) {
        let sorted = document.lignesTriees
        let insertionIndex = (sorted.firstIndex { $0.id == reference.id } ?? sorted.endIndex - 1) + 1
        var rebuilt = sorted
        rebuilt.insert(line, at: min(insertionIndex, rebuilt.endIndex))
        for index in rebuilt.indices {
            rebuilt[index].ordre = index
        }
        document.lignes = rebuilt
        onSave()
    }
}
