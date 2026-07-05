import SwiftUI
import AppKit

/// Hand-drawn, colored battery icon for the menu bar.
///
/// AppKit's status bar auto-converts `Image(systemName:)` content (and,
/// empirically, plain SwiftUI `Shape`s placed in a `MenuBarExtra` label) into
/// a template image, discarding any color. The only reliable way to show a
/// real yellow/red/green fill — the way macOS's own battery indicator does —
/// is to rasterize the icon into an `NSImage` ourselves and explicitly mark
/// it `isTemplate = false`, which AppKit then renders as-is.
enum BatteryIconRenderer {
    static func makeIcon(percent: Int, color: NSColor, charging: Bool) -> NSImage {
        let width: CGFloat = 22
        let height: CGFloat = 13
        let image = NSImage(size: NSSize(width: width, height: height))

        image.lockFocus()
        defer { image.unlockFocus() }

        let bodyWidth = width - 3
        let bodyRect = NSRect(x: 0.5, y: 1.5, width: bodyWidth - 1, height: height - 3)
        let corner: CGFloat = 2.5

        let outline = NSBezierPath(roundedRect: bodyRect, xRadius: corner, yRadius: corner)
        outline.lineWidth = 1.1
        NSColor.labelColor.withAlphaComponent(0.6).setStroke()
        outline.stroke()

        let inset: CGFloat = 1.6
        let ratio = CGFloat(max(0, min(100, percent))) / 100
        let fillWidth = max(1.5, (bodyRect.width - inset * 2) * ratio)
        let fillRect = NSRect(x: bodyRect.minX + inset, y: bodyRect.minY + inset,
                               width: fillWidth, height: bodyRect.height - inset * 2)
        let fillCorner = max(0.5, corner - inset)
        let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: fillCorner, yRadius: fillCorner)
        color.setFill()
        fillPath.fill()

        let nubRect = NSRect(x: bodyRect.maxX + 1, y: bodyRect.midY - height * 0.16,
                              width: 1.6, height: height * 0.32)
        NSColor.labelColor.withAlphaComponent(0.6).setFill()
        NSBezierPath(roundedRect: nubRect, xRadius: 0.5, yRadius: 0.5).fill()

        if charging {
            let bolt = NSBezierPath()
            let bx = bodyRect.minX + bodyRect.width * 0.32
            let by = bodyRect.minY
            let bw = bodyRect.width * 0.42
            let bh = bodyRect.height
            bolt.move(to: NSPoint(x: bx + bw * 0.62, y: by + bh))
            bolt.line(to: NSPoint(x: bx + bw * 0.08, y: by + bh * 0.42))
            bolt.line(to: NSPoint(x: bx + bw * 0.46, y: by + bh * 0.42))
            bolt.line(to: NSPoint(x: bx + bw * 0.38, y: by))
            bolt.line(to: NSPoint(x: bx + bw * 0.92, y: by + bh * 0.6))
            bolt.line(to: NSPoint(x: bx + bw * 0.54, y: by + bh * 0.6))
            bolt.close()
            NSColor.black.withAlphaComponent(0.7).setFill()
            bolt.fill()
        }

        image.isTemplate = false
        return image
    }
}

/// SwiftUI wrapper around the rasterized icon.
struct BatteryGlyph: View {
    let percent: Int
    let color: Color
    let charging: Bool

    var body: some View {
        Image(nsImage: BatteryIconRenderer.makeIcon(percent: percent, color: NSColor(color), charging: charging))
    }
}
