// swift-tools-version: 5.9

import PackageDescription

let librarySourceName = "JetpackStatsWidgetsCore"

let package = Package(
    name: librarySourceName,
    products: [
        .library(name: librarySourceName, targets: [librarySourceName]),
    ],
    targets: [
        .target(name: librarySourceName),
        .testTarget(
            name: "\(librarySourceName)Tests",
            dependencies: [.target(name: librarySourceName)]
        )
    ]
)
