import Foundation
import BuildSettingsKit
import SFHFKeychainUtils
import NotificationServiceExtensionCore

final class NotificationSupportService {
    private let appKeychainAccessGroup: String
    private let configuration: NotificationServiceExtensionConfiguration

    convenience init() {
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
    /// - Parameter authToken: WordPress.com OAuth Token
    ///
    func storeToken(_ authToken: String) {
        do {
            try SFHFKeychainUtils.storeUsername(
                configuration.keychainTokenKey,
                andPassword: authToken,
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
    func storeUsername(_ username: String) {
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
    func storeUserID(_ userID: String) {
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
