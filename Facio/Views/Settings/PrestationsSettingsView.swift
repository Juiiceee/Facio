import SwiftUI

struct PrestationsSettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        VStack(spacing: 20) {
            // Info
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text(L10n.servicesInfo(lang))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Prestations
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.favoriteServices(lang), systemImage: "star")
                        .font(.headline)

                    if company.prestations.isEmpty {
                        HStack {
                            Image(systemName: "tray")
                                .foregroundStyle(.secondary)
                            Text(L10n.noServiceConfigured(lang))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    // Header
                    if !company.prestations.isEmpty {
                        HStack(spacing: 10) {
                            Text(L10n.designationLabel(lang))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(L10n.priceLabel(lang))
                                .frame(width: 80, alignment: .trailing)
                            Text(L10n.vatLabel(lang))
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
                        dataStore.companyUpdated()
                    } label: {
                        Label(L10n.addService(lang), systemImage: "plus.circle")
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

    private var lang: AppLanguage { company.langueParDefaut }

    private static let tvaRates: [Decimal] = [0, 5.5, 10, 20]

    private func safeIndex() -> Int? {
        company.prestations.firstIndex(where: { $0.id == presetId })
    }

    var body: some View {
        if company.prestations.contains(where: { $0.id == presetId }) {
            HStack(spacing: 10) {
                TextField(L10n.designationLabel(lang), text: Binding(
                    get: { company.prestations.first(where: { $0.id == presetId })?.designation ?? "" },
                    set: { newVal in
                        if let i = safeIndex() { company.prestations[i].designation = newVal; dataStore.companyUpdated() }
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)

                DecimalField(
                    placeholder: L10n.priceLabel(lang),
                    value: Binding(
                        get: { company.prestations.first(where: { $0.id == presetId })?.prixUnitaire ?? 0 },
                        set: { newVal in
                            if let i = safeIndex() { company.prestations[i].prixUnitaire = newVal; dataStore.companyUpdated() }
                        }
                    )
                )
                .frame(width: 80)

                Picker(L10n.vatLabel(lang), selection: Binding(
                    get: { company.prestations.first(where: { $0.id == presetId })?.tauxTVA ?? 0 },
                    set: { newVal in
                        if let i = safeIndex() { company.prestations[i].tauxTVA = newVal; dataStore.companyUpdated() }
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
                    dataStore.companyUpdated()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
