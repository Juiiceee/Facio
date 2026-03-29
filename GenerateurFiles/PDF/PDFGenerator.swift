import AppKit
import Foundation
import CoreText

/// Generateur de PDF professionnel pour factures et devis
@MainActor
struct PDFGenerator {
    let document: Document
    let company: CompanyInfo

    // Coordonnees top-down : y=0 en haut, y augmente vers le bas
    // Conversion vers Core Graphics: cgY = pageHeight - topDownY

    private let pH = PDFLayout.pageHeight
    private let pW = PDFLayout.pageWidth
    private let mL = PDFLayout.marginLeft
    private let mR = PDFLayout.marginRight
    private let cW = PDFLayout.contentWidth

    func generate() -> Data {
        let pdfData = NSMutableData()
        var mediaBox = PDFLayout.pageRect

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else { return Data() }

        var y = beginPage(context)

        y = drawHeader(context, y: y)
        y += 20
        y = drawDatesAndClient(context, y: y)
        y += 25
        y = drawTable(context, y: y)
        y += 20
        y = drawTotals(context, y: y)
        y += 30

        if document.status == .payee && !document.transactionSignatures.isEmpty {
            if y > pH - 200 { context.endPDFPage(); y = beginPage(context) }
            y = drawTransactionSignatures(context, y: y)
            y += 20
        }

        if y > pH - 150 { context.endPDFPage(); y = beginPage(context) }
        y = drawPaymentInfo(context, y: y)
        drawFooter(context)

        context.endPDFPage()
        context.closePDF()
        return pdfData as Data
    }

    // MARK: - Pages

    private func beginPage(_ context: CGContext) -> CGFloat {
        let pageInfo: [String: Any] = [kCGPDFContextMediaBox as String: PDFLayout.pageRect]
        context.beginPDFPage(pageInfo as CFDictionary)
        return PDFLayout.marginTop
    }

    // MARK: - Conversion coordonnees

    /// Convertit Y top-down en Y Core Graphics (bottom-up)
    private func cgY(_ topY: CGFloat) -> CGFloat { pH - topY }

    // MARK: - Dessin texte via CoreText (pas de flip necessaire)

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

    // MARK: - Dessin rectangles

