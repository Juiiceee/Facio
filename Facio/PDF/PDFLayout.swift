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
    static let marginLeft: CGFloat = 40
    static let marginRight: CGFloat = 40
    static let marginTop: CGFloat = 30
    static let marginBottom: CGFloat = 30
    static let contentWidth: CGFloat = pageWidth - marginLeft - marginRight

    // MARK: - Tableau
    static let tableHeaderHeight: CGFloat = 28
    static let tableRowHeight: CGFloat = 24

    // Colonnes du tableau (proportions)
    static let colDesignation: CGFloat = 0.40
    static let colQuantite: CGFloat = 0.15
    static let colPrix: CGFloat = 0.15
    static let colTotal: CGFloat = 0.15
    static let colTVA: CGFloat = 0.15

    // MARK: - QR Code
    static let qrCodeSize: CGFloat = 120

    // MARK: - Polices (Helvetica / sans-serif)
    static let fontTitle = NSFont(name: "Helvetica-Bold", size: 18) ?? NSFont.systemFont(ofSize: 18, weight: .bold)
    static let fontBody = NSFont(name: "Helvetica", size: 10) ?? NSFont.systemFont(ofSize: 10)
    static let fontBodyBold = NSFont(name: "Helvetica-Bold", size: 10) ?? NSFont.systemFont(ofSize: 10, weight: .bold)
    static let fontBodyItalic = NSFont(name: "Helvetica-Oblique", size: 10) ?? NSFont.systemFont(ofSize: 10)
    static let fontBodyBoldItalic = NSFont(name: "Helvetica-BoldOblique", size: 11) ?? NSFont.systemFont(ofSize: 11, weight: .bold)
    static let fontSmall = NSFont(name: "Helvetica", size: 9) ?? NSFont.systemFont(ofSize: 9)
    static let fontSmallBold = NSFont(name: "Helvetica-Bold", size: 9) ?? NSFont.systemFont(ofSize: 9, weight: .bold)
    static let fontTableHeader = NSFont(name: "Helvetica-Bold", size: 9) ?? NSFont.systemFont(ofSize: 9, weight: .bold)
    static let fontTotalTTC = NSFont(name: "Helvetica-BoldOblique", size: 12) ?? NSFont.systemFont(ofSize: 12, weight: .bold)
    static let fontSection = NSFont(name: "Helvetica-Bold", size: 10) ?? NSFont.systemFont(ofSize: 10, weight: .semibold)
    static let fontClient = NSFont(name: "Helvetica-Bold", size: 11) ?? NSFont.systemFont(ofSize: 11, weight: .bold)

    // MARK: - Couleurs
    /// Vert principal (en-tetes tableau, bordures, accents)
    static let greenPrimary = NSColor(red: 0.42, green: 0.56, blue: 0.23, alpha: 1.0) // #6B8E3A
    /// Vert fonce (texte DESTINATAIRE, accents forts)
    static let greenDark = NSColor(red: 0.36, green: 0.43, blue: 0.18, alpha: 1.0) // #5B6E2D
    /// Vert clair pour alternance
    static let greenLight = NSColor(red: 0.95, green: 0.97, blue: 0.93, alpha: 1.0)
    /// Texte principal
    static let textBlack = NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0) // #1A1A1A
    static let textWhite = NSColor.white
    static let textGray = NSColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
    static let textLightGray = NSColor.gray

    // MARK: - Logo colors
    static let logoGreenOlive = NSColor(red: 0.55, green: 0.62, blue: 0.24, alpha: 0.85)   // #8B9E3C
    static let logoYellow = NSColor(red: 0.77, green: 0.66, blue: 0.22, alpha: 0.85)        // #C4A839
    static let logoPurple = NSColor(red: 0.48, green: 0.37, blue: 0.65, alpha: 0.85)        // #7B5EA7
    static let logoGreenDark = NSColor(red: 0.35, green: 0.48, blue: 0.17, alpha: 0.85)     // #5A7A2B
    static let logoGreenMed = NSColor(red: 0.45, green: 0.55, blue: 0.20, alpha: 0.80)
    static let logoYellowLight = NSColor(red: 0.82, green: 0.72, blue: 0.30, alpha: 0.75)

    // MARK: - Couleurs dynamiques (depuis CompanyInfo)

    /// Couleur principale du theme (en-tetes, bordures, accents)
    static func themePrimary(from company: CompanyInfo) -> NSColor {
        company.accentNSColor
    }

    /// Variante foncee (labels de section)
    static func themeDark(from company: CompanyInfo) -> NSColor {
        company.accentNSColor.darkened(by: 0.15)
    }

    /// Variante tres claire (alternance de lignes)
    static func themeLight(from company: CompanyInfo) -> NSColor {
        company.accentNSColor.withAlphaComponent(0.07)
    }
}
