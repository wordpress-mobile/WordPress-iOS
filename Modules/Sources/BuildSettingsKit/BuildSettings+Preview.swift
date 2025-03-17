import Foundation

/// The container for Xcode previews.
public struct BuildSettingsPreviewContainer: BuildSettingsContainer {
    public var pushNotificationAppID = "xcpreview_push_notification_id"
    public var appGroupName = "xcpreview_app_group_name"
    public var appKeychainAccessGroup = "xcpreview_app_keychain_access_group"

    nonisolated(unsafe) static var shared = BuildSettingsPreviewContainer()
}

extension BuildSettings {
    /// Updates the preview settings for the lifetime of the given closure.
    /// Reverts to the original settings when done.
    @MainActor
    public static func withSettings<T>(_ configure: (inout BuildSettingsPreviewContainer) -> Void, perform closure: () -> T) -> T {
        var container = BuildSettingsPreviewContainer.shared
        let original = container
        configure(&container)
        BuildSettingsPreviewContainer.shared = container
        let value = closure()
        BuildSettingsPreviewContainer.shared = original
        return value
    }
}
