import SwiftUI

// MARK: - Layout tokens

/// Tokens de layout de Facio : espacements, rayons et largeurs.
///
/// Règle d'or : aucune valeur magique dans les vues. Toute dimension
/// (padding, spacing, cornerRadius, largeur de colonne ou de champ) passe par
/// l'un de ces tokens. Les couleurs de surface et de bordure vivent dans
/// `Color+Theme` (`surfacePanel`, `borderSubtle`, …), la typo dans `FacioFont`.
enum FacioLayout {
    // MARK: Échelle d'espacement — 7 crans, TOUS multiples de 4
    //
    // L'ancienne échelle annonçait une grille de 4 pt et contenait 2, 6, 10, 14,
    // 18 et 20 : c'était une grille de 2 pt à 10 crans, et 8/10/12 se partageaient
    // le même travail. Les crans hors grille disparaissent, et l'ancien « entre
    // sections 18 » fusionne avec l'ancien « écran 24 ».
    /// Écart entre deux éléments d'une même ligne.
    static let space4: CGFloat = 4
    /// Écart entre les éléments d'une ligne de liste.
    static let space8: CGFloat = 8
    /// Écart à l'intérieur d'une tuile.
    static let space12: CGFloat = 12
    /// Écart à l'intérieur d'un panneau.
    static let space16: CGFloat = 16
    /// Marge d'écran, et écart entre deux sections.
    static let space24: CGFloat = 24
    /// Écart entre deux blocs majeurs.
    static let space32: CGFloat = 32
    /// Respiration d'un état vide.
    static let space40: CGFloat = 40

    /// Marge intérieure d'un écran.
    static let screenPadding: CGFloat = space24
    /// Espacement vertical entre sections d'un écran.
    static let sectionSpacing: CGFloat = space24
    /// Padding intérieur d'un panneau / d'une carte.
    static let panelPadding: CGFloat = space16
    /// Padding intérieur d'une tuile.
    static let tilePadding: CGFloat = space12
    /// Padding intérieur d'une ligne de liste.
    static let rowPadding: CGFloat = space8

    // Crans hors grille, ramenés au multiple de 4 le plus proche (à égalité, on
    // arrondit vers le haut). Conservés le temps de migrer les appels.
    static let space2: CGFloat = space4
    static let space6: CGFloat = space8
    static let space10: CGFloat = space12
    static let space20: CGFloat = space24

    // MARK: Rayons — 3 valeurs
    //
    // Cinq noms pour trois valeurs séparées de 1 pt : le coût cognitif était réel,
    // le bénéfice visuel nul. Et le badge existait en deux formes concurrentes
    // (rectangle 6 pt contre capsule) sans règle — seule la capsule survit.
    /// Champ, bouton.
    static let radiusSmall: CGFloat = 5
    /// Panneau, tuile, ligne.
    static let radiusMedium: CGFloat = 8
    /// Badge, pilule — une capsule, toujours.
    static let radiusFull: CGFloat = 999

    static let radiusField: CGFloat = radiusSmall
    static let radiusRow: CGFloat = radiusMedium
    static let radiusTile: CGFloat = radiusMedium
    static let radiusPanel: CGFloat = radiusMedium
    static let radiusBadge: CGFloat = radiusFull

    // Conservés pour compatibilité (alias des rayons nommés).
    static let panelRadius: CGFloat = radiusMedium
    static let rowRadius: CGFloat = radiusMedium

    // MARK: Densité
    //
    // Seuls les champs avaient deux densités ; panneaux, lignes, tuiles, badges
    // et boutons n'avaient qu'une taille, d'où les bricolages du tableau de
    // lignes et de la grille d'heures, qui définissaient leurs propres largeurs
    // HORS du design system.
    //
    // Le dense plafonne à 28 pt : c'est la cible de clic minimale que le design
    // system s'impose déjà. La cellule d'heures à 24 pt devient donc illégale.
    enum Density {
        case comfortable
        case dense

        /// Hauteur d'une ligne de liste.
        var rowHeight: CGFloat { self == .comfortable ? 36 : 28 }
        /// Hauteur d'un champ et d'un bouton.
        var controlHeight: CGFloat { self == .comfortable ? 30 : 28 }
        /// Hauteur d'une capsule.
        var badgeHeight: CGFloat { self == .comfortable ? 22 : 20 }
        /// Padding intérieur d'un panneau.
        var panelPadding: CGFloat { self == .comfortable ? space16 : space12 }
        /// Padding intérieur d'une tuile.
        var tilePadding: CGFloat { space12 }
    }

    /// Densité par défaut de l'application.
    static let density: Density = .comfortable

