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
            try KeychainUtils.shared.storeUsername(
                    WPNotificationContentExtensionKeychainTokenKey,
                    password: oauthToken,
                    serviceName: WPNotificationContentExtensionKeychainServiceName,
                    accessGroup: WPAppKeychainAccessGroup,
                    updateExisting: true
            )
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
            try KeychainUtils.shared.storeUsername(
                    WPNotificationContentExtensionKeychainUsernameKey,
                    password: username,
                    serviceName: WPNotificationContentExtensionKeychainServiceName,
                    accessGroup: WPAppKeychainAccessGroup,
                    updateExisting: true
            )
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
            try KeychainUtils.shared.storeUsername(
                    WPNotificationServiceExtensionKeychainTokenKey,
                    password: oauthToken,
                    serviceName: WPNotificationServiceExtensionKeychainServiceName,
                    accessGroup: WPAppKeychainAccessGroup,
                    updateExisting: true
            )
        } catch {
            DDLogDebug("Error while saving Notification Service Extension OAuth token: \(error)")
        }
    }

    /// Sets the Username that should be used by the Notification Service Extension to access WPCOM.
    ///
    /// - Parameter username: WordPress.com username
    ///
    @objc
    class func insertServiceExtensionUsername(_ username: String) {
        do {
            try KeychainUtils.shared.storeUsername(
                    WPNotificationServiceExtensionKeychainUsernameKey,
                    password: username,
                    serviceName: WPNotificationServiceExtensionKeychainServiceName,
                    accessGroup: WPAppKeychainAccessGroup,
                    updateExisting: true
            )
        } catch {
            DDLogDebug("Error while saving Notification Service Extension username: \(error)")
        }
    }

    /// Sets the UserID  that should be used by the Notification Service Extension to access WPCOM.
    ///
    /// - Parameter userID: WordPress.com userID
    ///
    @objc
    class func insertServiceExtensionUserID(_ userID: String) {
        do {
            try KeychainUtils.shared.storeUsername(
                    WPNotificationServiceExtensionKeychainUserIDKey,
                    password: userID,
                    serviceName: WPNotificationServiceExtensionKeychainServiceName,
                    accessGroup: WPAppKeychainAccessGroup,
                    updateExisting: true
            )
        } catch {
            DDLogDebug("Error while saving Notification Service Extension userID: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM OAuth Token used by the Notification Content Extension.
    ///
    @objc
    class func deleteContentExtensionToken() {
        do {
            try KeychainUtils.shared.deleteItem(
                    username: WPNotificationContentExtensionKeychainTokenKey,
                    serviceName: WPNotificationContentExtensionKeychainServiceName,
                    accessGroup: WPAppKeychainAccessGroup
            )
        } catch {
            DDLogDebug("Error while removing Notification Content Extension OAuth token: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM Username used by the Notification Content Extension.
    ///
    @objc
    class func deleteContentExtensionUsername() {
        do {
            try KeychainUtils.shared.deleteItem(
                    username: WPNotificationContentExtensionKeychainUsernameKey,
                    serviceName: WPNotificationContentExtensionKeychainServiceName,
                    accessGroup: WPAppKeychainAccessGroup
            )
        } catch {
            DDLogDebug("Error while removing Notification Content Extension username: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM OAuth Token used by the Notification Service Extension.
    ///
    @objc
    class func deleteServiceExtensionToken() {
        do {
            try KeychainUtils.shared.deleteItem(
                    username: WPNotificationServiceExtensionKeychainTokenKey,
                    serviceName: WPNotificationServiceExtensionKeychainServiceName,
                    accessGroup: WPAppKeychainAccessGroup
            )
        } catch {
            DDLogDebug("Error while removing Notification Service Extension OAuth token: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM Username used by the Notification Service Extension.
    ///
    @objc
    class func deleteServiceExtensionUsername() {
        do {
            try KeychainUtils.shared.deleteItem(
                    username: WPNotificationServiceExtensionKeychainUsernameKey,
                    serviceName: WPNotificationServiceExtensionKeychainServiceName,
                    accessGroup: WPAppKeychainAccessGroup
            )
        } catch {
            DDLogDebug("Error while removing Notification Service Extension username: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM Username used by the Notification Service Extension.
    ///
    @objc
    class func deleteServiceExtensionUserID() {
        do {
            try KeychainUtils.shared.deleteItem(
                    username: WPNotificationServiceExtensionKeychainUserIDKey,
                    serviceName: WPNotificationServiceExtensionKeychainServiceName,
                    accessGroup: WPAppKeychainAccessGroup
            )
        } catch {
            DDLogDebug("Error while removing Notification Service Extension userID: \(error)")
        }
    }
}
