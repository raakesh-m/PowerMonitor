import AppKit

/// Renders the entire status-bar label — battery glyph + percentage + live
/// wattage — as a single fixed-size bitmap.
///
/// `MenuBarExtra` measures its status item's width once, on the very first
/// layout pass, and does not reliably remeasure afterward when the label's
/// content changes size (verified directly: charging wattage text added to
/// the label was silently clipped even though it rendered correctly in the
/// dropdown). Drawing everything into one image with a constant canvas size
/// sidesteps that entirely — the status item's width never needs to change.
enum MenuBarIconRenderer {
    /// Wide enough for the longest realistic content ("100% 100W").
    static let canvasSize = NSSize(width: 92, height: 18)

    static func makeLabel(percent: Int, batteryColor: NSColor, charging: Bool,
                           wattageText: String?, wattageColor: NSColor) -> NSImage {
        let image = NSImage(size: canvasSize)
        image.lockFocus()
        defer { image.unlockFocus() }

        var x: CGFloat = 0

        let battery = BatteryIconRenderer.makeIcon(percent: percent, color: batteryColor, charging: charging)
        battery.draw(in: NSRect(x: x, y: (canvasSize.height - battery.size.height) / 2,
                                 width: battery.size.width, height: battery.size.height))
        x += battery.size.width + 4

        let percentFont = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        let percentAttrs: [NSAttributedString.Key: Any] = [.font: percentFont, .foregroundColor: NSColor.labelColor]
        let percentString = "\(percent)%"
        let percentSize = percentString.size(withAttributes: percentAttrs)
        percentString.draw(at: NSPoint(x: x, y: (canvasSize.height - percentSize.height) / 2 - 0.5), withAttributes: percentAttrs)
        x += percentSize.width + 4

        if let wattageText {
            let wattageFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
            let wattageAttrs: [NSAttributedString.Key: Any] = [.font: wattageFont, .foregroundColor: wattageColor]
            let wattageSize = wattageText.size(withAttributes: wattageAttrs)
            wattageText.draw(at: NSPoint(x: x, y: (canvasSize.height - wattageSize.height) / 2 - 0.5), withAttributes: wattageAttrs)
        }

        image.isTemplate = false
        return image
    }
}
