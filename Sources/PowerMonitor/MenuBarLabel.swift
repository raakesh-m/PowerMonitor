import SwiftUI

/// Compact status-bar label: battery icon (filled to actual level, colored by
/// state) + percentage + live charging wattage colored by speed tier.
///
/// Rendered as a single fixed-size bitmap via `MenuBarIconRenderer` — see its
/// doc comment for why (MenuBarExtra does not reliably resize its status item
/// when a plain SwiftUI label's content changes).
struct MenuBarLabel: View {
    let snapshot: PowerSnapshot

    private var speed: ChargeSpeed {
        ChargeSpeed.classify(watts: snapshot.externalConnected ? snapshot.livePower : nil)
    }

    /// Same convention macOS itself uses: yellow while Low Power Mode is on,
    /// red when critically low and unplugged, green while charging.
    private var batteryColor: Color {
        if snapshot.isLowPowerMode { return .yellow }
        if snapshot.batteryPercent <= 10 && !snapshot.isCharging { return .red }
        if snapshot.isCharging { return .green }
        return .primary
    }

    var body: some View {
        Image(nsImage: MenuBarIconRenderer.makeLabel(
            percent: snapshot.batteryPercent,
            batteryColor: NSColor(batteryColor),
            charging: snapshot.isCharging,
            wattageText: snapshot.externalConnected ? String(format: "%.0fW", snapshot.livePower ?? 0) : nil,
            wattageColor: NSColor(speed.color)
        ))
    }
}
