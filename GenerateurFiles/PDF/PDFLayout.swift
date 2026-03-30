import AppKit
import Foundation

/// Constantes de mise en page pour le PDF A4
@MainActor
struct PDFLayout {
    // MARK: - Dimensions A4
    static let pageWidth: CGFloat = 595.28
    static let pageHeight: CGFloat = 841.89
    static let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

    // MARK: - Marges
    static let marginLeft: CGFloat = 50
    static let marginRight: CGFloat = 50
    static let marginTop: CGFloat = 50
    static let marginBottom: CGFloat = 50
    static let contentWidth: CGFloat = pageWidth - marginLeft - marginRight

    // MARK: - Header
    static let headerHeight: CGFloat = 80
    static let headerColor = NSColor(red: 0.33, green: 0.54, blue: 0.19, alpha: 1.0)

    // MARK: - Tableau
    static let tableHeaderHeight: CGFloat = 30
    static let tableRowHeight: CGFloat = 25
    static let tableHeaderColor = NSColor(red: 0.33, green: 0.54, blue: 0.19, alpha: 1.0)
    static let tableAlternateColor = NSColor(red: 0.95, green: 0.97, blue: 0.93, alpha: 1.0)

    // Colonnes du tableau (proportions)
    static let colDesignation: CGFloat = 0.35
    static let colQuantite: CGFloat = 0.15
    static let colPrix: CGFloat = 0.15
    static let colTotal: CGFloat = 0.20
    static let colTVA: CGFloat = 0.15

    // MARK: - Polices
    static let fontTitle = NSFont.systemFont(ofSize: 22, weight: .bold)
    static let fontSubtitle = NSFont.systemFont(ofSize: 12, weight: .medium)
    static let fontBody = NSFont.systemFont(ofSize: 10, weight: .regular)
    static let fontBodyBold = NSFont.systemFont(ofSize: 10, weight: .bold)
    static let fontSmall = NSFont.systemFont(ofSize: 8, weight: .regular)
    static let fontTableHeader = NSFont.systemFont(ofSize: 9, weight: .bold)
    static let fontTotalTTC = NSFont.systemFont(ofSize: 13, weight: .bold)
    static let fontSection = NSFont.systemFont(ofSize: 11, weight: .semibold)

    // MARK: - Couleurs texte
    static let textBlack = NSColor.black
    static let textWhite = NSColor.white
    static let textGray = NSColor.darkGray
    static let textLightGray = NSColor.gray

    // MARK: - Seuil pour nouvelle page
    static let newPageThreshold: CGFloat = pageHeight - marginBottom - 120
}
