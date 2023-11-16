// swift-tools-version: 5.8

import PackageDescription

let jetpackStatsWidgetsCoreLibName = "JetpackStatsWidgetsCore"

let package = Package(
    name: "Modules",
    products: [
        .library(name: jetpackStatsWidgetsCoreLibName, targets: [jetpackStatsWidgetsCoreLibName]),
    ],
    targets: [
        .target(
            name: jetpackStatsWidgetsCoreLibName,
            path: "\(jetpackStatsWidgetsCoreLibName)/Sources"
        ),
        .testTarget(
            name: "\(jetpackStatsWidgetsCoreLibName)Tests",
            dependencies: [.target(name: jetpackStatsWidgetsCoreLibName)],
            path: "\(jetpackStatsWidgetsCoreLibName)/Tests"
        )
    ]
)
