import Foundation

@objc
open class NotificationSupportService: NSObject {
    /// Sets the OAuth Token that should be used by the Notification Content Extension to access WPCOM.
    ///
    /// - Parameter oauth2Token: WordPress.com OAuth Token
    ///
    @objc
    class func insertContentExtensionToken(_ oauthToken: String) {
        do {
            try SFHFKeychainUtils.storeUsername(WPNotificationContentExtensionKeychainTokenKey,
                                                andPassword: oauthToken,
                                                forServiceName: WPNotificationContentExtensionKeychainServiceName,
                                                accessGroup: WPAppKeychainAccessGroup,
                                                updateExisting: true)
        } catch {
            DDLogDebug("Error while saving Notification Content Extension OAuth token: \(error)")
        }
    }

    /// Sets the OAuth Token that should be used by the Notification Service Extension to access WPCOM.
    ///
    /// - Parameter oauth2Token: WordPress.com OAuth Token
    ///
    @objc
    class func insertServiceExtensionToken(_ oauthToken: String) {
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

    /// Attempts to delete the current WPCOM OAuth Token used by the Notification Content Extension.
    ///
    @objc
    class func deleteContentExtensionToken() {
        do {
            try SFHFKeychainUtils.deleteItem(forUsername: WPNotificationContentExtensionKeychainTokenKey,
                                             andServiceName: WPNotificationContentExtensionKeychainServiceName,
                                             accessGroup: WPAppKeychainAccessGroup)
        } catch {
            DDLogDebug("Error while removing Notification Content Extension OAuth token: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM OAuth Token used by the Notification Service Extension.
    ///
    @objc
    class func deleteServiceExtensionToken() {
        do {
            try SFHFKeychainUtils.deleteItem(forUsername: WPNotificationServiceExtensionKeychainTokenKey,
                                             andServiceName: WPNotificationServiceExtensionKeychainServiceName,
                                             accessGroup: WPAppKeychainAccessGroup)
        } catch {
            DDLogDebug("Error while removing Notification Service Extension OAuth token: \(error)")
        }
    }
}
