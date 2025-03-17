import Foundation
import BuildSettingsKit
import SFHFKeychainUtils

@objc
open class NotificationSupportService: NSObject {
    private let appKeychainAccessGroup: String

    @objc convenience override init() {
        self.init(appKeychainAccessGroup: BuildSettings.current.appKeychainAccessGroup)
    }

    init(appKeychainAccessGroup: String) {
        self.appKeychainAccessGroup = appKeychainAccessGroup
    }

    /// Sets the OAuth Token that should be used by the Notification Service Extension to access WPCOM.
    ///
    /// - Parameter oauth2Token: WordPress.com OAuth Token
    ///
    @objc
    func insertServiceExtensionToken(_ oauthToken: String) {
        do {
            try SFHFKeychainUtils.storeUsername(
                AppConfiguration.Extension.NotificationsService.keychainTokenKey,
                andPassword: oauthToken,
                forServiceName: AppConfiguration.Extension.NotificationsService.keychainServiceName,
                accessGroup: appKeychainAccessGroup,
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
    func insertServiceExtensionUsername(_ username: String) {
        do {
            try SFHFKeychainUtils.storeUsername(
                AppConfiguration.Extension.NotificationsService.keychainUsernameKey,
                andPassword: username,
                forServiceName: AppConfiguration.Extension.NotificationsService.keychainServiceName,
                accessGroup: appKeychainAccessGroup,
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
    func insertServiceExtensionUserID(_ userID: String) {
        do {
            try SFHFKeychainUtils.storeUsername(
                AppConfiguration.Extension.NotificationsService.keychainUserIDKey,
                andPassword: userID,
                forServiceName: AppConfiguration.Extension.NotificationsService.keychainServiceName,
                accessGroup: appKeychainAccessGroup,
                updateExisting: true
            )
        } catch {
            DDLogDebug("Error while saving Notification Service Extension userID: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM OAuth Token used by the Notification Service Extension.
    ///
    @objc
    func deleteServiceExtensionToken() {
        do {
            try SFHFKeychainUtils.deleteItem(
                forUsername: AppConfiguration.Extension.NotificationsService.keychainTokenKey,
                andServiceName: AppConfiguration.Extension.NotificationsService.keychainServiceName,
                accessGroup: appKeychainAccessGroup
            )
        } catch {
            DDLogDebug("Error while removing Notification Service Extension OAuth token: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM Username used by the Notification Service Extension.
    ///
    @objc
    func deleteServiceExtensionUsername() {
        do {
            try SFHFKeychainUtils.deleteItem(
                forUsername: AppConfiguration.Extension.NotificationsService.keychainUsernameKey,
                andServiceName: AppConfiguration.Extension.NotificationsService.keychainServiceName,
                accessGroup: appKeychainAccessGroup
            )
        } catch {
            DDLogDebug("Error while removing Notification Service Extension username: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM Username used by the Notification Service Extension.
    ///
    @objc
    func deleteServiceExtensionUserID() {
        do {
            try SFHFKeychainUtils.deleteItem(
                forUsername: AppConfiguration.Extension.NotificationsService.keychainUserIDKey,
                andServiceName: AppConfiguration.Extension.NotificationsService.keychainServiceName,
                accessGroup: appKeychainAccessGroup
            )
        } catch {
            DDLogDebug("Error while removing Notification Service Extension userID: \(error)")
        }
    }
}
