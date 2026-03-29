#!/usr/bin/env swift
import AppKit

// Convertit une image PNG en .icns pour macOS
let args = CommandLine.arguments
guard args.count >= 2 else {
    print("Usage: swift convert-icon.swift <image.png> [output.icns]")
    exit(1)
}

let inputPath = args[1]
let outputPath = args.count >= 3 ? args[2] : "Facio/Resources/AppIcon.icns"

guard let image = NSImage(contentsOfFile: inputPath) else {
    print("Erreur: impossible de charger \(inputPath)")
    exit(1)
}

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

let iconsetPath = "Facio/Resources/AppIcon.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetPath)
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for entry in sizes {
    let s = CGFloat(entry.size)
    let resized = NSImage(size: NSSize(width: s, height: s))
    resized.lockFocus()
    image.draw(in: NSRect(x: 0, y: 0, width: s, height: s),
               from: NSRect(origin: .zero, size: image.size),
               operation: .sourceOver,
               fraction: 1.0)
    resized.unlockFocus()

    guard let tiff = resized.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Erreur: \(entry.name)")
        continue
    }
    try! png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(entry.name).png"))
    print("  \(entry.name).png (\(entry.size)x\(entry.size))")
}

print("\nConversion en .icns...")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath, "-o", outputPath]
try! process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    try? fm.removeItem(atPath: iconsetPath)
    print("AppIcon.icns cree avec succes !")
} else {
    print("Erreur lors de la conversion")
    exit(1)
}