    // MARK: Largeurs
    /// Largeur standard d'un champ « court » (montants, codes, pickers).
    static let fieldWidth: CGFloat = 200
    /// Cap de lisibilité pour le contenu d'une colonne de détail.
    static let contentMaxWidth: CGFloat = 760
    /// Largeur d'un formulaire d'édition centré.
    static let formMaxWidth: CGFloat = 680

    /// Cible de clic minimale pour un bouton-icône.
    static let iconHitTarget: CGFloat = 28

    // MARK: Colonnes & fenêtre (min / ideal / max)
    static let sidebarMin: CGFloat = 200
    static let sidebarIdeal: CGFloat = 230
    static let sidebarMax: CGFloat = 300

    static let contentColumnMin: CGFloat = 300
    static let contentColumnIdeal: CGFloat = 320
    static let contentColumnMax: CGFloat = 400

    /// Largeur de la colonne liste quand elle est repliée en rail. La colonne
    /// ne disparaît jamais : c'est ce qui évite de reconstruire le châssis.
    static let contentRailWidth: CGFloat = 44

    static let detailMin: CGFloat = 460

    static let inspectorMin: CGFloat = 260
    static let inspectorIdeal: CGFloat = 300
    static let inspectorMax: CGFloat = 360
    /// Conservé pour compatibilité.
    static let inspectorWidth: CGFloat = 280

    /// Largeur en deçà de laquelle l'inspecteur du document est masqué.
    /// Alias historique de `breakpointWide`.
    static let documentInspectorBreakpoint: CGFloat = breakpointWide

    static let windowMinWidth: CGFloat = 960
    static let windowMinHeight: CGFloat = 640
    static let windowIdealWidth: CGFloat = 1280
    static let windowIdealHeight: CGFloat = 820

    // MARK: Breakpoints responsive (FacioWidthClass)
    /// En deçà : layouts compacts (piles verticales, sidebars repliées).
    static let breakpointCompact: CGFloat = 640
    /// Au-delà : layouts larges (inspecteur latéral visible).
    static let breakpointWide: CGFloat = 1120
    /// Largeur minimale d'un champ dans une `FormGrid`.
    static let fieldMinWidth: CGFloat = 150
    /// Largeur de conteneur sous laquelle le tableau de lignes passe en mode compact.
    /// (Relevé pour absorber la colonne « Total TTC » sans rogner la désignation.)
    static let lineItemsCompactBreakpoint: CGFloat = 820
    /// Cap de largeur du panneau de totaux (pleine largeur en compact).
    static let totalsMaxWidth: CGFloat = 350

    // MARK: Sheets (invariant : min ≤ fenêtre min − 80 par dimension)
    static let sheetMinWidth: CGFloat = 480
    static let sheetIdealWidth: CGFloat = 600
    static let sheetMinHeight: CGFloat = 360
    static let sheetIdealHeight: CGFloat = 520

    // MARK: Sidebar des réglages
    static let settingsSidebarWidth: CGFloat = 230
    static let settingsSidebarCompactWidth: CGFloat = 64

    // MARK: Verrouillage par code
    /// Côté d'une case de saisie du code.
    static let passcodeDotSize: CGFloat = 18
    /// Côté d'une touche du pavé numérique.
    static let passcodeKeySize: CGFloat = 54
    /// Largeur du panneau centré de l'écran de verrouillage.
    static let lockPanelWidth: CGFloat = 320
    /// Pastille ronde portant le cadenas, en tête de l'écran de verrouillage.
    static let lockBadgeSize: CGFloat = 56
}

// MARK: - Intent / tone

/// Tonalité sémantique partagée par les bannières, badges et accents.
/// Adossée à la palette d'intention unique de `Color+Theme`.
enum InlineTone {
    case info
    case success
    case warning
    case danger

    /// Les quatre rôles de cette tonalité. Point d'entrée unique des composants :
    /// un composant ne choisit plus une couleur, il choisit un rôle.
    var intent: FacioIntent { Color.intent(for: self) }

    /// Aplat. Conservé pour les appels qui posent la couleur sur un fond neutre ;
    /// pour une marque sans texte, préférer `intent.glyph`.
    var color: Color { intent.fill }

    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .danger: return "xmark.octagon"
        }
    }
}

// MARK: - Panels & cards

/// Chrome partagé des panneaux et tuiles : fond, bordure discrète, coins arrondis.
/// Remplace les blocs `background + overlay + clipShape` dupliqués dans les vues.
struct FacioCardChrome: ViewModifier {
    var surface: Color = .surfaceRaised
    var radius: CGFloat = FacioLayout.radiusMedium

