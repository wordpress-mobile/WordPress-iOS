// swift-tools-version: 6.0

/// A cross-platform subset of the WordPress iOS modules.
///
/// Depends on the `Modules` package and references its products, so target/dependency definitions live in one place.

import PackageDescription

let package = Package(
    name: "WordPressCrossPlatformModules",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    dependencies: [
        .package(path: "Modules")
    ],
    targets: [
        .testTarget(
            name: "JetpackStatsWidgetsCoreTests",
            dependencies: [.product(name: "JetpackStatsWidgetsCore", package: "Modules")],
            path: "Modules/Tests/JetpackStatsWidgetsCoreTests",
            exclude: ["SiteEntityQueryTests.swift"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "WordPressFluxTests",
            dependencies: [.product(name: "WordPressFlux", package: "Modules")],
            path: "Modules/Tests/WordPressFluxTests",
            exclude: ["WordPressFluxTests.xctestplan"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "WordPressCoreTests",
            dependencies: [.product(name: "WordPressCore", package: "Modules")],
            path: "Modules/Tests/WordPressCoreTests",
            exclude: ["WordPressCore.xctestplan"]
        ),
        .testTarget(
            name: "WordPressSharedTests",
            dependencies: [.product(name: "WordPressShared", package: "Modules")],
            path: "Modules/Tests/WordPressSharedTests",
            exclude: [
                "WordPressShared.xctestplan",
                "RichContentFormatterTests.swift",
                "WPUserAgentTests.swift"
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // The image/video upload transform engine. A leaf module (system
        // frameworks only), so `swift test` here exercises it on the macOS host
        // — no Xcode, no simulator, no wordpress-rs.
        .testTarget(
            name: "MediaTransformerTests",
            dependencies: [.product(name: "MediaTransformer", package: "Modules")],
            path: "Modules/Tests/MediaTransformerTests",
            resources: [.process("Resources")]
        )
    ]
)
