// WordPress Extension configuration

import Foundation

/// - Warning:
/// This configuration extension has a **Jetpack** counterpart in the Jetpack bundle.
/// Make sure to keep them in sync to avoid build errors when builing the Jetpack target.
@objc extension AppConfiguration {

    @objc(AppConfigurationExtension)
    class Extension: NSObject {
        @objc(AppConfigurationExtensionShare)
        class Share: NSObject {
            @objc static let keychainUsernameKey = "Username"
            @objc static let keychainTokenKey = "OAuth2Token"
            @objc static let keychainServiceName = "ShareExtension"
            @objc static let userDefaultsPrimarySiteName = "WPShareUserDefaultsPrimarySiteName"
            @objc static let userDefaultsPrimarySiteID = "WPShareUserDefaultsPrimarySiteID"
            @objc static let userDefaultsLastUsedSiteName = "WPShareUserDefaultsLastUsedSiteName"
            @objc static let userDefaultsLastUsedSiteID = "WPShareUserDefaultsLastUsedSiteID"
            @objc static let maximumMediaDimensionKey = "WPShareExtensionMaximumMediaDimensionKey"
            @objc static let recentSitesKey = "WPShareExtensionRecentSitesKey"
        }

        @objc(AppConfigurationExtensionNotificationsService)
        class NotificationsService: NSObject {
            @objc static let keychainServiceName = "NotificationServiceExtension"
            @objc static let keychainTokenKey = "OAuth2Token"
            @objc static let keychainUsernameKey = "Username"
            @objc static let keychainUserIDKey = "UserID"
        }
    }
}
