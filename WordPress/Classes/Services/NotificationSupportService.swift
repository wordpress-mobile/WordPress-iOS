import Foundation

@objc
open class NotificationSupportService: NSObject {
    /// Sets the OAuth Token that should be used by the Notification Service Extension to access WPCOM.
    ///
    /// - Parameter oauth2Token: WordPress.com OAuth Token
    ///
    @objc
    class func insertExtensionToken(_ oauthToken: String) {
        do {
            try SFHFKeychainUtils.storeUsername(WPNotificationServiceExtensionKeychainTokenKey,
                                                andPassword: oauthToken,
                                                forServiceName: WPNotificationServiceExtensionKeychainServiceName,
                                                accessGroup: WPAppKeychainAccessGroup,
                                                updateExisting: true)
        } catch {
            DDLogDebug("Error while saving Notification Service Extension OAuth token: \(error)")
        }
    }

    /// Attempts to the current WPCOM OAuth Token
    ///
    @objc
    class func deleteExtensionToken() {
        do {
            try SFHFKeychainUtils.deleteItem(forUsername: WPNotificationServiceExtensionKeychainTokenKey,
                                             andServiceName: WPNotificationServiceExtensionKeychainServiceName,
                                             accessGroup: WPAppKeychainAccessGroup)
        } catch {
            DDLogDebug("Error while removing Notification Service Extension OAuth token: \(error)")
        }
    }
}