    private func fillRect(_ context: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: NSColor) {
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: x, y: cgY(y + h), width: w, height: h))
    }

    private func strokeLine(_ context: CGContext, x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, color: NSColor, width: CGFloat = 0.5) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(width)
        context.move(to: CGPoint(x: x1, y: cgY(y1)))
        context.addLine(to: CGPoint(x: x2, y: cgY(y2)))
        context.strokePath()
    }

    // MARK: - Header

    private func drawHeader(_ context: CGContext, y: CGFloat) -> CGFloat {
        // Barre verte pleine largeur
        fillRect(context, x: 0, y: 0, w: pW, h: PDFLayout.headerHeight, color: PDFLayout.headerColor)

        // Logo
        if let logoData = company.logoData, let logo = NSImage(data: logoData),
           let cgImage = logo.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let logoRect = CGRect(x: pW - 90, y: cgY(70.0), width: 60, height: 60)
            context.draw(cgImage, in: logoRect)
        }

        // Titre
        let title = "\(document.type.prefix)_\(document.dateCreation.yearMonthFormatted)"
        drawText(title, x: mL, y: 28, font: PDFLayout.fontTitle, color: PDFLayout.textWhite, context: context)

        return PDFLayout.headerHeight + 10
    }

    // MARK: - Dates et Client

    private func drawDatesAndClient(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = y

        drawText("Date de facture: \(document.dateCreation.frenchFormatted)",
                 x: mL, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        cy += 16

        drawText("Echeance: \(document.dateEcheance.frenchFormatted)",
                 x: mL, y: cy, font: PDFLayout.fontBodyBold, color: PDFLayout.textBlack, context: context)

        // Destinataire
        let rx = pW - mR - 200
        var ry = y

        drawText("DESTINATAIRE", x: rx, y: ry, font: PDFLayout.fontSection, color: PDFLayout.textBlack, context: context)
        ry += 18
        drawText(document.clientNom, x: rx, y: ry, font: PDFLayout.fontBodyBold, color: PDFLayout.textBlack, context: context)
        ry += 14
        if !document.clientAdresse.isEmpty {
            drawText(document.clientAdresse, x: rx, y: ry, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
            ry += 14
        }
        drawText("\(document.clientVille), \(document.clientCodePostal)",
                 x: rx, y: ry, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)

        return max(cy, ry) + 20
    }

    // MARK: - Tableau

    private func drawTable(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = y
        let colW: [CGFloat] = [
            cW * PDFLayout.colDesignation,
            cW * PDFLayout.colQuantite,
            cW * PDFLayout.colPrix,
            cW * PDFLayout.colTotal,
            cW * PDFLayout.colTVA
        ]
        let headers = ["DESIGNATION", "QUANTITE", "PRIX", "TOTAL", "TVA"]

        cy = drawTableHeader(context, headers: headers, colW: colW, y: cy)

        for (index, ligne) in document.lignesTriees.enumerated() {
            if cy > pH - PDFLayout.marginBottom - 80 {
                drawFooter(context)
                context.endPDFPage()
                cy = beginPage(context)
                cy = drawTableHeader(context, headers: headers, colW: colW, y: cy)
            }

            if index % 2 == 1 {
                fillRect(context, x: mL, y: cy, w: cW, h: PDFLayout.tableRowHeight, color: PDFLayout.tableAlternateColor)
            }

            var colX = mL
            let vals = [
                ligne.designation,
                ligne.quantite.formatted2Decimals,
                ligne.prixUnitaire.formatted2Decimals,
                ligne.totalLigne.formatted2Decimals,
                ligne.tauxTVA == 0 ? "0" : "\(ligne.tauxTVA.formatted2Decimals)%"
            ]
            for (i, val) in vals.enumerated() {
                drawText(val, x: colX + 5, y: cy + 7, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
                colX += colW[i]
            }
            cy += PDFLayout.tableRowHeight
        }

        strokeLine(context, x1: mL, y1: cy, x2: mL + cW, y2: cy, color: PDFLayout.headerColor)
        return cy
    }

    private func drawTableHeader(_ context: CGContext, headers: [String], colW: [CGFloat], y: CGFloat) -> CGFloat {
        fillRect(context, x: mL, y: y, w: cW, h: PDFLayout.tableHeaderHeight, color: PDFLayout.tableHeaderColor)

        var colX = mL
        for (i, h) in headers.enumerated() {
            drawText(h, x: colX + 5, y: y + 8, font: PDFLayout.fontTableHeader, color: PDFLayout.textWhite, context: context)
            colX += colW[i]
        }
        return y + PDFLayout.tableHeaderHeight
    }

    // MARK: - Totaux

    private func drawTotals(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = y
        let labelX = pW - mR - 220
        let valueX = pW - mR - 100
        let cur = document.currency.rawValue

        drawText("TOTAL", x: labelX, y: cy, font: PDFLayout.fontBodyBold, color: PDFLayout.textBlack, context: context)
        drawText("\(document.totalHT.formatted2Decimals) \(cur)", x: valueX, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        cy += 20

        drawText("TVA", x: labelX, y: cy, font: PDFLayout.fontBodyBold, color: PDFLayout.textBlack, context: context)
        drawText("\(document.totalTVA.formatted2Decimals) \(cur)", x: valueX, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        cy += 25

        drawText("Total TTC", x: labelX, y: cy, font: PDFLayout.fontTotalTTC, color: PDFLayout.textBlack, context: context)
        drawText("\(document.totalTTC.formatted2Decimals) \(cur)", x: valueX, y: cy, font: PDFLayout.fontTotalTTC, color: PDFLayout.textBlack, context: context)
        cy += 20

        return cy
    }

    // MARK: - Signatures

    private func drawTransactionSignatures(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = y
        drawText("PREUVES DE PAIEMENT", x: mL, y: cy, font: PDFLayout.fontSection, color: PDFLayout.headerColor, context: context)
        cy += 18

        for tx in document.transactionSignatures {
            drawText("\(tx.date.frenchFormatted) — \(document.currency.format(tx.montant)) via \(tx.blockchain.label)",
                     x: mL, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
            cy += 14

            let sig = tx.signature.count > 60 ? "\(tx.signature.prefix(30))...\(tx.signature.suffix(10))" : tx.signature
            drawText("TX: \(sig)", x: mL + 10, y: cy, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
            cy += 12

            if let url = tx.explorerURL {
                drawText("\(tx.explorerName): \(url.absoluteString)", x: mL + 10, y: cy,
                         font: PDFLayout.fontSmall, color: NSColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0), context: context)
                cy += 16
            }
        }
        return cy
    }

    // MARK: - Infos de paiement

    private func drawPaymentInfo(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = y
        strokeLine(context, x1: mL, y1: cy, x2: mL + cW, y2: cy, color: PDFLayout.textLightGray)
        cy += 15

        let rx = pW / 2
        drawText(company.nom, x: mL, y: cy, font: PDFLayout.fontBodyBold, color: PDFLayout.textBlack, context: context)

        if document.currency.isCrypto {
            drawText(document.blockchain?.label ?? "", x: rx, y: cy, font: PDFLayout.fontBodyBold, color: PDFLayout.textBlack, context: context)
            cy += 14
            drawText("\(company.ville), \(company.codePostal)", x: mL, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
            drawText("Transfert Cryptomonnaie", x: rx, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
            cy += 14
            if !company.siret.isEmpty { drawText("SIRET: \(company.siret)", x: mL, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context) }
            drawText("Wallet adresse:", x: rx, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
            cy += 14
            if !company.telephone.isEmpty { drawText("Tel: \(company.telephone)", x: mL, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context) }
            if let chain = document.blockchain, let wallet = company.wallet(pour: chain) {
                drawText(wallet.address, x: rx, y: cy, font: PDFLayout.fontSmall, color: PDFLayout.textBlack, context: context)
            }
        } else {
            drawText("Virement bancaire", x: rx, y: cy, font: PDFLayout.fontBodyBold, color: PDFLayout.textBlack, context: context)
            cy += 14
            drawText("\(company.ville), \(company.codePostal)", x: mL, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
            if !company.iban.isEmpty { drawText("IBAN: \(company.iban)", x: rx, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context) }
            cy += 14
            if !company.siret.isEmpty { drawText("SIRET: \(company.siret)", x: mL, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context) }
            if !company.bic.isEmpty { drawText("BIC: \(company.bic)", x: rx, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context) }
            cy += 14
            if !company.telephone.isEmpty { drawText("Tel: \(company.telephone)", x: mL, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context) }
            if !company.titulaireCompte.isEmpty { drawText("Titulaire: \(company.titulaireCompte)", x: rx, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context) }
        }
        return cy
    }

    // MARK: - Footer

    private func drawFooter(_ context: CGContext) {
        var parts: [String] = []
        if !company.nom.isEmpty { parts.append(company.nom) }
        if !company.siret.isEmpty { parts.append("SIRET: \(company.siret)") }
        if !company.telephone.isEmpty { parts.append("Tel: \(company.telephone)") }
        if !company.email.isEmpty { parts.append(company.email) }

        let text = parts.joined(separator: " — ")
        let attrs: [NSAttributedString.Key: Any] = [.font: PDFLayout.fontSmall as CTFont, .foregroundColor: PDFLayout.textLightGray]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        let lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
        let centeredX = (pW - lineWidth) / 2

        context.textPosition = CGPoint(x: centeredX, y: PDFLayout.marginBottom - 10)
        CTLineDraw(line, context)
    }
}
