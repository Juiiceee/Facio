import SwiftUI

/// Classe de largeur d'un conteneur : pilote les bascules de layout
/// (HStack→VStack, colonnes de grilles, sidebars repliées).
///
/// Règles d'usage :
/// - `ViewThatFits` UNIQUEMENT quand toutes les variantes ont une taille
///   intrinsèque (Texts, Labels, Pickers, DatePickers) — dès qu'un TextField
///   est présent (compressible à l'infini), passer par `facioWidthClass` /
///   `AdaptiveStack` / `FormGrid`.
/// - Tout conteneur dont la largeur réelle diffère de la colonne détail
///   (ex : éditeur avec inspecteur latéral) re-pose `.facioResponsiveContainer()`.
enum FacioWidthClass: Equatable {
    case compact
    case regular
    case wide

    init(width: CGFloat) {
        if width < FacioLayout.breakpointCompact {
            self = .compact
        } else if width >= FacioLayout.breakpointWide {
            self = .wide
        } else {
            self = .regular
        }
    }
}

// EnvironmentKeys manuelles : le macro @Entry exige le plugin SwiftUIMacros,
// absent des builds SPM en ligne de commande.
private struct FacioWidthClassKey: EnvironmentKey {
    static var defaultValue: FacioWidthClass { .regular }
}

private struct FacioContainerWidthKey: EnvironmentKey {
    static var defaultValue: CGFloat { FacioLayout.windowIdealWidth }
}

extension EnvironmentValues {
    /// Classe de largeur posée par le conteneur responsive le plus proche.
    var facioWidthClass: FacioWidthClass {
        get { self[FacioWidthClassKey.self] }
        set { self[FacioWidthClassKey.self] = newValue }
    }

    /// Largeur réelle du conteneur responsive le plus proche.
    var facioContainerWidth: CGFloat {
        get { self[FacioContainerWidthKey.self] }
        set { self[FacioContainerWidthKey.self] = newValue }
    }
}

/// Mesure la largeur du conteneur et la propage dans l'environnement.
private struct FacioResponsiveContainer: ViewModifier {
    @State private var width: CGFloat = FacioLayout.windowIdealWidth

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { width = $0 }
            .environment(\.facioWidthClass, FacioWidthClass(width: width))
            .environment(\.facioContainerWidth, width)
    }
}

extension View {
    func facioResponsiveContainer() -> some View {
        modifier(FacioResponsiveContainer())
    }
}

/// HStack en largeur confortable, VStack en compact. `AnyLayout` préserve
/// l'identité des sous-vues : le focus d'un champ survit au changement.
struct AdaptiveStack<Content: View>: View {
    var hSpacing: CGFloat = FacioLayout.space12
    var vSpacing: CGFloat = FacioLayout.space10
    /// Alignement vertical en mode rangée — `.center` comme les HStack natifs
    /// que ce conteneur remplace.
    var hAlignment: VerticalAlignment = .center
    @ViewBuilder let content: Content

    @Environment(\.facioWidthClass) private var widthClass

    var body: some View {
        let layout = widthClass == .compact
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: vSpacing))
            : AnyLayout(HStackLayout(alignment: hAlignment, spacing: hSpacing))
        layout { content }
    }
}

/// Grille de formulaire adaptative : les champs wrappent naturellement quand
/// la largeur se réduit. Réservée aux petits groupes (≤ 8 champs) rendus d'un
/// bloc — LazyVGrid peut décharger l'état local des cellules hors écran.
struct FormGrid<Content: View>: View {
    var minimum: CGFloat = FacioLayout.fieldMinWidth
    var maximum: CGFloat = .infinity
    var spacing: CGFloat = FacioLayout.space12
    @ViewBuilder let content: Content

    init(
        minimum: CGFloat = FacioLayout.fieldMinWidth,
        maximum: CGFloat = .infinity,
        spacing: CGFloat = FacioLayout.space12,
        @ViewBuilder content: () -> Content
    ) {
        self.minimum = minimum
        self.maximum = maximum
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimum, maximum: maximum), alignment: .topLeading)],
            alignment: .leading,
            spacing: spacing
        ) {
            content
        }
    }
}
