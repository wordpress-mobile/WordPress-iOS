// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "WordPressFlux",
    products: [
        .library(
            name: "WordPressFlux",
            targets: ["WordPressFlux"]
        ),
    ],
    dependencies: [
        .package(name: "BuildkiteTestCollector", url: "https://github.com/buildkite/test-collector-swift", from: "0.1.1"),
    ],
    targets: [
        .target(
            name: "WordPressFlux",
            dependencies: []
        ),
        .testTarget(
            name: "WordPressFluxTests",
            dependencies: ["WordPressFlux", "BuildkiteTestCollector"]
        ),
    ]
)
