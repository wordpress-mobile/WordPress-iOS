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
