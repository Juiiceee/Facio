#!/usr/bin/env swift
import AppKit

// Genere l'icone de Facio
// Produit un .iconset puis le convertit en .icns

let sizes: [(name: String, size: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

func drawIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()

    let s = size
    let scale = s / 1024.0

    // === Fond arrondi vert avec gradient ===
    let bgRect = CGRect(x: 40 * scale, y: 40 * scale, width: 944 * scale, height: 944 * scale)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 210 * scale, yRadius: 210 * scale)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.50, green: 0.68, blue: 0.22, alpha: 1.0),
        NSColor(red: 0.38, green: 0.52, blue: 0.18, alpha: 1.0),
        NSColor(red: 0.26, green: 0.40, blue: 0.12, alpha: 1.0),
    ], atLocations: [0.0, 0.5, 1.0], colorSpace: .deviceRGB)!
    gradient.draw(in: bgPath, angle: -45)

    // Reflet subtil en haut
    let reflectRect = CGRect(x: 60 * scale, y: s - 500 * scale, width: 904 * scale, height: 420 * scale)
    let reflectPath = NSBezierPath(roundedRect: reflectRect, xRadius: 190 * scale, yRadius: 190 * scale)
    NSColor.white.withAlphaComponent(0.06).setFill()
    reflectPath.fill()

    // === Document arriere (pile) ===
    let backDocRect = CGRect(x: 280 * scale, y: s - 845 * scale, width: 490 * scale, height: 640 * scale)
    NSColor.black.withAlphaComponent(0.12).setFill()
    NSBezierPath(roundedRect: backDocRect.offsetBy(dx: 5 * scale, dy: -5 * scale), xRadius: 18 * scale, yRadius: 18 * scale).fill()
    NSColor(white: 0.90, alpha: 0.65).setFill()
    NSBezierPath(roundedRect: backDocRect, xRadius: 18 * scale, yRadius: 18 * scale).fill()

    // === Document principal ===
    let docX: CGFloat = 230 * scale
    let docY: CGFloat = s - 825 * scale
    let docW: CGFloat = 500 * scale
    let docH: CGFloat = 650 * scale
    let docRect = CGRect(x: docX, y: docY, width: docW, height: docH)

    // Ombre
    NSColor.black.withAlphaComponent(0.15).setFill()
    NSBezierPath(roundedRect: docRect.offsetBy(dx: 4 * scale, dy: -4 * scale), xRadius: 18 * scale, yRadius: 18 * scale).fill()

    // Document blanc
    let docPath = NSBezierPath(roundedRect: docRect, xRadius: 18 * scale, yRadius: 18 * scale)
    let docGrad = NSGradient(starting: NSColor(white: 1.0, alpha: 1.0), ending: NSColor(white: 0.97, alpha: 1.0))!
    docGrad.draw(in: docPath, angle: -90)

    // === Bandeau vert en haut ===
    let headerH: CGFloat = 75 * scale
    let headerRect = CGRect(x: docX, y: docY + docH - headerH, width: docW, height: headerH)

    guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }
    ctx.saveGState()
    NSBezierPath(roundedRect: docRect, xRadius: 18 * scale, yRadius: 18 * scale).addClip()
    let headerGrad = NSGradient(starting: NSColor(red: 0.42, green: 0.56, blue: 0.23, alpha: 1.0),
                                ending: NSColor(red: 0.52, green: 0.66, blue: 0.28, alpha: 1.0))!
    headerGrad.draw(in: headerRect, angle: 0)
    ctx.restoreGState()

    // === Texte "FACIO" centre dans le bandeau ===
    if size >= 32 {
        let titleSize = max(10, 30 * scale)
        let titleFont = NSFont(name: "Helvetica Neue", size: titleSize) ?? NSFont.systemFont(ofSize: titleSize, weight: .bold)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont(descriptor: titleFont.fontDescriptor.withSymbolicTraits(.bold), size: titleSize) ?? titleFont,
            .foregroundColor: NSColor.white,
            .kern: 4.0 * scale,
        ]
        let titleStr = NSAttributedString(string: "FACIO", attributes: titleAttrs)
        let ts = titleStr.size()
        titleStr.draw(at: NSPoint(x: docX + (docW - ts.width) / 2, y: docY + docH - headerH + (headerH - ts.height) / 2))
    }

    // === Contenu du document ===

    // Lignes de date (gauche)
    NSColor(white: 0.72, alpha: 0.5).setFill()
    NSBezierPath(roundedRect: CGRect(x: docX + 40 * scale, y: docY + docH - 125 * scale, width: 170 * scale, height: 7 * scale),
                 xRadius: 3.5 * scale, yRadius: 3.5 * scale).fill()
    NSBezierPath(roundedRect: CGRect(x: docX + 40 * scale, y: docY + docH - 143 * scale, width: 115 * scale, height: 7 * scale),
                 xRadius: 3.5 * scale, yRadius: 3.5 * scale).fill()

    // Bloc destinataire (droite)
    NSColor(red: 0.42, green: 0.56, blue: 0.23, alpha: 0.7).setFill()
    NSBezierPath(roundedRect: CGRect(x: docX + 295 * scale, y: docY + docH - 115 * scale, width: 85 * scale, height: 5 * scale),
                 xRadius: 2.5 * scale, yRadius: 2.5 * scale).fill()
    // Ligne verte
    NSColor(red: 0.42, green: 0.56, blue: 0.23, alpha: 0.5).setStroke()
    let destLine = NSBezierPath()
    destLine.move(to: NSPoint(x: docX + 295 * scale, y: docY + docH - 122 * scale))
    destLine.line(to: NSPoint(x: docX + docW - 40 * scale, y: docY + docH - 122 * scale))
    destLine.lineWidth = 0.8 * scale
    destLine.stroke()

    NSColor(white: 0.4, alpha: 0.5).setFill()
    NSBezierPath(roundedRect: CGRect(x: docX + 295 * scale, y: docY + docH - 138 * scale, width: 130 * scale, height: 7 * scale),
                 xRadius: 3.5 * scale, yRadius: 3.5 * scale).fill()
    NSBezierPath(roundedRect: CGRect(x: docX + 295 * scale, y: docY + docH - 155 * scale, width: 95 * scale, height: 6 * scale),
                 xRadius: 3 * scale, yRadius: 3 * scale).fill()

    // === Tableau ===
    let tableX = docX + 35 * scale
    let tableW = docW - 70 * scale
    let tableTopY = docY + docH - 195 * scale
    let thH: CGFloat = 30 * scale

    // En-tete vert
    let thRect = CGRect(x: tableX, y: tableTopY, width: tableW, height: thH)
    NSBezierPath(roundedRect: thRect, xRadius: 5 * scale, yRadius: 5 * scale)
    NSColor(red: 0.42, green: 0.56, blue: 0.23, alpha: 1.0).setFill()
    NSBezierPath(roundedRect: thRect, xRadius: 5 * scale, yRadius: 5 * scale).fill()

    // Texte en-tete
    if size >= 128 {
        let thFont = NSFont.systemFont(ofSize: max(7, 12 * scale), weight: .semibold)
        let thAttrs: [NSAttributedString.Key: Any] = [.font: thFont, .foregroundColor: NSColor.white]
        NSAttributedString(string: "DESIGNATION", attributes: thAttrs)
            .draw(at: NSPoint(x: tableX + 8 * scale, y: tableTopY + 8 * scale))
        NSAttributedString(string: "TOTAL", attributes: thAttrs)
            .draw(at: NSPoint(x: tableX + tableW - 60 * scale, y: tableTopY + 8 * scale))
    }

    // Lignes du tableau
    let rowH: CGFloat = 26 * scale
    for i in 0..<2 {
        let rowY = tableTopY - CGFloat(i + 1) * rowH
        if i == 0 {
            NSColor(red: 0.96, green: 0.97, blue: 0.94, alpha: 0.5).setFill()
            NSBezierPath(rect: CGRect(x: tableX, y: rowY, width: tableW, height: rowH)).fill()
        }
        let lineWidths: [CGFloat] = [130, 95]
        let valueWidths: [CGFloat] = [48, 40]
        NSColor(white: 0.38, alpha: 0.5).setFill()
        NSBezierPath(roundedRect: CGRect(x: tableX + 8 * scale, y: rowY + 10 * scale, width: lineWidths[i] * scale, height: 6 * scale),
                     xRadius: 3 * scale, yRadius: 3 * scale).fill()
        NSBezierPath(roundedRect: CGRect(x: tableX + tableW - (valueWidths[i] + 8) * scale, y: rowY + 10 * scale, width: valueWidths[i] * scale, height: 6 * scale),
                     xRadius: 3 * scale, yRadius: 3 * scale).fill()
    }

    // Bordure tableau
    NSColor(red: 0.42, green: 0.56, blue: 0.23, alpha: 0.35).setStroke()
    let tableBorder = NSBezierPath(rect: CGRect(x: tableX, y: tableTopY - 2 * rowH, width: tableW, height: thH + 2 * rowH))
    tableBorder.lineWidth = 0.8 * scale
    tableBorder.stroke()

    // Separateur sous tableau
    NSColor(red: 0.42, green: 0.56, blue: 0.23, alpha: 0.4).setStroke()
    let sep = NSBezierPath()
    sep.move(to: NSPoint(x: tableX, y: tableTopY - 2 * rowH))
    sep.line(to: NSPoint(x: tableX + tableW, y: tableTopY - 2 * rowH))
    sep.lineWidth = 1 * scale
    sep.stroke()

    // === Total TTC ===
    if size >= 64 {
        let ttcFont = NSFont.systemFont(ofSize: max(8, 14 * scale), weight: .bold)
        let ttcAttrs: [NSAttributedString.Key: Any] = [.font: ttcFont, .foregroundColor: NSColor(red: 0.25, green: 0.38, blue: 0.10, alpha: 1.0)]
        let ttcStr = NSAttributedString(string: "Total TTC", attributes: ttcAttrs)
        let ttcSz = ttcStr.size()
        let ttcY = tableTopY - 2 * rowH - 30 * scale
        ttcStr.draw(at: NSPoint(x: tableX + tableW - ttcSz.width - 75 * scale, y: ttcY))

        // Montant vert
        NSColor(red: 0.42, green: 0.56, blue: 0.23, alpha: 0.85).setFill()
        NSBezierPath(roundedRect: CGRect(x: tableX + tableW - 65 * scale, y: ttcY + 2 * scale, width: 58 * scale, height: 10 * scale),
                     xRadius: 4 * scale, yRadius: 4 * scale).fill()
    }

    // === Pied de page avec barre verte ===
    NSColor(red: 0.42, green: 0.56, blue: 0.23, alpha: 1.0).setFill()
    NSBezierPath(roundedRect: CGRect(x: docX + 35 * scale, y: docY + 40 * scale, width: 4 * scale, height: 55 * scale),
                 xRadius: 2 * scale, yRadius: 2 * scale).fill()

    NSColor(white: 0.5, alpha: 0.4).setFill()
    NSBezierPath(roundedRect: CGRect(x: docX + 50 * scale, y: docY + 78 * scale, width: 95 * scale, height: 5 * scale),
                 xRadius: 2.5 * scale, yRadius: 2.5 * scale).fill()
    NSBezierPath(roundedRect: CGRect(x: docX + 50 * scale, y: docY + 64 * scale, width: 75 * scale, height: 5 * scale),
                 xRadius: 2.5 * scale, yRadius: 2.5 * scale).fill()
    NSBezierPath(roundedRect: CGRect(x: docX + 50 * scale, y: docY + 50 * scale, width: 105 * scale, height: 5 * scale),
                 xRadius: 2.5 * scale, yRadius: 2.5 * scale).fill()

    // === Cercles decoratifs ===
    let circles: [(x: CGFloat, y: CGFloat, r: CGFloat, color: NSColor)] = [
        (785, 215, 36, NSColor(red: 0.55, green: 0.62, blue: 0.24, alpha: 0.6)),
        (822, 248, 28, NSColor(red: 0.77, green: 0.66, blue: 0.22, alpha: 0.5)),
        (798, 182, 26, NSColor(red: 0.48, green: 0.37, blue: 0.65, alpha: 0.5)),
        (840, 210, 22, NSColor(red: 0.35, green: 0.48, blue: 0.17, alpha: 0.55)),
    ]
    for c in circles {
        let cx = c.x * scale
        let cy = s - c.y * scale
        let r = c.r * scale
        c.color.setFill()
        NSBezierPath(ovalIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)).fill()
    }

    img.unlockFocus()
    return img
}

// Creer le .iconset
let iconsetPath = "Facio/Resources/AppIcon.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetPath)
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for entry in sizes {
    let img = drawIcon(size: CGFloat(entry.size))
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Erreur: impossible de creer \(entry.name)")
        continue
    }
    let path = "\(iconsetPath)/\(entry.name).png"
    try! png.write(to: URL(fileURLWithPath: path))
    print("  \(entry.name).png (\(entry.size)x\(entry.size))")
}

print("\nIconset cree. Conversion en .icns...")

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath, "-o", "Facio/Resources/AppIcon.icns"]
try! process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    try? fm.removeItem(atPath: iconsetPath)
    print("AppIcon.icns cree avec succes !")
} else {
    print("Erreur lors de la conversion en .icns")
}
