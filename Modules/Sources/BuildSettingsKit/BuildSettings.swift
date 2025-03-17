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
    public var pushNotificationAppID: String
    public var appGroupName: String
    public var appKeychainAccessGroup: String

    public static var current: BuildSettings {
        switch BuildSettingsEnvironment.current {
        case .live: .live
        case .preview: .preview
        }
    }
}
