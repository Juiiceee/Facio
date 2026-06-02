import SwiftUI

/// Scène de réglages native (Cmd-,). Rend la même surface canonique que
/// l'onglet Réglages intégré, pour une seule source de vérité (tous les
/// onglets présents, plus de fenêtre figée 500×480).
struct SettingsView: View {
    @State private var selectedTab = 0

    var body: some View {
        SettingsInlineView(selectedTab: $selectedTab)
            .frame(
                minWidth: 720, idealWidth: 880,
                minHeight: 520, idealHeight: 660
            )
    }
}