    func body(content: Content) -> some View {
        // Délègue au plan e1 : surface opaque, contour de raffinement et ombre
        // en clair, luminance seule en sombre. Le chrome n'est plus rejoué ici.
        content.facioElevation(.e1, radius: radius, surface: surface)
    }
}

extension View {
    func facioCardChrome(surface: Color = .surfaceRaised, radius: CGFloat = FacioLayout.radiusMedium) -> some View {
        modifier(FacioCardChrome(surface: surface, radius: radius))
    }
}

/// Présentation d'un panneau.
enum FacioPanelStyle {
    /// Carte : fond, contour, élévation. Le cas courant.
    case card
    /// Sans chrome : pour les groupes qui ne SONT pas des objets. « Saisie des
    /// heures » et son segmenté n'ont pas à se présenter comme une carte —
    /// c'était pourtant la seule rangée nue de son écran, sans conteneur du tout.
    case plain
}

/// Panneau de section — le conteneur le plus utilisé de l'app (61 usages).
///
/// Trois variantes : titrée, sans chrome, et repliable. Le titre accepte une
/// **action de droite** : c'est là que remontent les « + » et les « Voir tout »
/// aujourd'hui absents, ou perdus en bas de panneau après la liste qu'ils
/// commandent.
struct SectionPanel<Content: View, Accessory: View>: View {
    let title: String?
    let systemImage: String?
    var style: FacioPanelStyle = .card
    /// Compteur affiché à côté du titre (« Justificatifs · 3 »).
    var count: Int?
    /// Rend le panneau repliable. L'état vit dans le panneau.
    var isCollapsible: Bool = false
    let accessory: Accessory
    let content: Content

    @State private var isExpanded = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        _ title: String? = nil,
        systemImage: String? = nil,
        style: FacioPanelStyle = .card,
        count: Int? = nil,
        isCollapsible: Bool = false,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.count = count
        self.isCollapsible = isCollapsible
        self.accessory = accessory()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space16) {
            if title != nil || Accessory.self != EmptyView.self {
                header
            }
            if isExpanded || !isCollapsible {
                content
            }
        }
        .padding(style == .card ? FacioLayout.density.panelPadding : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(FacioPanelChrome(style: style))
    }

    private var header: some View {
        HStack(spacing: FacioLayout.space8) {
            if isCollapsible {
                Image(systemName: "chevron.right")
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .accessibilityHidden(true)
            }
            if let title {
                Label(title, systemImage: systemImage ?? "square.grid.2x2")
                    .font(FacioFont.titleSection)
                    .foregroundStyle(Color.textPrimary)
                    .labelStyle(.titleAndIcon)
            }
            if let count {
                Text("\(count)")
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, FacioLayout.space8)
                    .frame(minHeight: FacioLayout.density.badgeHeight - FacioLayout.space4)
                    .background(Color.surfaceSunken)
                    .clipShape(Capsule())
            }
            Spacer(minLength: FacioLayout.space8)
            accessory
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isCollapsible else { return }
            withAnimation(FacioMotion.respecting(FacioMotion.state, reduceMotion: reduceMotion)) {
                isExpanded.toggle()
            }
        }
    }
}

/// Chrome du panneau, isolé pour que la variante `plain` n'ait ni fond, ni
/// contour, ni élévation — et pas simplement un fond transparent.
private struct FacioPanelChrome: ViewModifier {
    let style: FacioPanelStyle

    func body(content: Content) -> some View {
        switch style {
        case .card: content.facioElevation(.e1, radius: FacioLayout.radiusMedium)
        case .plain: content
        }
    }
}

// Les 61 appels existants ne passent pas d'accessoire : cette surcharge garde
// leur signature intacte.
extension SectionPanel where Accessory == EmptyView {
    init(
        _ title: String? = nil,
        systemImage: String? = nil,
        style: FacioPanelStyle = .card,
        count: Int? = nil,
        isCollapsible: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title,
            systemImage: systemImage,
            style: style,
            count: count,
            isCollapsible: isCollapsible,
            accessory: { EmptyView() },
            content: content
        )
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    var subtitle: String?
    let systemImage: String
    /// La tuile prend une intention, plus une couleur nue : le filet et l'icône
    /// sont des marques (valeur vive), la pastille d'icône un fond teinté.
    /// Auparavant une seule couleur servait aux trois, dont un fond à 10 % d'un
    /// aplat sombre — un gris sale.
    let intent: FacioIntent
    /// Tendance optionnelle vs période précédente.
    var trend: MetricTrend?
    // `emphasized` a disparu : la refonte typographique a fusionné `heroValue`
    // et `metricValue` sur le même pas de 28 pt, le drapeau ne changeait donc
    // plus rien — et aucune vue ne l'utilisait.

