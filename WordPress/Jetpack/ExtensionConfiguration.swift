// Jetpack Extension configuration

import Foundation

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
            @objc static let enabledKey = "JetpackNotificationsEnabled"
        }
    }
}
