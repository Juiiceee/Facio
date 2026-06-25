import SwiftUI

/// Une option de tri pour `FacioListControls` (clé stable + libellé localisé).
struct FacioSortOption: Identifiable, Equatable {
    let id: String
    let label: String
}

/// Un chip de filtre pour `FacioListControls` (clé stable + libellé + couleur
/// d'accent quand il est actif).
struct FacioFilterChip: Identifiable, Equatable {
    let id: String
    let label: String
    var tone: Color?
}

/// Barre **Trier & Filtrer** partagée par les listes (factures, devis, clients).
///
/// Entièrement tokenisée. Chaque liste fournit ses options de tri et ses chips
/// de filtre ; le composant gère l'affichage et l'interaction :
/// - **Tri** : un menu compact montrant toujours le critère actif et le sens (↑/↓).
/// - **Filtres** : des chips cumulables (OU) ; le chip « Toutes » réinitialise.
struct FacioListControls: View {
    let lang: AppLanguage
    var accent: Color = .accentColor
    let sortOptions: [FacioSortOption]
    @Binding var sortKey: String
    @Binding var sortAscending: Bool
    var filterChips: [FacioFilterChip] = []
    @Binding var activeFilters: Set<String>

    private static let allID = "__all__"

    private var currentSortLabel: String {
        sortOptions.first { $0.id == sortKey }?.label ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space8) {
            HStack(spacing: FacioLayout.space8) {
                sortMenu
                Spacer(minLength: 0)
                if !activeFilters.isEmpty {
                    Button {
                        activeFilters.removeAll()
                    } label: {
                        Label(L10n.clearFilters(lang), systemImage: "xmark.circle.fill")
                            .font(FacioFont.captionSmall)
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help(L10n.clearFilters(lang))
                }
            }

            if !filterChips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FacioLayout.space6) {
                        chipButton(FacioFilterChip(id: Self.allID, label: L10n.filterAll(lang), tone: nil))
                        ForEach(filterChips) { chipButton($0) }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(.horizontal, FacioLayout.screenPadding)
        .padding(.vertical, FacioLayout.space8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Tri

    private var sortMenu: some View {
        Menu {
            ForEach(sortOptions) { option in
                Button {
                    sortKey = option.id
                } label: {
                    if sortKey == option.id {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
            }
            Divider()
            Picker(L10n.sortDirection(lang), selection: $sortAscending) {
                Label(L10n.sortAscending(lang), systemImage: "arrow.up").tag(true)
                Label(L10n.sortDescending(lang), systemImage: "arrow.down").tag(false)
            }
        } label: {
            HStack(spacing: FacioLayout.space4) {
                Image(systemName: "arrow.up.arrow.down")
                Text(currentSortLabel)
                    .lineLimit(1)
                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .font(FacioFont.captionSmall)
            .fontWeight(.medium)
            .padding(.horizontal, FacioLayout.space10)
            .padding(.vertical, FacioLayout.space6)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(L10n.sortBy(lang))
    }

    // MARK: - Filtres

    private func chipButton(_ chip: FacioFilterChip) -> some View {
        let isAll = chip.id == Self.allID
        let isActive = isAll ? activeFilters.isEmpty : activeFilters.contains(chip.id)
        let tone = chip.tone ?? accent
        return Button {
            if isAll {
                activeFilters.removeAll()
            } else if activeFilters.contains(chip.id) {
                activeFilters.remove(chip.id)
            } else {
                activeFilters.insert(chip.id)
            }
        } label: {
            Text(chip.label)
                .font(FacioFont.captionSmall)
                .fontWeight(isActive ? .semibold : .regular)
                .lineLimit(1)
                .padding(.horizontal, FacioLayout.space10)
                .padding(.vertical, FacioLayout.space6)
                .foregroundStyle(isActive ? tone : Color.secondary)
                .background((isActive ? tone : Color.secondary).opacity(isActive ? 0.16 : 0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(tone.opacity(isActive ? 0.5 : 0), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
