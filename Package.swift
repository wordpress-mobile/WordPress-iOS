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
    ]
)
