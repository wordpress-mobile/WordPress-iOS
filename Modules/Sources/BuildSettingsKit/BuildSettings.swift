import Foundation

public protocol BuildSettingsContainer: Sendable {
    var pushNotificationAppID: String { get }
    var appGroupName: String { get }
    var appKeychainAccessGroup: String { get }
}

public enum AppBrand: String, Sendable {
    case wordpress
    case jetpack
}

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
public enum BuildSettings {
    public static var current: BuildSettingsContainer {
        switch BuildSettingsEnvironment.current {
        case .live: BuildSettingsLiveContainer.shared
        case .preview: BuildSettingsPreviewContainer.shared
        }
    }
}

private enum BuildSettingsEnvironment {
    case live
    case preview

    static let current: BuildSettingsEnvironment = {
#if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return .preview
        }
        if NSClassFromString("XCTestCase") != nil {
            fatalError("BuildSettings are unavailable when running unit tests. Make sure to inject the values manually in system under test.")
        }
#endif
        return .live
    }()
}
