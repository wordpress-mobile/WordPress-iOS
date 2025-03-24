import Foundation

/// Manages global build settings.
///
/// The build settings work differently depending on the environment:
///
/// - **Live** – the code runs as part of an app or app extensions with build
/// settings configured using the `Info.plist` file.
/// - **Preview** – the code runs as part of the SwiftPM or Xcode target. In this
/// environment, the build settings have predefined values that can also be
/// changed at runtime.
/// - **Test** – `BuildSettings` are not available when running unit tests as
/// they are incompatible with parallelized tests and are generally not recommended.
public struct BuildSettings: Sendable {
    public var configuration: BuildConfiguration
    public var brand: AppBrand
    public var pushNotificationAppID: String
    public var appGroupName: String
    public var appKeychainAccessGroup: String
    public var eventNamePrefix: String
    public var explatPlatform: String
    public var itunesAppID: String
    public var appURLScheme: String
    public var jetpackAppURLScheme: String
    public var about: ProductAboutDetails
    public var zendeskSourcePlatform: String
    public var mobileAnnounceAppID: String
    public var authKeychainServiceName: String

    public struct ProductAboutDetails: Sendable {
        public var twitterHandle: String
        public var twitterURL: URL
        public var blogURL: URL
    }

    public static var current: BuildSettings {
        switch BuildSettingsEnvironment.current {
        case .live:
            return .live
        case .preview:
            return .preview
        case .test:
            // TODO: update tests to ensure none of the rely on `BuildSettings` availability as it's incompatible with parallelized tests
            return .live
        }
    }
}

public enum AppBrand: String, Sendable {
    case wordpress
    case jetpack
}
