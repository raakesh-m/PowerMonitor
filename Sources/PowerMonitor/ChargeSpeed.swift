import SwiftUI

/// Classifies live charging wattage into a speed tier so the UI can
/// color-code slow/standard/fast MacBook charging at a glance.
enum ChargeSpeed: Equatable {
    case none
    case trickle   // weak/USB bricks, <20W
    case standard  // typical 20-45W adapters
    case fast      // 45-80W (most MacBook Pro chargers)
    case maxFast   // 80W+ (96/140W fast-charge bricks, at/near adapter max)

    static func classify(watts: Double?) -> ChargeSpeed {
        guard let w = watts, w > 0.5 else { return .none }
        switch w {
        case ..<20: return .trickle
        case ..<45: return .standard
        case ..<80: return .fast
        default: return .maxFast
        }
    }

    var color: Color {
        switch self {
        case .none: return .secondary
        case .trickle: return .red
        case .standard: return .orange
        case .fast: return .teal
        case .maxFast: return .green
        }
    }

    var label: String {
        switch self {
        case .none: return "Not charging"
        case .trickle: return "Slow charging"
        case .standard: return "Charging"
        case .fast: return "Fast charging"
        case .maxFast: return "Max-speed charging"
        }
    }

    /// Whether this tier is worth a subtle pulse to draw the eye.
    var animates: Bool { self == .fast || self == .maxFast }
}
