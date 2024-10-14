// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [
        .iOS(.v16),
    ],
    products: XcodeSupport.products + [
        .library(name: "JetpackStatsWidgetsCore", targets: ["JetpackStatsWidgetsCore"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "WordPressFlux", targets: ["WordPressFlux"]),
        .library(name: "WordPressShared", targets: ["WordPressShared"]),
        .library(name: "WordPressUI", targets: ["WordPressUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios", from: "4.4.0"),
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.9.1"),
        .package(url: "https://github.com/Alamofire/AlamofireImage", from: "4.3.0"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.1.0"),
        .package(url: "https://github.com/Automattic/Automattic-Tracks-iOS", from: "3.4.2"),
        .package(url: "https://github.com/Automattic/AutomatticAbout-swift", from: "1.1.4"),
        .package(url: "https://github.com/Automattic/Gravatar-SDK-iOS", from: "2.1.0"),
        .package(url: "https://github.com/Automattic/Gridicons-iOS", branch: "develop"),
        .package(url: "https://github.com/Automattic/ScreenObject", from: "0.2.3"),
        .package(url: "https://github.com/Automattic/XCUITestHelpers", from: "0.4.0"),
        .package(url: "https://github.com/buildkite/test-collector-swift", from: "0.3.0"),
        .package(url: "https://github.com/ChartsOrg/Charts", from: "5.0.0"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", from: "3.8.5"),
        .package(url: "https://github.com/daltoniam/Starscream", from: "4.0.8"),
        .package(url: "https://github.com/erikdoe/ocmock", revision: "2c0bfd373289f4a7716db5d6db471640f91a6507"),
        .package(url: "https://github.com/johnxnguyen/Down", branch: "master"),
        .package(url: "https://github.com/kaishin/Gifu", from: "3.4.1"),
        .package(url: "https://github.com/patchthecode/JTAppleCalendar", from: "8.0.5"),
        .package(url: "https://github.com/Quick/Nimble", from: "10.0.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup", exact: "2.7.5"),
        .package(url: "https://github.com/squarefrog/UIDeviceIdentifier", from: "2.3.0"),
        .package(url: "https://github.com/SVProgressHUD/SVProgressHUD", from: "2.3.1"),
        .package(url: "https://github.com/tonymillion/Reachability", from: "3.7.5"),
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.19"),
        .package(url: "https://github.com/wordpress-mobile/FSInteractiveMap", from: "0.3.0"),
        .package(url: "https://github.com/wordpress-mobile/MediaEditor-iOS", branch: "task/spm-support"),
        .package(url: "https://github.com/wordpress-mobile/NSObject-SafeExpectations", from: "0.0.6"),
        .package(url: "https://github.com/wordpress-mobile/NSURL-IDN", branch: "trunk"),
        .package(url: "https://github.com/wordpress-mobile/WordPressKit-iOS", branch: "wpios-edition"),
        .package(url: "https://github.com/zendesk/support_sdk_ios", from: "8.0.3"),
        // We can't use wordpress-rs branches nor commits here. Only tags work.
        .package(url: "https://github.com/Automattic/wordpress-rs", revision: "alpha-swift-20240813"),
        .package(url: "https://github.com/wordpress-mobile/GutenbergKit", revision: "c31879b834ef3ca5ea6b09040c96093ef627e029"),
        .package(url: "https://github.com/Automattic/color-studio", branch: "trunk"),
    ],
    targets: XcodeSupport.targets + [
        .target(name: "JetpackStatsWidgetsCore"),
        .target(name: "DesignSystem"),
        .target(name: "UITestsFoundation", dependencies: [
            .product(name: "ScreenObject", package: "ScreenObject"),
            .product(name: "XCUITestHelpers", package: "XCUITestHelpers"),
        ]),
        .target(name: "WordPressFlux"),
        .target(name: "WordPressSharedObjC", resources: [.process("Resources")]),
        .target(name: "WordPressShared", dependencies: [.target(name: "WordPressSharedObjC")], resources: [.process("Resources")]),
        .target(name: "WordPressUI", resources: [.process("Resources")]),
        .testTarget(name: "JetpackStatsWidgetsCoreTests", dependencies: [.target(name: "JetpackStatsWidgetsCore")]),
        .testTarget(name: "DesignSystemTests", dependencies: [.target(name: "DesignSystem")]),
        .testTarget(name: "WordPressFluxTests", dependencies: ["WordPressFlux"]),
        .testTarget(name: "WordPressSharedTests", dependencies: [.target(name: "WordPressShared")]),
        .testTarget(name: "WordPressSharedObjCTests", dependencies: [.target(name: "WordPressShared")], resources: [.process("Resources")]),
        .testTarget(name: "WordPressUITests", dependencies: [.target(name: "WordPressUI")]),
    ]
)

// MARK: - XcodeSupport (Xcode Targets)

/// The following section specifies dependencies for the respective Xcode targets.
/// You can add internal or third-party dependencies to these targets or even
/// source files and resources.
///
/// - note: SwiftPM automatically detects which modules are shared between
/// multiple targets and decides when to use dynamic frameworks.
///
/// ## Known Issues
///
///   - SwiftPM copies resource bundles from a target, including dynamic frameworks,
/// into every target that depends on it. Make sure to avoid including frameworks
/// with large resources bundled into multiple targets.
enum XcodeSupport {
    static let products: [Product] = [
        .library(name: "XcodeTarget_App", targets: ["XcodeTarget_App"]),
        .library(name: "XcodeTarget_WordPressTests", targets: ["XcodeTarget_WordPressTests"]),
        .library(name: "XcodeTarget_WordPressAuthentificator", targets: ["XcodeTarget_WordPressAuthentificator"]),
        .library(name: "XcodeTarget_WordPressAuthentificatorTests", targets: ["XcodeTarget_WordPressAuthentificatorTests"]),
        .library(name: "XcodeTarget_ShareExtension", targets: ["XcodeTarget_ShareExtension"]),
        .library(name: "XcodeTarget_DraftActionExtension", targets: ["XcodeTarget_DraftActionExtension"]),
        .library(name: "XcodeTarget_NotificationServiceExtension", targets: ["XcodeTarget_NotificationServiceExtension"]),
        .library(name: "XcodeTarget_Intents", targets: ["XcodeTarget_Intents"]),
        .library(name: "XcodeTarget_StatsWidget", targets: ["XcodeTarget_StatsWidget"]),
        .library(name: "XcodeTarget_UITests", targets: ["XcodeTarget_UITests"]),
    ]

    static let targets: [Target] = {
        let wordPresAuthentificatorDependencies: [Target.Dependency] = [
            "WordPressShared",
            "WordPressUI",
            .product(name: "Gridicons", package: "Gridicons-iOS"),
            .product(name: "NSURL+IDN", package: "NSURL-IDN"),
            .product(name: "SVProgressHUD", package: "SVProgressHUD"),
            .product(name: "WordPressKit", package: "WordPressKit-iOS"),
            .product(name: "Gravatar", package: "Gravatar-SDK-iOS"),
            .product(name: "GravatarUI", package: "Gravatar-SDK-iOS"),
        ]

        let shareAndDraftExtensionsDependencies: [Target.Dependency] = [
            "WordPressShared",
            "WordPressUI",
            .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
            .product(name: "Down", package: "Down"),
            .product(name: "Gridicons", package: "Gridicons-iOS"),
            .product(name: "Reachability", package: "Reachability"),
            .product(name: "SVProgressHUD", package: "SVProgressHUD"),
            .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            .product(name: "ColorStudio", package: "color-studio"),
        ]

        let testDependencies: [Target.Dependency] = [
            .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
            .product(name: "OCMock", package: "OCMock"),
        ]

        return [
            .xcodeTarget("XcodeTarget_App", dependencies: [
                "DesignSystem",
                "JetpackStatsWidgetsCore",
                "WordPressFlux",
                "WordPressShared",
                "WordPressUI",
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "AlamofireImage", package: "AlamofireImage"),
                .product(name: "AutomatticAbout", package: "AutomatticAbout-swift"),
                .product(name: "AutomatticTracks", package: "Automattic-Tracks-iOS"),
                .product(name: "CocoaLumberjack", package: "CocoaLumberjack"),
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                .product(name: "DGCharts", package: "Charts"),
                .product(name: "Down", package: "Down"),
                .product(name: "FSInteractiveMap", package: "FSInteractiveMap"),
                .product(name: "Gifu", package: "Gifu"),
                .product(name: "Gravatar", package: "Gravatar-SDK-iOS"),
                .product(name: "GravatarUI", package: "Gravatar-SDK-iOS"),
                .product(name: "Gridicons", package: "Gridicons-iOS"),
                .product(name: "GutenbergKit", package: "GutenbergKit"),
                .product(name: "JTAppleCalendar", package: "JTAppleCalendar"),
                .product(name: "Lottie", package: "lottie-ios"),
                .product(name: "MediaEditor", package: "MediaEditor-iOS"),
                .product(name: "NSObject-SafeExpectations", package: "NSObject-SafeExpectations"),
                .product(name: "Reachability", package: "Reachability"),
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "SVProgressHUD", package: "SVProgressHUD"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "UIDeviceIdentifier", package: "UIDeviceIdentifier"),
                .product(name: "WordPressKit", package: "WordPressKit-iOS"),
                .product(name: "ZendeskSupportSDK", package: "support_sdk_ios"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "WordPressAPI", package: "wordpress-rs"),
                .product(name: "ColorStudio", package: "color-studio"),
            ]),
            .xcodeTarget("XcodeTarget_WordPressTests", dependencies: testDependencies + [
                "WordPressShared",
                .product(name: "Gravatar", package: "Gravatar-SDK-iOS"),
                .product(name: "Nimble", package: "Nimble"),
                .product(name: "BuildkiteTestCollector", package: "test-collector-swift"),
            ]),
            .xcodeTarget("XcodeTarget_WordPressAuthentificator", dependencies: wordPresAuthentificatorDependencies),
            .xcodeTarget("XcodeTarget_WordPressAuthentificatorTests", dependencies: wordPresAuthentificatorDependencies + testDependencies),
            .xcodeTarget("XcodeTarget_ShareExtension", dependencies: shareAndDraftExtensionsDependencies),
            .xcodeTarget("XcodeTarget_DraftActionExtension", dependencies: shareAndDraftExtensionsDependencies),
            .xcodeTarget("XcodeTarget_NotificationServiceExtension", dependencies: [
                "WordPressUI",
                "WordPressShared",
            ]),
            .xcodeTarget("XcodeTarget_StatsWidget", dependencies: [
                "JetpackStatsWidgetsCore",
                "WordPressShared",
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                .product(name: "WordPressAPI", package: "wordpress-rs"),
                .product(name: "ColorStudio", package: "color-studio"),
            ]),
            .xcodeTarget("XcodeTarget_Intents", dependencies: [
                "JetpackStatsWidgetsCore",
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
            ]),
            .xcodeTarget("XcodeTarget_UITests", dependencies: [
                "UITestsFoundation",
                .product(name: "BuildkiteTestCollector", package: "test-collector-swift"),
            ]),
        ]
    }()
}

extension Target {
    static func xcodeTarget(_ name: String, dependencies: [Dependency]) -> Target {
        .target(name: name, dependencies: dependencies, path: "Sources/XcodeSupport/\(name)")
    }
}
