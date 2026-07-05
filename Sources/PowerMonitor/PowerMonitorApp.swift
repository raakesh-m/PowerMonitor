import SwiftUI

@main
struct PowerMonitorApp: App {
    @StateObject private var store = PowerStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(store)
        } label: {
            MenuBarLabel(snapshot: store.current)
        }
        .menuBarExtraStyle(.window)
    }
}
