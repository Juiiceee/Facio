import SwiftUI

struct PrestationsSettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    var body: some View {
        VStack(spacing: 20) {
            // Info
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Configurez vos prestations habituelles pour les ajouter en un clic lors de la creation de factures et devis.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Prestations
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Prestations favorites", systemImage: "star")
                        .font(.headline)

                    if company.prestations.isEmpty {
                        HStack {
                            Image(systemName: "tray")
                                .foregroundStyle(.secondary)
                            Text("Aucune prestation configuree")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    // Header
                    if !company.prestations.isEmpty {
                        HStack(spacing: 10) {
                            Text("Designation")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Prix")
                                .frame(width: 80, alignment: .trailing)
                            Text("TVA")
                                .frame(width: 75, alignment: .center)
                            Spacer().frame(width: 28)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                        Divider()
                    }

                    ForEach(company.prestations) { preset in
                        PrestationRow(presetId: preset.id, company: company, dataStore: dataStore)
                    }

                    Button {
                        company.prestations.append(DesignationPreset())
                        dataStore.save()
                    } label: {
                        Label("Ajouter une prestation", systemImage: "plus.circle")
                    }
                }
                .padding(12)
            }

            Spacer()
        }
        .padding(24)
    }
}

/// Ligne prestation avec acces securise par ID
private struct PrestationRow: View {
    let presetId: UUID
    let company: CompanyInfo
    let dataStore: DataStore

    private static let tvaRates: [Decimal] = [0, 5.5, 10, 20]

    private func safeIndex() -> Int? {
        company.prestations.firstIndex(where: { $0.id == presetId })
    }

    var body: some View {
        if company.prestations.contains(where: { $0.id == presetId }) {
            HStack(spacing: 10) {
                TextField("Designation", text: Binding(
                    get: { company.prestations.first(where: { $0.id == presetId })?.designation ?? "" },
                    set: { newVal in
                        if let i = safeIndex() { company.prestations[i].designation = newVal; dataStore.save() }
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)

                DecimalField(
                    placeholder: "Prix",
                    value: Binding(
                        get: { company.prestations.first(where: { $0.id == presetId })?.prixUnitaire ?? 0 },
                        set: { newVal in
                            if let i = safeIndex() { company.prestations[i].prixUnitaire = newVal; dataStore.save() }
                        }
                    )
                )
                .frame(width: 80)

                Picker("TVA", selection: Binding(
                    get: { company.prestations.first(where: { $0.id == presetId })?.tauxTVA ?? 0 },
                    set: { newVal in
                        if let i = safeIndex() { company.prestations[i].tauxTVA = newVal; dataStore.save() }
                    }
                )) {
                    ForEach(Self.tvaRates, id: \.self) { rate in
                        Text("\(NSDecimalNumber(decimal: rate))%").tag(rate)
                    }
                }
                .labelsHidden()
                .frame(width: 75)

                Button {
                    company.prestations.removeAll { $0.id == presetId }
                    dataStore.save()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
