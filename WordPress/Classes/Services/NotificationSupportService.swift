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

    /// Sets the Username that should be used by the Notification Content Extension to access WPCOM.
    ///
    /// - Parameter username: WordPress.com username
    ///
    @objc
    class func insertContentExtensionUsername(_ username: String) {
        do {
            try SFHFKeychainUtils.storeUsername(WPNotificationContentExtensionKeychainUsernameKey,
                                                andPassword: username,
                                                forServiceName: WPNotificationContentExtensionKeychainServiceName,
                                                accessGroup: WPAppKeychainAccessGroup,
                                                updateExisting: true)
        } catch {
            DDLogDebug("Error while saving Notification Content Extension username: \(error)")
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

    /// Sets the Username that should be used by the Notification Content Extension to access WPCOM.
    ///
    /// - Parameter username: WordPress.com username
    ///
    @objc
    class func insertServiceExtensionUsername(_ username: String) {
        do {
            try SFHFKeychainUtils.storeUsername(WPNotificationServiceExtensionKeychainUsernameKey,
                                                andPassword: username,
                                                forServiceName: WPNotificationServiceExtensionKeychainServiceName,
                                                accessGroup: WPAppKeychainAccessGroup,
                                                updateExisting: true)
        } catch {
            DDLogDebug("Error while saving Notification Service Extension username: \(error)")
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

    /// Attempts to delete the current WPCOM Username used by the Notification Content Extension.
    ///
    @objc
    class func deleteContentExtensionUsername() {
        do {
            try SFHFKeychainUtils.deleteItem(forUsername: WPNotificationContentExtensionKeychainUsernameKey,
                                             andServiceName: WPNotificationContentExtensionKeychainServiceName,
                                             accessGroup: WPAppKeychainAccessGroup)
        } catch {
            DDLogDebug("Error while removing Notification Content Extension username: \(error)")
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

    /// Attempts to delete the current WPCOM Username used by the Notification Service Extension.
    ///
    @objc
    class func deleteServiceExtensionUsername() {
        do {
            try SFHFKeychainUtils.deleteItem(forUsername: WPNotificationServiceExtensionKeychainUsernameKey,
                                             andServiceName: WPNotificationServiceExtensionKeychainServiceName,
                                             accessGroup: WPAppKeychainAccessGroup)
        } catch {
            DDLogDebug("Error while removing Notification Service Extension username: \(error)")
        }
    }
}
