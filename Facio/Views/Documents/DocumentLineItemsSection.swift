import SwiftUI

struct DocumentLineItemsSection: View {
    let document: Document
    let company: CompanyInfo
    let lang: AppLanguage
    let onSave: () -> Void

    var body: some View {
        GroupBox(L10n.linesSection(lang)) {
            VStack(alignment: .leading, spacing: 8) {
                header
                Divider()
                content
                Divider()
                addLineButton
            }
            .padding(8)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(L10n.designationLabel(lang))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.quantityLabel(lang))
                .frame(width: 80, alignment: .trailing)
            Text(L10n.unitPrice(lang))
                .frame(width: 110, alignment: .trailing)
            Text(L10n.vatLabel(lang))
                .frame(width: 80, alignment: .center)
            Text(L10n.totalHTLabel(lang))
                .frame(width: 110, alignment: .trailing)
            Spacer().frame(width: 32)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }

    private var content: some View {
        Group {
            ForEach(document.lignesTriees) { ligne in
                LineItemRowView(
                    document: document,
                    ligneId: ligne.id,
                    onDelete: {
                        document.supprimerLigne(ligne)
                        onSave()
                    },
                    onUpdate: onSave
                )
            }

            if document.lignes.isEmpty {
                Text(L10n.noLines(lang))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
        }
    }

    private var addLineButton: some View {
        HStack(spacing: 12) {
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
                                Text("\(NSDecimalNumber(decimal: preset.prixUnitaire))€/u")
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
}
