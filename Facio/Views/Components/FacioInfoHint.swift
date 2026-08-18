import SwiftUI

/// Une explication qui ne déforme pas la mise en page.
///
/// Les aides étaient rendues SOUS leur champ. Comme elles n'ont pas toutes la
/// même longueur — ni toutes une aide — chaque champ d'une même rangée prenait
/// une hauteur différente, et « Seuil hebdo » se retrouvait 40 pt plus haut que
/// « Taux normal » dans la même grille. L'explication vit donc à côté du
/// libellé : survol pour l'infobulle, clic pour la garder ouverte.
struct FacioInfoHint: View {
    let text: String
    /// Titre annoncé aux technologies d'assistance, qui ne survolent rien.
    var label: String

    @State private var isPresented = false

    init(_ text: String, label: String) {
        self.text = text
        self.label = label
    }

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(FacioFont.label)
                .foregroundStyle(Color.textTertiary)
        }
        .buttonStyle(.plain)
        .help(text)
        .accessibilityLabel(label)
        .accessibilityHint(text)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            Text(text)
                .font(FacioFont.secondary)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(FacioLayout.space12)
                .frame(maxWidth: 260, alignment: .leading)
        }
    }
}
