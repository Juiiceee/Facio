import SwiftUI

/// Une option de tri pour `FacioListControls` (clé stable + libellé localisé).
struct FacioSortOption: Identifiable, Equatable {
    let id: String
    let label: String
}

/// Barre **Trier & Filtrer** partagée par les listes (factures, devis, clients).
///
/// Tokenisée. Chaque liste fournit :
/// - ses options de tri (le menu montre toujours le critère actif + le sens ↑/↓) ;
/// - un **panneau de filtres** (style Notion) affiché dans un popover via le
///   bouton « Filtrer », avec un compteur de filtres actifs.
struct FacioListControls<FilterPanel: View>: View {
    let lang: AppLanguage
    var accent: Color = .accentColor
    let sortOptions: [FacioSortOption]
    @Binding var sortKey: String
    @Binding var sortAscending: Bool
    var filterActiveCount: Int = 0
    @ViewBuilder var filterPanel: () -> FilterPanel

    @State private var showFilter = false

    private var currentSortLabel: String {
        sortOptions.first { $0.id == sortKey }?.label ?? ""
    }

    var body: some View {
        HStack(spacing: FacioLayout.space8) {
            sortMenu
            filterButton
            Spacer(minLength: 0)
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
            pill(active: false) {
                Image(systemName: "arrow.up.arrow.down")
                Text(currentSortLabel).lineLimit(1)
                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help(L10n.sortBy(lang))
    }

    // MARK: - Filtre

    private var filterButton: some View {
        Button {
            showFilter = true
        } label: {
            pill(active: filterActiveCount > 0) {
                Image(systemName: "line.3.horizontal.decrease")
                Text(L10n.filterButton(lang))
                if filterActiveCount > 0 {
                    Text("\(filterActiveCount)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(accent, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .help(L10n.filterButton(lang))
        .popover(isPresented: $showFilter, arrowEdge: .bottom) {
            filterPanel()
        }
    }

    // MARK: - Style commun (pilule)

    @ViewBuilder
    private func pill<Content: View>(active: Bool, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: FacioLayout.space4) {
            content()
        }
        .font(FacioFont.captionSmall)
        .fontWeight(.medium)
        .foregroundStyle(active ? accent : Color.primary)
        .padding(.horizontal, FacioLayout.space10)
        .padding(.vertical, FacioLayout.space6)
        .background((active ? accent : Color.secondary).opacity(active ? 0.16 : 0.12))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(accent.opacity(active ? 0.5 : 0), lineWidth: 1))
        .contentShape(Capsule())
    }
}
