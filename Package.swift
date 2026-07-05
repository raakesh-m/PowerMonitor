// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PowerMonitor",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PowerMonitor",
            path: "Sources/PowerMonitor"
        )
    ]
)
