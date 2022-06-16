// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "WordPressFlux",
    products: [
        .library(
            name: "WordPressFlux",
            targets: ["WordPressFlux"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WordPressFlux",
            dependencies: []
        ),
        .testTarget(
            name: "WordPressFluxTests",
            dependencies: ["WordPressFlux"]
        ),
    ]
)
