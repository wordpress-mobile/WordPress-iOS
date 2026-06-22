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
    // Secrets are configured at runtime for security necessity.
    //
    // To avoid unwrapping values that have to be present for the app to work, the value is an
    // implicitly unwrapped optional.
    //
    // Call `BuildSettings.configure(secrets:)` as soon as possible in the consumer app life cycle
    // to avoid crashes.
    public internal(set) var secrets: BuildSecrets!
    public var brand: AppBrand
    public var pushNotificationAppID: String
    public var appGroupName: String
    public var appKeychainAccessGroup: String
    /// The legacy cross-app keychain group shared by the WordPress and
    /// Jetpack apps. nil where the app has no shared-group entitlement
    /// (Reader): the key is simply absent from that app's Info.plist.
    public var sharedKeychainAccessGroup: String?
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
        public var blogURL: URL
    }

    public static var current: BuildSettings {
        switch BuildSettingsEnvironment.current {
        case .live:
            return .live
        case .preview:
            return .preview
        case .test:
            // App-hosted test targets (e.g. Keystone) carry the app Info.plist and can use
            // `.live`. SPM module test hosts (e.g. WordPressDataTests) don't, so fall back to
            // `.preview` to keep `BuildSettings.current` (and `AppKeychain()`) from crashing.
            return liveIfHostBundleAvailable ?? .preview
        }
    }
}

public enum AppBrand: String, Sendable {
    case wordpress
    case jetpack
    case reader
}
