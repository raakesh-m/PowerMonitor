import Foundation
import IOKit
import IOKit.ps

/// A single point-in-time reading of charging/power state.
struct PowerSnapshot: Equatable {
    var timestamp = Date()

    var externalConnected = false
    var isCharging = false
    var batteryPercent = 0
    var timeToFullMinutes: Int?
    var timeToEmptyMinutes: Int?

    var adapterName: String?
    var adapterManufacturer: String?
    var adapterDescription: String?      // e.g. "usb brick", "pd charger"
    var adapterSerial: String?
    var ratedWatts: Double?
    var ratedVoltage: Double?            // V
    var ratedCurrent: Double?            // A

    var liveVoltage: Double?             // V
    var liveCurrent: Double?             // A
    var livePower: Double?               // W
    var batteryPowerW: Double?           // + charging into battery, - discharging
    var efficiencyLossW: Double?
    var isLowPowerMode = false

    var displayName: String {
        adapterName ?? adapterDescription?.capitalized ?? "No Adapter"
    }
}

/// Reads live charger/battery telemetry from IOKit.
///
/// Battery percentage/charging/time-remaining come from the public
/// IOPowerSources API. Adapter identity and live wattage come from the
/// AppleSmartBattery IORegistry entry — undocumented but the only place
/// macOS exposes per-charger voltage/current/wattage telemetry.
enum PowerReader {
    static func read() -> PowerSnapshot {
        var snap = PowerSnapshot()
        snap.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

        if let info = publicPowerSourceInfo() {
            snap.batteryPercent = info.percent
            snap.isCharging = info.isCharging
            snap.timeToFullMinutes = info.timeToFull
            snap.timeToEmptyMinutes = info.timeToEmpty
        }

        guard let props = smartBatteryProperties() else { return snap }

        snap.externalConnected = (props["ExternalConnected"] as? Bool) ?? snap.externalConnected
        if let charging = props["IsCharging"] as? Bool {
            snap.isCharging = charging
        }

        if let adapter = props["AdapterDetails"] as? [String: Any] {
            snap.adapterName = adapter["Name"] as? String
            snap.adapterManufacturer = adapter["Manufacturer"] as? String
            snap.adapterDescription = adapter["Description"] as? String
            snap.adapterSerial = adapter["SerialString"] as? String
            snap.ratedWatts = (adapter["Watts"] as? NSNumber)?.doubleValue
            if let mv = (adapter["AdapterVoltage"] as? NSNumber)?.doubleValue {
                snap.ratedVoltage = mv / 1000.0
            }
            if let ma = (adapter["Current"] as? NSNumber)?.doubleValue {
                snap.ratedCurrent = ma / 1000.0
            }
        }

        if let telemetry = props["PowerTelemetryData"] as? [String: Any] {
            snap.liveVoltage = signedMilliUnits(telemetry["SystemVoltageIn"])
            snap.liveCurrent = signedMilliUnits(telemetry["SystemCurrentIn"])
            snap.livePower = signedMilliUnits(telemetry["SystemPowerIn"])
            snap.batteryPowerW = signedMilliUnits(telemetry["BatteryPower"])
            snap.efficiencyLossW = signedMilliUnits(telemetry["AdapterEfficiencyLoss"])
        }

        return snap
    }

    // MARK: - Public IOPowerSources API (battery %, charging, time remaining)

    private static func publicPowerSourceInfo() -> (percent: Int, isCharging: Bool, timeToFull: Int?, timeToEmpty: Int?)? {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
        guard let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef], let source = list.first else { return nil }
        guard let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] else { return nil }

        let percent = description[kIOPSCurrentCapacityKey] as? Int ?? 0
        let charging = description[kIOPSIsChargingKey] as? Bool ?? false
        let toFull = description[kIOPSTimeToFullChargeKey] as? Int
        let toEmpty = description[kIOPSTimeToEmptyKey] as? Int
        return (percent, charging, (toFull ?? -1) >= 0 ? toFull : nil, (toEmpty ?? -1) >= 0 ? toEmpty : nil)
    }

    // MARK: - Private AppleSmartBattery IORegistry entry

    private static func smartBatteryProperties() -> [String: Any]? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        var propsUnmanaged: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(service, &propsUnmanaged, kCFAllocatorDefault, 0)
        guard result == KERN_SUCCESS, let dict = propsUnmanaged?.takeRetainedValue() as? [String: Any] else { return nil }
        return dict
    }

    /// IOKit reports some signed telemetry values (e.g. battery power while
    /// discharging) as huge unsigned integers wrapping around zero. Reinterpret
    /// the bit pattern as signed before converting milli-units to base units.
    private static func signedMilliUnits(_ any: Any?) -> Double? {
        guard let number = any as? NSNumber else { return nil }
        let signed = Int64(bitPattern: number.uint64Value)
        return Double(signed) / 1000.0
    }
}
