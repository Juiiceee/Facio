import SwiftUI

// MARK: - Layout tokens

/// Tokens de layout de Facio : espacements, rayons et largeurs.
///
/// Règle d'or : aucune valeur magique dans les vues. Toute dimension
/// (padding, spacing, cornerRadius, largeur de colonne ou de champ) passe par
/// l'un de ces tokens. Les couleurs de surface et de bordure vivent dans
/// `Color+Theme` (`surfacePanel`, `borderSubtle`, …), la typo dans `FacioFont`.
enum FacioLayout {
    // MARK: Échelle d'espacement (grille 4 pt)
    static let space2: CGFloat = 2
    static let space4: CGFloat = 4
    static let space6: CGFloat = 6
    static let space8: CGFloat = 8
    static let space10: CGFloat = 10
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space20: CGFloat = 20
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32

    /// Marge intérieure d'un écran.
    static let screenPadding: CGFloat = 24
    /// Espacement vertical entre sections d'un écran.
    static let sectionSpacing: CGFloat = 18
    /// Padding intérieur d'un panneau / d'une carte.
    static let panelPadding: CGFloat = 16
    /// Padding intérieur d'une tuile.
    static let tilePadding: CGFloat = 14
    /// Padding intérieur d'une ligne de liste.
    static let rowPadding: CGFloat = 10

    // MARK: Rayons nommés
    static let radiusField: CGFloat = 6
    static let radiusBadge: CGFloat = 6
    static let radiusRow: CGFloat = 7
    static let radiusTile: CGFloat = 7
    static let radiusPanel: CGFloat = 8

    // Conservés pour compatibilité (alias des rayons nommés).
    static let panelRadius: CGFloat = 8
    static let rowRadius: CGFloat = 7

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
}

// MARK: - Intent / tone

/// Tonalité sémantique partagée par les bannières, badges et accents.
/// Adossée à la palette d'intention unique de `Color+Theme`.
enum InlineTone {
    case info
    case success
    case warning
    case danger

    var color: Color {
        switch self {
        case .info: return .intentInfo
        case .success: return .intentSuccess
        case .warning: return .intentWarning
        case .danger: return .intentDanger
        }
    }

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
    var surface: Color = .surfacePanel
    var radius: CGFloat = FacioLayout.radiusPanel

    func body(content: Content) -> some View {
        content
            .background(surface)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Color.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

extension View {
    func facioCardChrome(surface: Color = .surfacePanel, radius: CGFloat = FacioLayout.radiusPanel) -> some View {
        modifier(FacioCardChrome(surface: surface, radius: radius))
    }
}

struct SectionPanel<Content: View>: View {
    let title: String?
    let systemImage: String?
    let content: Content

    init(_ title: String? = nil, systemImage: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space16) {
            if let title {
                Label(title, systemImage: systemImage ?? "square.grid.2x2")
                    .font(FacioFont.sectionTitle)
                    .foregroundStyle(.primary)
                    .labelStyle(.titleAndIcon)
            }
            content
        }
        .padding(FacioLayout.panelPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .facioCardChrome()
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    var subtitle: String?
    let systemImage: String
    let color: Color
    /// Variante mise en avant (KPI principal) : valeur plus grande.
    var emphasized: Bool = false
    /// Tendance optionnelle vs période précédente.
    var trend: MetricTrend?

    var body: some View {
        HStack(alignment: .top, spacing: FacioLayout.space12) {
            RoundedRectangle(cornerRadius: FacioLayout.space2)
                .fill(color)
                .frame(width: 3)
                .padding(.vertical, FacioLayout.space2)

            VStack(alignment: .leading, spacing: FacioLayout.space6) {
                Text(title)
                    .font(FacioFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(value)
                    .font(emphasized ? FacioFont.heroValue : FacioFont.metricValue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if let trend {
                    trend.label
                } else if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(FacioFont.captionSmall)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(" ")
                        .font(FacioFont.captionSmall)
                        .lineLimit(2)
                        .hidden()
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusTile))
        }
        .padding(FacioLayout.tilePadding)
        .frame(maxWidth: .infinity, minHeight: 128, maxHeight: 148, alignment: .topLeading)
        .facioCardChrome(surface: .surfaceTile)
    }
}

/// Tendance d'une métrique (delta vs période précédente).
struct MetricTrend {
    let text: String
    let direction: Direction

    enum Direction { case up, down, flat }

    @ViewBuilder var label: some View {
        let (icon, color): (String, Color) = {
            switch direction {
            case .up: return ("arrow.up.right", .intentSuccess)
            case .down: return ("arrow.down.right", .intentDanger)
            case .flat: return ("arrow.right", .secondary)
            }
        }()
        HStack(spacing: FacioLayout.space4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(FacioFont.captionSmall)
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

    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: FacioLayout.space12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tone.color)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: FacioLayout.space2) {
                    Text(title)
                        .font(FacioFont.rowTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(FacioFont.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(FacioLayout.rowPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
        }
        .buttonStyle(.plain)
        .background(isHovering ? Color.surfaceRowHover : Color.surfaceTile)
        .overlay(
            RoundedRectangle(cornerRadius: FacioLayout.radiusPanel)
                .strokeBorder(isHovering ? Color.borderHover : Color.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
        .animation(FacioMotion.respecting(FacioMotion.hover, reduceMotion: reduceMotion), value: isHovering)
        .onHover { isHovering = $0 }
    }
}

struct FacioListRow<Content: View>: View {
    var tone: Color = .primary
    let content: Content

    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(tone: Color = .primary, @ViewBuilder content: () -> Content) {
        self.tone = tone
        self.content = content()
    }

    var body: some View {
        HStack(spacing: FacioLayout.space10) {
            RoundedRectangle(cornerRadius: FacioLayout.space2)
                .fill(tone.opacity(0.75))
                .frame(width: 3)
            content
        }
        .padding(FacioLayout.rowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovering ? Color.surfaceRowHover : Color.surfaceRow)
        .overlay(
            RoundedRectangle(cornerRadius: FacioLayout.radiusRow)
                .strokeBorder(isHovering ? Color.borderHover : Color.borderHairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusRow))
        .contentShape(RoundedRectangle(cornerRadius: FacioLayout.radiusRow))
        .animation(FacioMotion.respecting(FacioMotion.hover, reduceMotion: reduceMotion), value: isHovering)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Inline feedback

struct InlineWarning: View {
    let text: String
    var tone: InlineTone = .warning

    var body: some View {
        HStack(alignment: .top, spacing: FacioLayout.space8) {
            Image(systemName: tone.icon)
                .foregroundStyle(tone.color)
            Text(text)
                .font(FacioFont.caption)
                .foregroundStyle(tone.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(FacioLayout.space8)
        .background(tone.color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusField))
    }
}

struct ChecklistRow: View {
    let title: String
    var detail: String?
    let isComplete: Bool

    var body: some View {
        HStack(alignment: .top, spacing: FacioLayout.space8) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? Color.intentSuccess : .secondary)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: FacioLayout.space2) {
                Text(title)
                    .font(FacioFont.caption)
                    .foregroundStyle(.primary)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(FacioFont.captionSmall)
                        .foregroundStyle(.secondary)
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