    var body: some View {
        HStack(alignment: .top, spacing: FacioLayout.space12) {
            RoundedRectangle(cornerRadius: FacioLayout.space4)
                .fill(intent.glyph)
                .frame(width: 3)
                .padding(.vertical, FacioLayout.space4)

            VStack(alignment: .leading, spacing: FacioLayout.space8) {
                Text(title)
                    .font(FacioFont.secondary)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                Text(value)
                    .font(FacioFont.metric)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if let trend {
                    trend.label
                } else if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(FacioFont.label)
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(" ")
                        .font(FacioFont.label)
                        .lineLimit(2)
                        .hidden()
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(intent.glyph)
                .frame(width: 30, height: 30)
                .background(intent.tint)
                .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusMedium))
        }
        .padding(FacioLayout.tilePadding)
        .frame(maxWidth: .infinity, minHeight: 128, maxHeight: 148, alignment: .topLeading)
        .facioCardChrome(surface: .surfaceSunken)
    }
}

/// Tendance d'une métrique (delta vs période précédente).
struct MetricTrend {
    let text: String
    let direction: Direction

    enum Direction { case up, down, flat }

    @ViewBuilder var label: some View {
        // Flèche + delta : une marque, pas un paragraphe. Elle prend donc la
        // valeur vive et non l'aplat calé sur le seuil du texte.
        let (icon, color): (String, Color) = {
            switch direction {
            case .up: return ("arrow.up.right", Color.intentSuccessTriple.glyph)
            case .down: return ("arrow.down.right", Color.intentDangerTriple.glyph)
            case .flat: return ("arrow.right", Color.textSecondary)
            }
        }()
        HStack(spacing: FacioLayout.space4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(FacioFont.label)
        .foregroundStyle(color)
        .lineLimit(1)
    }
}

/// Tuile d'action cliquable (icône + titre + sous-titre + chevron).
/// Utilisée pour les raccourcis (dashboard, fiche client).
struct ActionTile: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    var tone: InlineTone = .info
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FacioLayout.space12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tone.intent.glyph)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: FacioLayout.space4) {
                    Text(title)
                        .font(FacioFont.rowTitle)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(FacioFont.secondary)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(FacioLayout.rowPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        // Survol partagé : l'état, l'animation et les deux couleurs vivent
        // désormais dans un seul modificateur au lieu d'être réécrits ici.
        .facioHoverable(radius: FacioLayout.radiusMedium)
    }
}

struct FacioListRow<Content: View>: View {
    var tone: Color = .primary
    let content: Content

    init(tone: Color = .textPrimary, @ViewBuilder content: () -> Content) {
        self.tone = tone
        self.content = content()
    }

    var body: some View {
        HStack(spacing: FacioLayout.space12) {
            // Le filet perdait 25 % d'opacité sur une surface non définie ; il
            // porte maintenant sa couleur pleine sur un plan opaque.
            RoundedRectangle(cornerRadius: FacioLayout.space4)
                .fill(tone)
                .frame(width: 3)
            content
        }
        .padding(FacioLayout.rowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .facioHoverable(radius: FacioLayout.radiusMedium)
    }
}

// MARK: - Inline feedback

struct InlineWarning: View {
    let text: String
    var tone: InlineTone = .warning

    var body: some View {
        // Le fond était l'aplat à 9 % d'opacité et le texte le MÊME aplat : un
        // contraste que rien ne garantissait. Fond et texte viennent désormais
        // de la paire mesurée `tint` / `onTint` ; seule l'icône, qui ne porte
        // pas de texte, prend la valeur vive.
        HStack(alignment: .top, spacing: FacioLayout.space8) {
            Image(systemName: tone.icon)
                .foregroundStyle(tone.intent.glyph)
            Text(text)
                .font(FacioFont.secondary)
                .foregroundStyle(tone.intent.onTint)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(FacioLayout.space8)
        .background(tone.intent.tint)
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusSmall))
    }
}

struct ChecklistRow: View {
    let title: String
    var detail: String?
    let isComplete: Bool

    var body: some View {
        HStack(alignment: .top, spacing: FacioLayout.space8) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? Color.intentSuccessTriple.glyph : Color.textTertiary)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: FacioLayout.space4) {
                Text(title)
                    .font(FacioFont.secondary)
                    .foregroundStyle(Color.textPrimary)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(FacioFont.label)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Inspector

struct InspectorPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FacioLayout.space16) {
                content
            }
            .padding(FacioLayout.tilePadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(
            minWidth: FacioLayout.inspectorMin,
            idealWidth: FacioLayout.inspectorIdeal,
            maxWidth: FacioLayout.inspectorMax
        )
        .background(Color.surfaceInspector)
    }
}
