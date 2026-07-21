// swift-tools-version: 6.0

/// A cross-platform subset of the WordPress iOS modules.
///
/// Modules listed here must build and test on macOS. As modules are made cross-platform, add them here so they
/// can be tested with `swift test` from the repository root.

import PackageDescription

let package = Package(
    name: "WordPressCrossPlatformModules",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.2"),
        .package(url: "https://github.com/scinfu/SwiftSoup", exact: "2.7.5"),
        .package(url: "https://github.com/wordpress-mobile/NSObject-SafeExpectations", from: "0.0.6"),
        .package(url: "https://github.com/wordpress-mobile/wpxmlrpc", from: "0.9.0"),
        .package(url: "https://github.com/Automattic/wordpress-rs", exact: "0.6.0")
    ],
    targets: [
        .target(name: "BuildSettingsKit", path: "Modules/Sources/BuildSettingsKit"),
        .target(
            name: "JetpackStatsWidgetsCore",
            path: "Modules/Sources/JetpackStatsWidgetsCore",
            // The AppIntents widget-configuration code (SelectSiteIntent/SiteEntity) is
            // iOS-only and does not compile for macOS; exclude it from the cross-platform build.
            exclude: ["AppIntents"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "NotificationServiceExtensionCore",
            dependencies: ["BuildSettingsKit"],
            path: "Modules/Sources/NotificationServiceExtensionCore"
        ),
        .target(
            name: "SFHFKeychainUtils",
            path: "Modules/Sources/SFHFKeychainUtils",
            cSettings: [.unsafeFlags(["-fno-objc-arc"])]
        ),
        .target(name: "TextBundle", path: "Modules/Sources/TextBundle"),
        .target(name: "WordPressCoreProtocols", path: "Modules/Sources/WordPressCoreProtocols"),
        .target(
            name: "WordPressKitModels",
            dependencies: [
                "NSObject-SafeExpectations",
                "WordPressShared"
            ],
            path: "Modules/Sources/WordPressKitModels"
        ),
        .target(
            name: "WordPressKitObjC",
            dependencies: [
                "NSObject-SafeExpectations",
                "wpxmlrpc",
                "WordPressShared",
                "WordPressKitModels"
            ],
            path: "Modules/Sources/WordPressKitObjC",
            publicHeadersPath: "include",
            cSettings: [
                .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release))
            ]
        ),
        .target(
            name: "WordPressSharedObjC",
            path: "Modules/Sources/WordPressSharedObjC",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "WordPressShared",
            dependencies: [
                "BuildSettingsKit",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                "SFHFKeychainUtils",
                "WordPressSharedObjC"
            ],
            path: "Modules/Sources/WordPressShared",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "WordPressKit",
            dependencies: [
                "WordPressKitObjC",
                "WordPressKitModels",
                "NSObject-SafeExpectations",
                "WordPressShared",
                "wpxmlrpc"
            ],
            path: "Modules/Sources/WordPressKit",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "WordPressCore",
            dependencies: [
                "WordPressCoreProtocols",
                "WordPressShared",
                .product(name: "WordPressAPI", package: "wordpress-rs")
            ],
            path: "Modules/Sources/WordPressCore"
        ),
        .target(
            name: "WordPressTesting",
            path: "Modules/Sources/WordPressTesting",
            resources: [.process("Resources")]
        ),
        .target(
            name: "WordPressFlux",
            path: "Modules/Sources/WordPressFlux",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "JetpackStatsWidgetsCoreTests",
            dependencies: ["JetpackStatsWidgetsCore"],
            path: "Modules/Tests/JetpackStatsWidgetsCoreTests",
            // Tests the AppIntents SiteEntityQuery, which is excluded from the cross-platform build.
            exclude: ["SiteEntityQueryTests.swift"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "WordPressFluxTests",
            dependencies: ["WordPressFlux"],
            path: "Modules/Tests/WordPressFluxTests",
            exclude: ["WordPressFluxTests.xctestplan"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "WordPressCoreTests",
            dependencies: ["WordPressCore"],
            path: "Modules/Tests/WordPressCoreTests",
            exclude: ["WordPressCore.xctestplan"]
        ),
        .testTarget(
            name: "WordPressSharedTests",
            dependencies: ["WordPressShared"],
            path: "Modules/Tests/WordPressSharedTests",
            exclude: [
                "WordPressShared.xctestplan",
                "RichContentFormatterTests.swift",
                "WPUserAgentTests.swift"
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
