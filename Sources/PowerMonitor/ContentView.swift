import SwiftUI
import Charts

struct ContentView: View {
    @EnvironmentObject var store: PowerStore
    @State private var pulse = false

    private var snap: PowerSnapshot { store.current }
    private var speed: ChargeSpeed { ChargeSpeed.classify(watts: snap.externalConnected ? snap.livePower : nil) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            if snap.externalConnected {
                statGrid
                Divider()
                sparkline
            } else {
                Label("Running on battery", systemImage: "battery.100percent")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
            if snap.isLowPowerMode {
                Label("Low Power Mode", systemImage: "leaf.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
            Divider()
            batteryRow
            Divider()
            Button {
                openBatterySettings()
            } label: {
                Label("Battery Settings…", systemImage: "gearshape")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            Divider()
            HStack {
                Text("Updates every 2s")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private func openBatterySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    private var header: some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                if snap.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(speed.color)
                        .opacity(speed.animates && pulse ? 1.0 : 0.55)
                }
            }
            .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(snap.displayName)
                    .font(.headline)
                if snap.externalConnected {
                    HStack(spacing: 4) {
                        Text(String(format: "%.1fW", snap.livePower ?? 0))
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(speed.color)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(speed.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let watts = snap.ratedWatts {
                        Text("Rated \(Int(watts))W" + (snap.adapterManufacturer.map { " · \($0)" } ?? ""))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
        }
        .onAppear { updatePulse() }
        .onChange(of: speed) { _ in updatePulse() }
    }

    private func updatePulse() {
        guard speed.animates else { pulse = false; return }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }

    private var statusIcon: String {
        if !snap.externalConnected { return batteryIcon }
        return snap.isCharging ? "bolt.fill" : "bolt.slash"
    }

    private var statusColor: Color {
        guard snap.externalConnected else { return .secondary }
        if snap.isCharging { return speed.color }
        return .orange
    }

    private var statGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
            GridRow {
                stat("Power", value: snap.livePower.map { String(format: "%.1f W", $0) } ?? "—", color: speed.color)
                stat("Voltage", value: snap.liveVoltage.map { String(format: "%.2f V", $0) } ?? "—")
            }
            GridRow {
                stat("Current", value: snap.liveCurrent.map { String(format: "%.2f A", $0) } ?? "—")
                stat("Efficiency loss", value: snap.efficiencyLossW.map { String(format: "%.2f W", $0) } ?? "—")
            }
        }
    }

    private func stat(_ label: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .rounded).monospacedDigit())
                .foregroundStyle(color)
        }
    }

    private var sparkline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Live power")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Chart(Array(store.history.enumerated()), id: \.offset) { _, point in
                if let power = point.livePower {
                    AreaMark(x: .value("Time", point.timestamp), y: .value("Watts", power))
                        .foregroundStyle(.linearGradient(colors: [statusColor.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Time", point.timestamp), y: .value("Watts", power))
                        .foregroundStyle(statusColor)
                        .interpolationMethod(.monotone)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3))
            }
            .frame(height: 70)
        }
    }

    private var batteryRow: some View {
        HStack {
            Image(systemName: batteryIcon)
                .foregroundStyle(batteryIconColor)
            Text("\(snap.batteryPercent)%")
                .font(.system(.body, design: .rounded).monospacedDigit())
            Spacer()
            Text(batteryStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var batteryIcon: String {
        switch snap.batteryPercent {
        case ..<13: return "battery.0percent"
        case ..<38: return "battery.25percent"
        case ..<63: return "battery.50percent"
        case ..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    private var batteryIconColor: Color {
        if snap.isLowPowerMode { return .yellow }
        if snap.batteryPercent <= 10 && !snap.isCharging { return .red }
        if snap.isCharging { return .green }
        return .primary
    }

    private var batteryStatusText: String {
        if snap.isCharging, let mins = snap.timeToFullMinutes {
            return "\(mins / 60)h \(mins % 60)m to full"
        }
        if !snap.isCharging, snap.externalConnected {
            return snap.batteryPercent >= 100 ? "Charged" : "Not charging"
        }
        if let mins = snap.timeToEmptyMinutes {
            return "\(mins / 60)h \(mins % 60)m remaining"
        }
        return "On battery"
    }
}
