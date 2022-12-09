// Jetpack Extension configuration

import Foundation

/// - Warning:
/// This configuration extension has a **WordPress** counterpart in the WordPress bundle.
/// Make sure to keep them in sync to avoid build errors when builing the WordPress target.
@objc extension AppConfiguration {

    @objc(AppConfigurationExtension)
    class Extension: NSObject {
        @objc(AppConfigurationExtensionShare)
        class Share: NSObject {
            @objc static let keychainUsernameKey = "JPUsername"
            @objc static let keychainTokenKey = "JPOAuth2Token"
            @objc static let keychainServiceName = "JPShareExtension"
            @objc static let userDefaultsPrimarySiteName = "JPShareUserDefaultsPrimarySiteName"
            @objc static let userDefaultsPrimarySiteID = "JPShareUserDefaultsPrimarySiteID"
            @objc static let userDefaultsLastUsedSiteName = "JPShareUserDefaultsLastUsedSiteName"
            @objc static let userDefaultsLastUsedSiteID = "JPShareUserDefaultsLastUsedSiteID"
            @objc static let maximumMediaDimensionKey = "JPShareExtensionMaximumMediaDimensionKey"
            @objc static let recentSitesKey = "JPShareExtensionRecentSitesKey"
        }

        @objc(AppConfigurationExtensionNotificationsService)
        class NotificationsService: NSObject {
            @objc static let keychainServiceName = "JPNotificationServiceExtension"
            @objc static let keychainTokenKey = "JPOAuth2Token"
            @objc static let keychainUsernameKey = "JPUsername"
            @objc static let keychainUserIDKey = "JPUserID"
        }
    }
}
