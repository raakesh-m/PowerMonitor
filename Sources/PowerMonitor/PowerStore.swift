import Foundation
import Combine

@MainActor
final class PowerStore: ObservableObject {
    @Published private(set) var current = PowerSnapshot()
    @Published private(set) var history: [PowerSnapshot] = []

    private let maxHistory = 90 // ~3 minutes at 2s polling
    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        let snap = PowerReader.read()
        current = snap
        history.append(snap)
        if history.count > maxHistory {
            history.removeFirst(history.count - maxHistory)
        }
    }

    deinit {
        timer?.invalidate()
    }
}
