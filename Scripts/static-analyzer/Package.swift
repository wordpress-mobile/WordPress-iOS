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
        .package(url: "https://github.com/apple/indexstore-db", revision: "swift-5.8-RELEASE"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", .upToNextMinor(from: "0.34.1")),
        .package(url: "https://github.com/apple/swift-tools-support-core.git", from: "0.5.2"),
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
                .product(name: "TSCBasic", package: "swift-tools-support-core"),
                "Analyzer",
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .target(
            name: "Analyzer",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "IndexStoreDB", package: "indexstore-db"),
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "TSCBasic", package: "swift-tools-support-core"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "AnalyzerTests",
            dependencies: [
                "Analyzer"
            ],
            resources: [.copy("TestData")]
        )
    ]
)
