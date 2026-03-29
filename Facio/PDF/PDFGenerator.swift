import AppKit
import Foundation
import CoreText

/// Generateur de PDF professionnel pour factures et devis
/// Style : fond blanc, titre centre, logo abstrait, tableau vert olive, pied avec bordure verte gauche
@MainActor
struct PDFGenerator {
    let document: Document
    let company: CompanyInfo

    private let pH = PDFLayout.pageHeight
    private let pW = PDFLayout.pageWidth
    private let mL = PDFLayout.marginLeft
    private let mR = PDFLayout.marginRight
    private let cW = PDFLayout.contentWidth

    // MARK: - Generation principale

    func generate() -> Data {
        let pdfData = NSMutableData()
        var mediaBox = PDFLayout.pageRect

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else { return Data() }

        var y = beginPage(context)

        // 1. Titre + Logo
        y = drawTitleAndLogo(context, y: y)
        y += 25

        // 2. Dates + Destinataire
        y = drawDatesAndClient(context, y: y)
        y += 20

        // 3. Tableau
        y = drawTable(context, y: y)
        y += 15

        // 4. Totaux
        y = drawTotals(context, y: y)
        y += 25

        // 5. Signatures (si payee)
        if document.status == .payee && !document.transactionSignatures.isEmpty {
            if y > pH - 200 { context.endPDFPage(); y = beginPage(context) }
            y = drawTransactionSignatures(context, y: y)
            y += 15
        }

        // 6. Pied de page entreprise + paiement
        if y > pH - 140 { context.endPDFPage(); y = beginPage(context) }
        y = drawFooterBlock(context, y: y, showPayment: document.paymentMode != .aucun)

        context.endPDFPage()
        context.closePDF()
        return pdfData as Data
    }

    // MARK: - Page

    private func beginPage(_ context: CGContext) -> CGFloat {
        let pageInfo: [String: Any] = [kCGPDFContextMediaBox as String: PDFLayout.pageRect]
        context.beginPDFPage(pageInfo as CFDictionary)
        return PDFLayout.marginTop
    }

    /// Convertit Y top-down en Y Core Graphics (bottom-up)
    private func cgY(_ topY: CGFloat) -> CGFloat { pH - topY }

    // MARK: - Dessin texte via CoreText

