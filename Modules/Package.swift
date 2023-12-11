// swift-tools-version: 5.8

import PackageDescription

let jetpackStatsWidgetsCoreName = "JetpackStatsWidgetsCore"

let package = Package(
    name: jetpackStatsWidgetsCoreName,
    products: [
        .library(name: jetpackStatsWidgetsCoreName, targets: [jetpackStatsWidgetsCoreName]),
    ],
    targets: [
        .target(name: jetpackStatsWidgetsCoreName),
        .testTarget(
            name: "\(jetpackStatsWidgetsCoreName)Tests",
            dependencies: [.target(name: jetpackStatsWidgetsCoreName)]
        )
    ]
)
