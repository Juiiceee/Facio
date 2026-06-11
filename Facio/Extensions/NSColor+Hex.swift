import AppKit

extension NSColor {
    /// Parse "#RRGGBB" or "RRGGBB" hex string to NSColor (sRGB)
    static func fromHex(_ hex: String) -> NSColor? {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let int = UInt64(h, radix: 16) else { return nil }

        let r = CGFloat((int >> 16) & 0xFF) / 255.0
        let g = CGFloat((int >> 8) & 0xFF) / 255.0
        let b = CGFloat(int & 0xFF) / 255.0
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    /// Convert to "#RRGGBB" hex string (sRGB)
    func toHex() -> String {
        guard let c = usingColorSpace(.sRGB) else { return "#000000" }
        let r = Int(round(c.redComponent * 255))
        let g = Int(round(c.greenComponent * 255))
        let b = Int(round(c.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// Darker variant — multiplies RGB by (1 - factor)
    func darkened(by factor: CGFloat = 0.15) -> NSColor {
        guard let c = usingColorSpace(.sRGB) else { return self }
        let f = 1.0 - factor
        return NSColor(srgbRed: c.redComponent * f,
                       green: c.greenComponent * f,
                       blue: c.blueComponent * f,
                       alpha: c.alphaComponent)
    }

    /// Lighter variant — moves RGB towards white by `factor` (miroir de `darkened(by:)`).
    /// Utilisé pour l'accent de marque en mode sombre (lisibilité du texte/icônes).
    func lightened(by factor: CGFloat = 0.15) -> NSColor {
        guard let c = usingColorSpace(.sRGB) else { return self }
        return NSColor(srgbRed: c.redComponent + (1.0 - c.redComponent) * factor,
                       green: c.greenComponent + (1.0 - c.greenComponent) * factor,
                       blue: c.blueComponent + (1.0 - c.blueComponent) * factor,
                       alpha: c.alphaComponent)
    }
}
