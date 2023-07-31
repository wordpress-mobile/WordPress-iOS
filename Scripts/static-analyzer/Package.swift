// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "static-analyzer",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "static-analyzer",
            targets: ["static-analyzer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "508.0.0"),
        .package(url: "https://github.com/apple/indexstore-db", branch: "release/5.8"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", .upToNextMinor(from: "0.34.1")),
    ],
    targets: [
        .executableTarget(
            name: "static-analyzer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "IndexStoreDB", package: "indexstore-db"),
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        )
    ]
)
