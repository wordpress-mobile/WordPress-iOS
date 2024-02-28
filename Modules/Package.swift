// swift-tools-version: 5.8

import PackageDescription

let jetpackStatsWidgetsCoreName = "JetpackStatsWidgetsCore"
let designSystemName = "DesignSystem"

let package = Package(
    name: "Modules",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: jetpackStatsWidgetsCoreName, targets: [jetpackStatsWidgetsCoreName]),
        .library(name: designSystemName, targets: [designSystemName]),
    ],
    targets: [
        .target(name: jetpackStatsWidgetsCoreName),
        .testTarget(
            name: "\(jetpackStatsWidgetsCoreName)Tests",
            dependencies: [.target(name: jetpackStatsWidgetsCoreName)]
        ),
        .testTarget(
            name: "\(designSystemName)Tests",
            dependencies: [.target(name: designSystemName)]
        ),
        .target(name: designSystemName)
    ]
)
