import AppKit

/// Renders the entire status-bar label — battery glyph + percentage + live
/// wattage — as a single bitmap sized exactly to its content, so the status
/// item takes no more menu-bar width than it needs (narrow on battery, wider
/// while charging when the wattage text is shown).
///
/// `MenuBarExtra` does not reliably remeasure its status item when a plain
/// SwiftUI label's content changes size (verified directly: charging wattage
/// text added to the label was silently clipped even though it rendered
/// correctly in the dropdown). Rendering to an `NSImage` avoids that, and
/// `MenuBarLabel` additionally re-identifies its view whenever the wattage
/// text appears/disappears to force a fresh layout pass.
enum MenuBarIconRenderer {
    static let canvasHeight: CGFloat = 18

    private static let percentFont = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    private static let wattageFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)

    static func makeLabel(percent: Int, batteryColor: NSColor, charging: Bool,
                           wattageText: String?, wattageColor: NSColor) -> NSImage {
        let battery = BatteryIconRenderer.makeIcon(percent: percent, color: batteryColor, charging: charging)

        let percentAttrs: [NSAttributedString.Key: Any] = [.font: percentFont, .foregroundColor: NSColor.labelColor]
        let percentString = "\(percent)%"
        let percentSize = percentString.size(withAttributes: percentAttrs)

        let wattageAttrs: [NSAttributedString.Key: Any] = [.font: wattageFont, .foregroundColor: wattageColor]
        let wattageSize = wattageText?.size(withAttributes: wattageAttrs)

        var width = battery.size.width + 4 + ceil(percentSize.width)
        if let wattageSize { width += 4 + ceil(wattageSize.width) }
        let canvasSize = NSSize(width: width, height: canvasHeight)

        let image = NSImage(size: canvasSize)
        image.lockFocus()
        defer { image.unlockFocus() }

        var x: CGFloat = 0

        battery.draw(in: NSRect(x: x, y: (canvasSize.height - battery.size.height) / 2,
                                 width: battery.size.width, height: battery.size.height))
        x += battery.size.width + 4

        percentString.draw(at: NSPoint(x: x, y: (canvasSize.height - percentSize.height) / 2 - 0.5), withAttributes: percentAttrs)
        x += ceil(percentSize.width) + 4

        if let wattageText, let wattageSize {
            wattageText.draw(at: NSPoint(x: x, y: (canvasSize.height - wattageSize.height) / 2 - 0.5), withAttributes: wattageAttrs)
        }

        image.isTemplate = false
        return image
    }
}
