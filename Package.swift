// swift-tools-version: 6.2

import PackageDescription

let concurrencySettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency"),
    .enableUpcomingFeature("ExistentialAny"),
    .defaultIsolation(MainActor.self),
]

let package = Package(
    name: "DaemonOS",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "DaemonOS", targets: ["DaemonOS"]),
        .executable(name: "daemon", targets: ["daemon"]),
    ],
    dependencies: [
        .package(url: "https://github.com/steipete/AXorcist.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "DaemonOS",
            dependencies: [
                .product(name: "AXorcist", package: "AXorcist"),
            ],
            path: "Sources/DaemonOS",
            swiftSettings: concurrencySettings,
            linkerSettings: [.linkedFramework("ScreenCaptureKit")]
        ),
        .executableTarget(
            name: "daemon",
            dependencies: ["DaemonOS"],
            path: "Sources/daemon",
            swiftSettings: concurrencySettings
        ),
        .testTarget(
            name: "DaemonOSTests",
            dependencies: ["DaemonOS"],
            path: "Tests/DaemonOSTests",
            swiftSettings: concurrencySettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
