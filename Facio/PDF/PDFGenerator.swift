import AppKit
import Foundation
import CoreText
import ImageIO

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
    private var lang: AppLanguage { document.langue }

    // Couleurs dynamiques (depuis CompanyInfo)
    private var themePrimary: NSColor { PDFLayout.themePrimary(from: company) }
    private var themeDark: NSColor { PDFLayout.themeDark(from: company) }
    private let maximumTextLength = 8_000
    private let maximumLineLength = 1_000
    private let maximumLogoBytes = 2_000_000
    private let maximumLogoDimension = 4_096
    private let maximumLogoPixels = 12_000_000

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
        y = ensurePageSpace(context, y: y, needed: 85)
        y = drawTotals(context, y: y)
        y += 25

        // 5. Notes (si non vides)
        if !document.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if y > pH - 120 { context.endPDFPage(); y = beginPage(context) }
            y = drawNotes(context, y: y)
            y += 15
        }

        // 6. Signatures (si payee)
        if document.status == .payee && !document.transactionSignatures.isEmpty {
            if y > pH - 200 { context.endPDFPage(); y = beginPage(context) }
            y = drawTransactionSignatures(context, y: y)
            y += 15
        }

        // 7. Pied de page entreprise + paiement
        let solanaPayQR: CGImage? = {
            guard let address = document.solanaPayWalletAddress(from: company.wallets) else { return nil }
            return SolanaPayService.generateQRCode(
                walletAddress: address,
                amount: document.totalTTC,
                currency: document.currency,
                companyName: company.nom,
                documentNumber: document.number
            )
        }()
        let showPaymentDetails = shouldRenderPaymentDetails
        let footerNeeded = footerNeededHeight(showPayment: showPaymentDetails, solanaPayQR: solanaPayQR)
        y = ensurePageSpace(context, y: y, needed: footerNeeded)
        y = drawFooterBlock(context, y: y, showPayment: showPaymentDetails, solanaPayQR: solanaPayQR)

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

    private func drawText(_ text: String, x: CGFloat, y: CGFloat, font: NSFont, color: NSColor, context: CGContext, maxWidth: CGFloat? = nil) {
        let maxWidth = max(1, maxWidth ?? (pW - mR - x))
        let text = fittedSingleLine(text, font: font, maxWidth: maxWidth)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        let ascent = CTFontGetAscent(font as CTFont)
        context.saveGState()
        context.clip(to: CGRect(x: x, y: cgY(y + font.pointSize + 3), width: maxWidth, height: font.pointSize + 6))
        context.textPosition = CGPoint(x: x, y: cgY(y) - ascent)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    /// Dessine du texte aligne a droite par rapport a rightX
    private func drawTextRight(_ text: String, rightX: CGFloat, y: CGFloat, font: NSFont, color: NSColor, context: CGContext, maxWidth: CGFloat? = nil) {
        let maxWidth = max(1, maxWidth ?? (rightX - mL))
        let text = fittedSingleLine(text, font: font, maxWidth: maxWidth)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        let ascent = CTFontGetAscent(font as CTFont)
        let x = rightX - width
        context.saveGState()
        context.clip(to: CGRect(x: rightX - maxWidth, y: cgY(y + font.pointSize + 3), width: maxWidth, height: font.pointSize + 6))
        context.textPosition = CGPoint(x: x, y: cgY(y) - ascent)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    /// Dessine du texte centre horizontalement
    private func drawTextCenter(_ text: String, y: CGFloat, font: NSFont, color: NSColor, context: CGContext) {
        let text = fittedSingleLine(text, font: font, maxWidth: cW)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        let ascent = CTFontGetAscent(font as CTFont)
        let x = (pW - width) / 2
        context.saveGState()
        context.clip(to: CGRect(x: mL, y: cgY(y + font.pointSize + 3), width: cW, height: font.pointSize + 6))
        context.textPosition = CGPoint(x: x, y: cgY(y) - ascent)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private func textWidth(_ text: String, font: NSFont) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        return CTLineGetTypographicBounds(line, nil, nil, nil)
    }

    private func sanitizedSingleLine(_ text: String) -> String {
        let limited = String(text.prefix(maximumLineLength))
        var result = ""
        result.reserveCapacity(limited.count)
        var previousWasSpace = false

        for scalar in limited.unicodeScalars {
            let isAllowedControl = scalar == "\t"
            if CharacterSet.controlCharacters.contains(scalar), !isAllowedControl {
                continue
            }
            let replacement = CharacterSet.newlines.contains(scalar) || isAllowedControl ? " " : String(scalar)
            let isSpace = replacement.unicodeScalars.allSatisfy { CharacterSet.whitespacesAndNewlines.contains($0) }
            if isSpace {
                if !previousWasSpace {
                    result.append(" ")
                }
                previousWasSpace = true
            } else {
                result.append(replacement)
                previousWasSpace = false
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sanitizedMultiline(_ text: String) -> String {
        let limited = String(text.prefix(maximumTextLength))
        var result = ""
        result.reserveCapacity(limited.count)

        for scalar in limited.unicodeScalars {
            if scalar == "\n" || scalar == "\r" {
                result.append("\n")
            } else if scalar == "\t" {
                result.append(" ")
            } else if !CharacterSet.controlCharacters.contains(scalar) {
                result.append(String(scalar))
            }
        }

        return result
    }

    private func fittedSingleLine(_ text: String, font: NSFont, maxWidth: CGFloat) -> String {
        let clean = sanitizedSingleLine(text)
        guard !clean.isEmpty, textWidth(clean, font: font) > maxWidth else { return clean }
        let suffix = "..."
        guard textWidth(suffix, font: font) < maxWidth else { return "" }

        var low = 0
        var high = clean.count
        var best = suffix

        while low <= high {
            let mid = (low + high) / 2
            let candidate = String(clean.prefix(mid)) + suffix
            if textWidth(candidate, font: font) <= maxWidth {
                best = candidate
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        return best
    }

    private func wrappedLines(_ text: String, font: NSFont, maxWidth: CGFloat) -> [String] {
        sanitizedMultiline(text)
            .components(separatedBy: .newlines)
            .flatMap { paragraph in
                let words = paragraph.split(whereSeparator: { $0.isWhitespace }).map(String.init)
                guard !words.isEmpty else { return [""] }

                var lines: [String] = []
                var currentLine = ""
                for word in words {
                    let candidate = currentLine.isEmpty ? word : "\(currentLine) \(word)"
                    if textWidth(candidate, font: font) <= maxWidth {
                        currentLine = candidate
                    } else {
                        if !currentLine.isEmpty {
                            lines.append(currentLine)
                        }
                        if textWidth(word, font: font) <= maxWidth {
                            currentLine = word
                        } else {
                            let pieces = splitLongWord(word, font: font, maxWidth: maxWidth)
                            lines.append(contentsOf: pieces.dropLast())
                            currentLine = pieces.last ?? ""
                        }
                    }
                }
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                }
                return lines
            }
    }

    private func splitLongWord(_ word: String, font: NSFont, maxWidth: CGFloat) -> [String] {
        var remaining = String(word.prefix(maximumLineLength))
        var pieces: [String] = []

        while !remaining.isEmpty {
            if textWidth(remaining, font: font) <= maxWidth {
                pieces.append(remaining)
                break
            }

            var low = 1
            var high = remaining.count
            var best = 1
            while low <= high {
                let mid = (low + high) / 2
                let candidate = String(remaining.prefix(mid))
                if textWidth(candidate, font: font) <= maxWidth {
                    best = mid
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }

            pieces.append(String(remaining.prefix(best)))
            remaining.removeFirst(best)
        }

        return pieces
    }

    private func ensurePageSpace(_ context: CGContext, y: CGFloat, needed: CGFloat) -> CGFloat {
        guard y + needed > pH - PDFLayout.marginBottom else { return y }
        context.endPDFPage()
        return beginPage(context)
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

    private func drawImage(_ ctx: CGContext, image: CGImage, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        ctx.draw(image, in: CGRect(x: x, y: cgY(y + h), width: w, height: h))
    }

    private func validatedLogoImage(from data: Data, maxPixelSize: Int) -> CGImage? {
        guard data.count <= maximumLogoBytes,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source),
              ["public.png", "public.jpeg", "public.tiff"].contains(type as String),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0,
              height > 0,
              width <= maximumLogoDimension,
              height <= maximumLogoDimension,
              width * height <= maximumLogoPixels
        else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
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
        // Si l'utilisateur a un logo valide, l'utiliser.
        if let logoData = company.logoData,
           let cgImage = validatedLogoImage(from: logoData, maxPixelSize: 140) {
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
        let dateLabel = document.type == .facture ? L10n.invoiceDate(lang) : L10n.quoteDate(lang)
        drawText("\(dateLabel)\(formatDate(document.dateCreation))",
                 x: mL, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        cy += 15
        drawText("\(L10n.dueDate(lang))\(formatDate(document.dateEcheance))",
                 x: mL, y: cy, font: PDFLayout.fontBodyBold, color: PDFLayout.textBlack, context: context)

        // Droite : destinataire
        let blockRight = pW - mR
        let destX = blockRight - 180
        var ry = y

        drawText(L10n.recipient(lang), x: destX, y: ry, font: PDFLayout.fontSection, color: themeDark, context: context)
        ry += 13
        // Ligne verte fine sous DESTINATAIRE
        strokeLine(context, x1: destX, y1: ry, x2: blockRight, y2: ry, color: themeDark, width: 1.0)
        ry += 8

        // Nom client
        drawText(document.clientNom, x: destX, y: ry, font: PDFLayout.fontClient, color: PDFLayout.textBlack, context: context)
        ry += 14

        // Adresse
        if !document.clientAdresse.isEmpty {
            drawText(document.clientAdresse, x: destX, y: ry, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
            ry += 13
        }
        let clientCityLine = addressLine(city: document.clientVille, postalCode: document.clientCodePostal)
        if !clientCityLine.isEmpty {
            drawText(clientCityLine, x: destX, y: ry, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        }

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
        let headers = [L10n.designation(lang), L10n.quantity(lang), L10n.price(lang), L10n.total(lang), L10n.vat(lang)]

        // En-tete du tableau
        cy = drawTableHeader(context, headers: headers, colW: colW, x: x, w: w, y: cy)

        var tableStartY = y

        // Lignes
        for (_, ligne) in document.lignesTriees.enumerated() {
            if cy > pH - PDFLayout.marginBottom - 80 {
                // Bordure du tableau avant nouvelle page
                strokeRect(context, x: x, y: tableStartY, w: w, h: cy - tableStartY, color: themePrimary, lineWidth: 0.8)
                context.endPDFPage()
                cy = beginPage(context)
                tableStartY = cy
                cy = drawTableHeader(context, headers: headers, colW: colW, x: x, w: w, y: cy)
            }

            // Dessiner les separateurs verticaux verts legers
            var sepX = x
            for i in 0..<colW.count {
                sepX += colW[i]
                if i < colW.count - 1 {
                    strokeLine(context, x1: sepX, y1: cy, x2: sepX, y2: cy + PDFLayout.tableRowHeight,
                               color: themePrimary.withAlphaComponent(0.3), width: 0.3)
                }
            }

            // Donnees
            var colX = x
            let vals = [
                ligne.designation,
                formatNumber(ligne.quantite),
                formatCurrencyNumber(ligne.prixUnitaire, usesGroupingSeparator: false),
                formatSpaced(ligne.totalLigne),
                ligne.tauxTVA == 0 ? "0" : "\(formatNumber(ligne.tauxTVA))"
            ]

            for (i, val) in vals.enumerated() {
                if i == 0 {
                    // Designation alignee a gauche
                    drawText(val, x: colX + 6, y: cy + 7,
                             font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context, maxWidth: colW[i] - 12)
                } else {
                    // Nombres alignes a droite
                    drawTextRight(val, rightX: colX + colW[i] - 6, y: cy + 7,
                                  font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context, maxWidth: colW[i] - 12)
                }
                colX += colW[i]
            }
            cy += PDFLayout.tableRowHeight

            // Ligne horizontale fine entre les lignes
            strokeLine(context, x1: x, y1: cy, x2: x + w, y2: cy,
                       color: themePrimary.withAlphaComponent(0.15), width: 0.3)
        }

        // Bordure du tableau
        strokeRect(context, x: x, y: tableStartY, w: w, h: cy - tableStartY, color: themePrimary, lineWidth: 0.8)

        return cy
    }

    private func drawTableHeader(_ context: CGContext, headers: [String], colW: [CGFloat], x: CGFloat, w: CGFloat, y: CGFloat) -> CGFloat {
        // Fond vert olive
        fillRect(context, x: x, y: y, w: w, h: PDFLayout.tableHeaderHeight, color: themePrimary)

        var colX = x
        for (i, h) in headers.enumerated() {
            if i == 0 {
                drawText(h, x: colX + 6, y: y + 9,
                         font: PDFLayout.fontTableHeader, color: PDFLayout.textWhite, context: context, maxWidth: colW[i] - 12)
            } else {
                drawTextRight(h, rightX: colX + colW[i] - 6, y: y + 9,
                              font: PDFLayout.fontTableHeader, color: PDFLayout.textWhite, context: context, maxWidth: colW[i] - 12)
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

        drawTextRight(L10n.totalHT(lang), rightX: labelRight, y: cy,
                      font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        drawTextRight("\(formatSpaced(document.totalHT)) \(cur)", rightX: valueRight, y: cy,
                      font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        cy += 16

        // Ligne de separation
        strokeLine(context, x1: labelRight - 30, y1: cy - 2, x2: valueRight, y2: cy - 2,
                   color: themePrimary.withAlphaComponent(0.2), width: 0.3)

        drawTextRight(L10n.totalVAT(lang), rightX: labelRight, y: cy,
                      font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        drawTextRight("\(formatSpaced(document.totalTVA)) \(cur)", rightX: valueRight, y: cy,
                      font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
        cy += 18

        // Ligne de separation
        strokeLine(context, x1: labelRight - 30, y1: cy - 2, x2: valueRight, y2: cy - 2,
                   color: themePrimary.withAlphaComponent(0.3), width: 0.5)

        drawTextRight(L10n.totalTTC(lang), rightX: labelRight, y: cy,
                      font: PDFLayout.fontTotalTTC, color: PDFLayout.textBlack, context: context)
        drawTextRight("\(formatSpaced(document.totalTTC)) \(cur)", rightX: valueRight, y: cy,
                      font: PDFLayout.fontTotalTTC, color: PDFLayout.textBlack, context: context)
        cy += 16

        return cy
    }

    // MARK: - 5. Signatures de transaction

    private func drawTransactionSignatures(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = ensurePageSpace(context, y: y, needed: 30)
        drawText(L10n.paymentProofs(lang), x: mL, y: cy,
                 font: PDFLayout.fontSection, color: themeDark, context: context)
        cy += 16

        for tx in document.transactionSignatures {
            let rowHeight: CGFloat = tx.explorerURL == nil ? 24 : 38
            cy = ensurePageSpace(context, y: cy, needed: rowHeight)
            drawText("\(formatDate(tx.date)) — \(document.currency.format(tx.montant, lang: lang)) via \(tx.blockchain.label)",
                     x: mL + 5, y: cy, font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
            cy += 13

            let sig = tx.signature.count > 60 ? "\(tx.signature.prefix(30))...\(tx.signature.suffix(10))" : tx.signature
            drawText("\(L10n.txPrefix(lang))\(sig)", x: mL + 10, y: cy,
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

    // MARK: - Notes

    private func drawNotes(_ context: CGContext, y: CGFloat) -> CGFloat {
        var cy = ensurePageSpace(context, y: y, needed: 34)

        drawText(L10n.notesLabel(lang), x: mL, y: cy,
                 font: PDFLayout.fontSection, color: themeDark, context: context)
        cy += 13
        strokeLine(context, x1: mL, y1: cy, x2: mL + cW, y2: cy,
                   color: themeDark.withAlphaComponent(0.4), width: 0.5)
        cy += 8

        let maxLineWidth = cW
        let lineHeight: CGFloat = 13
        let lines = wrappedLines(document.notes, font: PDFLayout.fontBody, maxWidth: maxLineWidth)

        for line in lines {
            cy = ensurePageSpace(context, y: cy, needed: lineHeight)
            if !line.isEmpty {
                drawText(line, x: mL, y: cy,
                         font: PDFLayout.fontBody, color: PDFLayout.textBlack, context: context)
            }
            cy += lineHeight
        }

        return cy
    }

    // MARK: - 7. Pied de page (bloc entreprise + paiement)

    private var footerRightX: CGFloat {
        pW / 2 + 10
    }

    private var footerRightWidth: CGFloat {
        pW - mR - footerRightX
    }

    private var footerLineHeight: CGFloat {
        11
    }

    private var shouldRenderPaymentDetails: Bool {
        switch document.paymentMode {
        case .aucun:
            return false
        case .crypto:
            return document.selectedPaymentWalletAddress(from: company.wallets) != nil
        case .virement:
            return !trimmedPaymentValue(company.iban).isEmpty
                || !trimmedPaymentValue(company.bic).isEmpty
                || !trimmedPaymentValue(company.titulaireCompte).isEmpty
        }
    }

    private func trimmedPaymentValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func footerNeededHeight(showPayment: Bool, solanaPayQR: CGImage?) -> CGFloat {
        var needed = 10 + footerBlockHeight(showPayment: showPayment) + 10
        if solanaPayQR != nil {
            needed += 5 + PDFLayout.qrCodeSize + 18
        }
        return needed
    }

    private func footerBlockHeight(showPayment: Bool) -> CGFloat {
        max(70, paymentFooterContentHeight(showPayment: showPayment))
    }

    private func paymentFooterContentHeight(showPayment: Bool) -> CGFloat {
        guard showPayment else { return 0 }

        switch document.paymentMode {
        case .aucun:
            return 0
        case .crypto:
            var height: CGFloat = 12 + 12
            if let address = document.selectedPaymentWalletAddress(from: company.wallets) {
                height += 12
                height += wrappedTextHeight(address, font: PDFLayout.fontSmall, maxWidth: footerRightWidth, lineHeight: footerLineHeight)
            }
            return height
        case .virement:
            var height: CGFloat = 12
            let iban = trimmedPaymentValue(company.iban)
            if !iban.isEmpty {
                height += wrappedTextHeight("\(L10n.iban(lang)): \(iban)", font: PDFLayout.fontSmall, maxWidth: footerRightWidth, lineHeight: footerLineHeight)
            }
            let bic = trimmedPaymentValue(company.bic)
            if !bic.isEmpty {
                height += wrappedTextHeight("\(L10n.bic(lang)): \(bic)", font: PDFLayout.fontSmall, maxWidth: footerRightWidth, lineHeight: footerLineHeight)
            }
            let accountHolder = trimmedPaymentValue(company.titulaireCompte)
            if !accountHolder.isEmpty {
                height += wrappedTextHeight("\(L10n.accountHolder(lang))\(accountHolder)", font: PDFLayout.fontSmall, maxWidth: footerRightWidth, lineHeight: footerLineHeight)
            }
            return height
        }
    }

    private func wrappedTextHeight(_ text: String, font: NSFont, maxWidth: CGFloat, lineHeight: CGFloat) -> CGFloat {
        CGFloat(wrappedLines(text, font: font, maxWidth: maxWidth).count) * lineHeight
    }

    @discardableResult
    private func drawWrappedText(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        font: NSFont,
        color: NSColor,
        context: CGContext,
        maxWidth: CGFloat,
        lineHeight: CGFloat
    ) -> CGFloat {
        var cy = y
        for line in wrappedLines(text, font: font, maxWidth: maxWidth) {
            drawText(line, x: x, y: cy, font: font, color: color, context: context, maxWidth: maxWidth)
            cy += lineHeight
        }
        return cy
    }

    private func drawFooterBlock(_ context: CGContext, y: CGFloat, showPayment: Bool = true, solanaPayQR: CGImage? = nil) -> CGFloat {
        var cy = y + 10

        // Bordure verte epaisse a gauche du bloc
        let blockTop = cy
        let blockHeight = footerBlockHeight(showPayment: showPayment)
        fillRect(context, x: mL, y: cy, w: 4, h: blockHeight, color: themePrimary)

        let leftX = mL + 14
        let rightX = footerRightX

        // Colonne gauche : infos entreprise
        drawText(company.nom.isEmpty ? L10n.companyFallback(lang) : company.nom.uppercased(),
                 x: leftX, y: cy, font: PDFLayout.fontSmallBold, color: PDFLayout.textBlack, context: context)
        cy += 12
        if !company.ville.isEmpty || !company.codePostal.isEmpty {
            drawText(addressLine(city: company.ville, postalCode: company.codePostal, uppercaseCity: true),
                     x: leftX, y: cy, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
        }
        cy += 11
        if !company.siret.isEmpty {
            drawText("\(L10n.siret(lang)): \(company.siret)",
                     x: leftX, y: cy, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
        }
        cy += 11
        if !company.telephone.isEmpty {
            drawText("\(L10n.phoneShort(lang)): \(company.telephone)",
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
        } else if document.paymentMode == .crypto, let walletAddress = document.selectedPaymentWalletAddress(from: company.wallets) {
            let chainLabel = document.blockchain?.label ?? "Crypto"
            drawText(chainLabel, x: rightX, y: ry, font: PDFLayout.fontSmallBold, color: PDFLayout.textBlack, context: context)
            ry += 12
            drawText(L10n.cryptoTransfer(lang), x: rightX, y: ry, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
            ry += 12
            drawText(L10n.walletAddress(lang), x: rightX, y: ry, font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
            ry += 12
            ry = drawWrappedText(walletAddress, x: rightX, y: ry, font: PDFLayout.fontSmall,
                                 color: PDFLayout.textBlack, context: context, maxWidth: footerRightWidth,
                                 lineHeight: footerLineHeight)
        } else {
            drawText(L10n.bankTransfer(lang), x: rightX, y: ry, font: PDFLayout.fontSmallBold, color: PDFLayout.textBlack, context: context)
            ry += 12
            let iban = trimmedPaymentValue(company.iban)
            if !iban.isEmpty {
                ry = drawWrappedText("\(L10n.iban(lang)): \(iban)", x: rightX, y: ry,
                                     font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context,
                                     maxWidth: footerRightWidth, lineHeight: footerLineHeight)
            }
            let bic = trimmedPaymentValue(company.bic)
            if !bic.isEmpty {
                ry = drawWrappedText("\(L10n.bic(lang)): \(bic)", x: rightX, y: ry,
                                     font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context,
                                     maxWidth: footerRightWidth, lineHeight: footerLineHeight)
            }
            let accountHolder = trimmedPaymentValue(company.titulaireCompte)
            if !accountHolder.isEmpty {
                ry = drawWrappedText("\(L10n.accountHolder(lang))\(accountHolder)", x: rightX, y: ry,
                                     font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context,
                                     maxWidth: footerRightWidth, lineHeight: footerLineHeight)
            }
        }

        var endY = blockTop + blockHeight + 10

        // QR code Solana Pay (sous le bloc footer, centré)
        if let qr = solanaPayQR {
            let qrSize = PDFLayout.qrCodeSize
            let qrX = pW / 2 + 10
            let qrY = endY + 5
            drawImage(context, image: qr, x: qrX, y: qrY, w: qrSize, h: qrSize)
            drawSolanaLogo(context, centerX: qrX + qrSize / 2, centerY: qrY + qrSize / 2, size: 18)
            let labelWidth = textWidth(L10n.scanToPay(lang), font: PDFLayout.fontSmall)
            drawText(L10n.scanToPay(lang), x: qrX + (qrSize - labelWidth) / 2, y: qrY + qrSize + 4,
                     font: PDFLayout.fontSmall, color: PDFLayout.textGray, context: context)
            endY = qrY + qrSize + 18
        }

        return endY
    }

    // MARK: - Logo Solana (centre du QR)

    /// Dessine le logo Solana PNG au centre du QR code avec fond blanc carré
    private func drawSolanaLogo(_ context: CGContext, centerX: CGFloat, centerY: CGFloat, size: CGFloat) {
        let padding = size * 0.3
        let bgSize = size + padding

        // Fond blanc carré
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(
            x: centerX - bgSize / 2, y: cgY(centerY) - bgSize / 2,
            width: bgSize, height: bgSize
        ))

        // Charger le logo Solana depuis les ressources (Bundle.main ou Bundle.module)
        let url: URL? = Bundle.main.url(forResource: "solanaLogo", withExtension: "png")
            ?? {
                // SPM resource bundle (dev via swift run)
                let bundlePath = Bundle.main.bundleURL.appendingPathComponent("Facio_Facio.bundle")
                return Bundle(path: bundlePath.path)?.url(forResource: "solanaLogo", withExtension: "png")
            }()
        guard let url,
              let dataProvider = CGDataProvider(url: url as CFURL),
              let logo = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        else { return }

        let rect = CGRect(
            x: centerX - size / 2,
            y: cgY(centerY) - size / 2,
            width: size,
            height: size
        )
        context.draw(logo, in: rect)
    }

    // MARK: - Formatage nombres

    private var numberLocale: Locale {
        Locale(identifier: lang == .fr ? "fr_FR" : "en_US")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = numberLocale
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func addressLine(city: String, postalCode: String, uppercaseCity: Bool = false) -> String {
        let cityValue = uppercaseCity ? city.uppercased() : city
        if lang == .fr {
            return [postalCode, cityValue]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
        return [cityValue, postalCode]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    /// Formate un Decimal avec 2 decimales sans separateur de milliers.
    private func formatNumber(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = numberLocale
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    private func formatCurrencyNumber(_ value: Decimal, usesGroupingSeparator: Bool = true) -> String {
        document.currency.formatNumber(value, lang: lang, usesGroupingSeparator: usesGroupingSeparator)
    }

    /// Formate un Decimal avec separateur de milliers.
    private func formatSpaced(_ value: Decimal) -> String {
        formatCurrencyNumber(value)
    }
}
