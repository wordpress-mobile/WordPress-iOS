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
        .iOS(.v17),
    ],
    dependencies: [
        .package(url: "https://github.com/wordpress-mobile/NSObject-SafeExpectations", from: "0.0.6"),
        .package(url: "https://github.com/wordpress-mobile/wpxmlrpc", from: "0.9.0"),
        .package(url: "https://github.com/Automattic/wordpress-rs", revision: "alpha-20260226"),
        .package(url: "https://github.com/Automattic/Reachability", branch: "framework-support-via-spm"),
    ],
    targets: [
        .target(name: "BuildSettingsKit", path: "Modules/Sources/BuildSettingsKit"),
        .target(
            name: "JetpackStatsWidgetsCore",
            path: "Modules/Sources/JetpackStatsWidgetsCore",
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
            name: "WordPressKitObjCUtils",
            path: "Modules/Sources/WordPressKitObjCUtils",
            cSettings: [
                .define("NS_BLOCK_ASSERTIONS", to: "1", .when(configuration: .release))
            ]
        ),
        .target(
            name: "WordPressKitModels",
            dependencies: [
                "NSObject-SafeExpectations",
                "WordPressKitObjCUtils",
            ],
            path: "Modules/Sources/WordPressKitModels"
        ),
        .target(
            name: "WordPressKitObjC",
            dependencies: [
                "NSObject-SafeExpectations",
                "wpxmlrpc",
                "WordPressKitModels",
                "WordPressKitObjCUtils",
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
                .product(name: "Reachability", package: "Reachability"),
                "SFHFKeychainUtils",
                "WordPressSharedObjC",
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
                "WordPressKitObjCUtils",
                "NSObject-SafeExpectations",
                "WordPressShared",
                "wpxmlrpc",
            ],
            path: "Modules/Sources/WordPressKit",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "WordPressCore",
            dependencies: [
                "WordPressCoreProtocols",
                "WordPressShared",
                .product(name: "WordPressAPI", package: "wordpress-rs"),
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
                "WPUserAgentTests.swift",
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