    private func drawText(_ text: String, x: CGFloat, y: CGFloat, font: NSFont, color: NSColor, context: CGContext) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        let ascent = CTFontGetAscent(font as CTFont)
        context.saveGState()
        context.textPosition = CGPoint(x: x, y: cgY(y) - ascent)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    /// Dessine du texte aligne a droite par rapport a rightX
    private func drawTextRight(_ text: String, rightX: CGFloat, y: CGFloat, font: NSFont, color: NSColor, context: CGContext) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        let ascent = CTFontGetAscent(font as CTFont)
        context.saveGState()
        context.textPosition = CGPoint(x: rightX - width, y: cgY(y) - ascent)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    /// Dessine du texte centre horizontalement
    private func drawTextCenter(_ text: String, y: CGFloat, font: NSFont, color: NSColor, context: CGContext) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        let ascent = CTFontGetAscent(font as CTFont)
        context.saveGState()
        context.textPosition = CGPoint(x: (pW - width) / 2, y: cgY(y) - ascent)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private func textWidth(_ text: String, font: NSFont) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        return CTLineGetTypographicBounds(line, nil, nil, nil)
    }

    // MARK: - Dessin rectangles / lignes

    private func fillRect(_ ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: NSColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(x: x, y: cgY(y + h), width: w, height: h))
    }

    private func strokeRect(_ ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: NSColor, lineWidth: CGFloat = 0.5) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.stroke(CGRect(x: x, y: cgY(y + h), width: w, height: h))
    }

    private func strokeLine(_ ctx: CGContext, x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, color: NSColor, width: CGFloat = 0.5) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.move(to: CGPoint(x: x1, y: cgY(y1)))
        ctx.addLine(to: CGPoint(x: x2, y: cgY(y2)))
        ctx.strokePath()
    }

    private func fillCircle(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat, color: NSColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - r, y: cgY(cy) - r, width: r * 2, height: r * 2))
    }

    // MARK: - 1. Titre + Logo

    private func drawTitleAndLogo(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = y + 10

        // Logo en haut a droite (motif abstrait de cercles)
        let logoX = pW - mR - 50
        let logoY = cy + 15
        drawAbstractLogo(context, centerX: logoX, centerY: logoY)

        // Titre centre — utilise le numero du document directement
        let title = document.number
        drawTextCenter(title, y: cy + 15, font: PDFLayout.fontTitle, color: PDFLayout.textBlack, context: context)

        cy += 55
        return cy
    }

    /// Dessine le logo abstrait : 6 cercles/ellipses superposes
    private func drawAbstractLogo(_ ctx: CGContext, centerX: CGFloat, centerY: CGFloat) {
        // Si l'utilisateur a un logo, l'utiliser
        if let logoData = company.logoData, let logo = NSImage(data: logoData),
           let cgImage = logo.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let rect = CGRect(x: centerX - 35, y: cgY(centerY) - 35, width: 70, height: 70)
            ctx.draw(cgImage, in: rect)
            return
        }

        // Sinon, dessiner le motif abstrait
        let circles: [(dx: CGFloat, dy: CGFloat, r: CGFloat, color: NSColor)] = [
            (-12, -15, 14, PDFLayout.logoGreenOlive),
            (8, -18, 12, PDFLayout.logoYellow),
            (-5, -2, 15, PDFLayout.logoGreenDark),
            (12, -3, 13, PDFLayout.logoPurple),
            (-8, 12, 12, PDFLayout.logoGreenMed),
            (10, 14, 11, PDFLayout.logoYellowLight),
        ]
        for c in circles {
            fillCircle(ctx, cx: centerX + c.dx, cy: centerY + c.dy, r: c.r, color: c.color)
        }
    }

    // MARK: - 2. Dates + Destinataire

    private func drawDatesAndClient(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = y

        // Gauche : dates
        drawText("Date de facture: \(document.dateCreation.frenchFormatted)",
                 x: mL, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        cy += 15
        drawText("Echeance: \(document.dateEcheance.frenchFormatted)",
                 x: mL, y: cy, font: PDFLayout.fontBodyBold, color: PDFLayout.textBlack, context: context)

        // Droite : destinataire
        let blockRight = pW - mR
        let destX = blockRight - 180
        var ry = y

        // "DESTINATAIRE" en vert fonce
        drawText("DESTINATAIRE", x: destX, y: ry, font: PDFLayout.fontSection, color: PDFLayout.greenDark, context: context)
        ry += 13
        // Ligne verte fine sous DESTINATAIRE
        strokeLine(context, x1: destX, y1: ry, x2: blockRight, y2: ry, color: PDFLayout.greenDark, width: 1.0)
        ry += 8

        // Nom client
        drawText(document.clientNom, x: destX, y: ry, font: PDFLayout.fontClient, color: PDFLayout.textBlack, context: context)
        ry += 14

        // Adresse
        if !document.clientAdresse.isEmpty {
            drawText(document.clientAdresse, x: destX, y: ry, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
            ry += 13
        }
        drawText("\(document.clientVille), \(document.clientCodePostal)",
                 x: destX, y: ry, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)

        return max(cy, ry) + 15
    }

    // MARK: - 3. Tableau

    private func drawTable(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = y
        let x = mL
        let w = cW
        let colW: [CGFloat] = [
            w * PDFLayout.colDesignation,
            w * PDFLayout.colQuantite,
            w * PDFLayout.colPrix,
            w * PDFLayout.colTotal,
            w * PDFLayout.colTVA
        ]
        let headers = ["DESIGNATION", "QUANTITE", "PRIX", "TOTAL", "TVA"]

        // En-tete du tableau
        cy = drawTableHeader(context, headers: headers, colW: colW, x: x, w: w, y: cy)

        let tableStartY = y

        // Lignes
        for (_, ligne) in document.lignesTriees.enumerated() {
            if cy > pH - PDFLayout.marginBottom - 80 {
                // Bordure du tableau avant nouvelle page
                strokeRect(context, x: x, y: tableStartY, w: w, h: cy - tableStartY, color: PDFLayout.greenPrimary, lineWidth: 0.8)
                context.endPDFPage()
                cy = beginPage(context)
                cy = drawTableHeader(context, headers: headers, colW: colW, x: x, w: w, y: cy)
            }

            // Dessiner les separateurs verticaux verts legers
            var sepX = x
            for i in 0..<colW.count {
                sepX += colW[i]
                if i < colW.count - 1 {
                    strokeLine(context, x1: sepX, y1: cy, x2: sepX, y2: cy + PDFLayout.tableRowHeight,
                               color: PDFLayout.greenPrimary.withAlphaComponent(0.3), width: 0.3)
                }
            }

            // Donnees
            var colX = x
            let vals = [
                ligne.designation,
                formatNumber(ligne.quantite),
                formatNumber(ligne.prixUnitaire),
                formatSpaced(ligne.totalLigne),
                ligne.tauxTVA == 0 ? "0" : "\(formatNumber(ligne.tauxTVA))"
            ]

            for (i, val) in vals.enumerated() {
                if i == 0 {
                    // Designation alignee a gauche
                    drawText(val, x: colX + 6, y: cy + 7,
                             font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
                } else {
                    // Nombres alignes a droite
                    drawTextRight(val, rightX: colX + colW[i] - 6, y: cy + 7,
                                  font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
                }
                colX += colW[i]
            }
            cy += PDFLayout.tableRowHeight

            // Ligne horizontale fine entre les lignes
            strokeLine(context, x1: x, y1: cy, x2: x + w, y2: cy,
                       color: PDFLayout.greenPrimary.withAlphaComponent(0.15), width: 0.3)
        }

        // Bordure du tableau
        strokeRect(context, x: x, y: tableStartY, w: w, h: cy - tableStartY, color: PDFLayout.greenPrimary, lineWidth: 0.8)

        return cy
    }

    private func drawTableHeader(_ context: CGContext, headers: [String], colW: [CGFloat], x: CGFloat, w: CGFloat, y: CGFloat) -> CGFloat {
        // Fond vert olive
        fillRect(context, x: x, y: y, w: w, h: PDFLayout.tableHeaderHeight, color: PDFLayout.greenPrimary)

        var colX = x
        for (i, h) in headers.enumerated() {
            if i == 0 {
                drawText(h, x: colX + 6, y: y + 9,
                         font: PDFLayout.fontTableHeader, color: PDFLayout.textWhite, context: context)
            } else {
                drawTextRight(h, rightX: colX + colW[i] - 6, y: y + 9,
                              font: PDFLayout.fontTableHeader, color: PDFLayout.textWhite, context: context)
            }
            colX += colW[i]
        }
        return y + PDFLayout.tableHeaderHeight
    }

    // MARK: - 4. Totaux

    private func drawTotals(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = y
        let valueRight = pW - mR
        let labelRight = valueRight - 120

        let cur = document.currency.rawValue

        // TOTAL
        drawTextRight("TOTAL", rightX: labelRight, y: cy,
                      font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        drawTextRight("\(formatSpaced(document.totalHT)) \(cur)", rightX: valueRight, y: cy,
                      font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        cy += 16

        // Ligne de separation
        strokeLine(context, x1: labelRight - 30, y1: cy - 2, x2: valueRight, y2: cy - 2,
                   color: PDFLayout.greenPrimary.withAlphaComponent(0.2), width: 0.3)

        // TVA
        drawTextRight("TVA", rightX: labelRight, y: cy,
                      font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        drawTextRight("\(formatSpaced(document.totalTVA)) \(cur)", rightX: valueRight, y: cy,
                      font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        cy += 18

        // Ligne de separation
        strokeLine(context, x1: labelRight - 30, y1: cy - 2, x2: valueRight, y2: cy - 2,
                   color: PDFLayout.greenPrimary.withAlphaComponent(0.3), width: 0.5)

        // Total TTC (gras italique)
        drawTextRight("Total TTC", rightX: labelRight, y: cy,
                      font: PDFLayout.fontTotalTTC, color: PDFLayout.textBlack, context: context)
        drawTextRight("\(formatSpaced(document.totalTTC)) \(cur)", rightX: valueRight, y: cy,
                      font: PDFLayout.fontTotalTTC, color: PDFLayout.textBlack, context: context)
        cy += 16

        return cy
    }

    // MARK: - 5. Signatures de transaction

    private func drawTransactionSignatures(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = y
        drawText("PREUVES DE PAIEMENT", x: mL, y: cy,
                 font: PDFLayout.fontSection, color: PDFLayout.greenDark, context: context)
        cy += 16

        for tx in document.transactionSignatures {
            drawText("\(tx.date.frenchFormatted) — \(document.currency.format(tx.montant)) via \(tx.blockchain.label)",
                     x: mL + 5, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
            cy += 13

            let sig = tx.signature.count > 60 ? "\(tx.signature.prefix(30))...\(tx.signature.suffix(10))" : tx.signature
            drawText("TX: \(sig)", x: mL + 10, y: cy,
                     font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
            cy += 11

            if let url = tx.explorerURL {
                drawText("\(tx.explorerName): \(url.absoluteString)", x: mL + 10, y: cy,
                         font: PDFLayout.fontSmall, color: NSColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0), context: context)
                cy += 14
            }
        }
        return cy
    }

    // MARK: - 6. Pied de page (bloc entreprise + paiement)

    private func drawFooterBlock(_ context: CGContext, y: CGFloat, showPayment: Bool = true) -> CGFloat {
        var cy = y + 10

        // Bordure verte epaisse a gauche du bloc
        let blockTop = cy
        let blockHeight: CGFloat = 70
        fillRect(context, x: mL, y: cy, w: 4, h: blockHeight, color: PDFLayout.greenPrimary)

        let leftX = mL + 14
        let rightX = pW / 2 + 10

        // Colonne gauche : infos entreprise
        drawText(company.nom.isEmpty ? "ENTREPRISE" : company.nom.uppercased(),
                 x: leftX, y: cy, font: PDFLayout.fontSmallBold, color: PDFLayout.textBlack, context: context)
        cy += 12
        if !company.ville.isEmpty || !company.codePostal.isEmpty {
            drawText("\(company.ville.uppercased()), \(company.codePostal)",
                     x: leftX, y: cy, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
        }
        cy += 11
        if !company.siret.isEmpty {
            drawText("SIRET: \(company.siret)",
                     x: leftX, y: cy, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
        }
        cy += 11
        if !company.telephone.isEmpty {
            drawText("Tel: \(company.telephone)",
                     x: leftX, y: cy, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
        }
        if !company.email.isEmpty {
            cy += 11
            drawText(company.email,
                     x: leftX, y: cy, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
        }

        // Colonne droite : mode de paiement (si actif)
        var ry = blockTop

        if !showPayment {
            // Pas de paiement — on n'affiche rien a droite
        } else if document.paymentMode == .crypto {
            let chainLabel = document.blockchain?.label ?? "Crypto"
            drawText(chainLabel, x: rightX, y: ry, font: PDFLayout.fontSmallBold, color: PDFLayout.textBlack, context: context)
            ry += 12
            drawText("Transfert Cryptomonnaie", x: rightX, y: ry, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
            ry += 12
            drawText("Wallet adresse:", x: rightX, y: ry, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
            ry += 12
            if let chain = document.blockchain, let wallet = company.wallet(pour: chain) {
                drawText(wallet.address, x: rightX, y: ry, font: PDFLayout.fontSmall, color: PDFLayout.textBlack, context: context)
            }
        } else {
            drawText("Virement bancaire", x: rightX, y: ry, font: PDFLayout.fontSmallBold, color: PDFLayout.textBlack, context: context)
            ry += 12
            if !company.iban.isEmpty {
                drawText("IBAN: \(company.iban)", x: rightX, y: ry, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
                ry += 11
            }
            if !company.bic.isEmpty {
                drawText("BIC: \(company.bic)", x: rightX, y: ry, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
                ry += 11
            }
            if !company.titulaireCompte.isEmpty {
                drawText("Titulaire: \(company.titulaireCompte)", x: rightX, y: ry, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
            }
        }

        return blockTop + blockHeight + 10
    }

    // MARK: - Formatage nombres

    /// Formate un Decimal avec 2 decimales et virgule (ex: 26,39)
    private func formatNumber(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = ""
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    /// Formate un Decimal avec separateur de milliers (ex: 2 897,39)
    private func formatSpaced(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = "\u{202F}" // narrow non-breaking space
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
