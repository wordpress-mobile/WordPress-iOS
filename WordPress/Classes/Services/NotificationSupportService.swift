import Foundation
import BuildSettingsKit
import SFHFKeychainUtils
import NotificationServiceExtensionCore

@objc
open class NotificationSupportService: NSObject {
    private let appKeychainAccessGroup: String
    private let configuration: NotificationServiceExtensionConfiguration

    @objc convenience override init() {
        let settings = BuildSettings.current
        self.init(
            appKeychainAccessGroup: settings.appKeychainAccessGroup,
            configuration: settings.notificationServiceExtensionConfiguration
        )
    }

    init(appKeychainAccessGroup: String,
         configuration: NotificationServiceExtensionConfiguration) {
        self.appKeychainAccessGroup = appKeychainAccessGroup
        self.configuration = configuration
    }

    /// Sets the OAuth Token that should be used by the Notification Service Extension to access WPCOM.
    ///
    /// - Parameter oauth2Token: WordPress.com OAuth Token
    ///
    @objc
    func insertServiceExtensionToken(_ oauthToken: String) {
        do {
            try SFHFKeychainUtils.storeUsername(
                configuration.keychainTokenKey,
                andPassword: oauthToken,
                forServiceName: configuration.keychainServiceName,
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
                configuration.keychainUsernameKey,
                andPassword: username,
                forServiceName: configuration.keychainServiceName,
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
                configuration.keychainUserIDKey,
                andPassword: userID,
                forServiceName: configuration.keychainServiceName,
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
                forUsername: configuration.keychainTokenKey,
                andServiceName: configuration.keychainServiceName,
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
                forUsername: configuration.keychainUsernameKey,
                andServiceName: configuration.keychainServiceName,
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
                forUsername: configuration.keychainUserIDKey,
                andServiceName: configuration.keychainServiceName,
                accessGroup: appKeychainAccessGroup
            )
        } catch {
            DDLogDebug("Error while removing Notification Service Extension userID: \(error)")
        }
    }
}
