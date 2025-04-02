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

        init(twitterHandle: String, twitterURL: URL, blogURL: URL) {
            self.twitterHandle = twitterHandle
            self.twitterURL = twitterURL
            self.blogURL = blogURL
        }
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

    init(
        configuration: BuildConfiguration,
        brand: AppBrand,
        pushNotificationAppID: String,
        appGroupName: String,
        appKeychainAccessGroup: String,
        eventNamePrefix: String,
        explatPlatform: String,
        itunesAppID: String,
        appURLScheme: String,
        jetpackAppURLScheme: String,
        about: ProductAboutDetails,
        zendeskSourcePlatform: String,
        mobileAnnounceAppID: String,
        authKeychainServiceName: String
    ) {
        self.configuration = configuration
        self.brand = brand
        self.pushNotificationAppID = pushNotificationAppID
        self.appGroupName = appGroupName
        self.appKeychainAccessGroup = appKeychainAccessGroup
        self.eventNamePrefix = eventNamePrefix
        self.explatPlatform = explatPlatform
        self.itunesAppID = itunesAppID
        self.appURLScheme = appURLScheme
        self.jetpackAppURLScheme = jetpackAppURLScheme
        self.about = about
        self.zendeskSourcePlatform = zendeskSourcePlatform
        self.mobileAnnounceAppID = mobileAnnounceAppID
        self.authKeychainServiceName = authKeychainServiceName
    }
}

public enum AppBrand: String, Sendable {
    case wordpress
    case jetpack
}
