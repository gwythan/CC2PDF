#!/usr/bin/env swift
// Standalone script — run with: swift Tools/make_icon.swift <output.png>
// Renders the CC2PDF icon to a 1024×1024 PNG using the same design as AppIconFactory.
import AppKit

func makeIcon(size: CGFloat = 1024) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    // Navy rounded background
    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    let bg = NSBezierPath(roundedRect: canvas.insetBy(dx: size * 0.04, dy: size * 0.04),
                          xRadius: size * 0.18, yRadius: size * 0.18)
    NSColor(calibratedRed: 0.06, green: 0.19, blue: 0.36, alpha: 1.0).setFill()
    bg.fill()

    // White document body
    let documentRect = NSRect(x: size * 0.17, y: size * 0.12, width: size * 0.66, height: size * 0.76)
    let doc = NSBezierPath(roundedRect: documentRect, xRadius: size * 0.05, yRadius: size * 0.05)
    NSColor(calibratedRed: 0.98, green: 0.99, blue: 1.0, alpha: 1.0).setFill()
    doc.fill()

    // Dog-ear fold (top-right)
    let fold = NSBezierPath()
    fold.move(to: NSPoint(x: documentRect.maxX - size * 0.16, y: documentRect.maxY))
    fold.line(to: NSPoint(x: documentRect.maxX, y: documentRect.maxY - size * 0.16))
    fold.line(to: NSPoint(x: documentRect.maxX, y: documentRect.maxY))
    fold.close()
    NSColor(calibratedRed: 0.87, green: 0.91, blue: 0.98, alpha: 1.0).setFill()
    fold.fill()

    // Horizontal text stripes
    let stripeH = size * 0.02
    for idx in 0..<5 {
        let y = documentRect.minY + size * (0.44 + CGFloat(idx) * 0.08)
        let r = NSRect(x: documentRect.minX + size * 0.07, y: y, width: size * 0.52, height: stripeH)
        let stripe = NSBezierPath(roundedRect: r, xRadius: stripeH / 2, yRadius: stripeH / 2)
        NSColor(calibratedRed: 0.85, green: 0.89, blue: 0.95, alpha: 1.0).setFill()
        stripe.fill()
    }

    // Green "CC → PDF" badge
    let badgeRect = NSRect(x: size * 0.2, y: size * 0.18, width: size * 0.6, height: size * 0.25)
    let badge = NSBezierPath(roundedRect: badgeRect, xRadius: size * 0.06, yRadius: size * 0.06)
    NSColor(calibratedRed: 0.09, green: 0.56, blue: 0.34, alpha: 1.0).setFill()
    badge.fill()

    let label = "CC → PDF" as NSString
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: size * 0.09),
        .foregroundColor: NSColor.white
    ]
    let labelSize = label.size(withAttributes: attrs)
    let origin = NSPoint(x: badgeRect.midX - labelSize.width / 2,
                         y: badgeRect.midY - labelSize.height / 2)
    label.draw(at: origin, withAttributes: attrs)

    return image
}

// --- Entry point ---
guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift Tools/make_icon.swift <output.png>\n", stderr)
    exit(1)
}

let outputPath = CommandLine.arguments[1]
let icon = makeIcon()

guard let tiffData = icon.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Error: could not render icon to PNG\n", stderr)
    exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Icon written to \(outputPath)")
} catch {
    fputs("Error writing icon: \(error)\n", stderr)
    exit(1)
}
