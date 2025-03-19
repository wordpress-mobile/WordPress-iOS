import Foundation

/// The container for Xcode previews.
extension BuildSettings {
    nonisolated(unsafe) static var preview = BuildSettings(
        brand: .jetpack,
        pushNotificationAppID: "xcpreview_push_notification_id",
        appGroupName: "xcpreview_app_group_name",
        appKeychainAccessGroup: "xcpreview_app_keychain_access_group",
        eventNamePrefix: "xcpreview",
        explatPlatform: "xcpreview",
        itunesAppID: "1234567890"
    )
}

extension BuildSettings {
    /// Updates the preview settings for the lifetime of the given closure.
    /// Reverts to the original settings when done.
    @MainActor
    public static func withSettings<T>(_ configure: (inout BuildSettings) -> Void, perform closure: () -> T) -> T {
        var container = BuildSettings.preview
        let original = container
        configure(&container)
        BuildSettings.preview = container
        let value = closure()
        BuildSettings.preview = original
        return value
    }
}
