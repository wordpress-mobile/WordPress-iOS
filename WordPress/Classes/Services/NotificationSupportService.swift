import Foundation
import BuildSettingsKit
import NotificationServiceExtensionCore
import WordPressShared

final class NotificationSupportService {
    private let configuration: NotificationServiceExtensionConfiguration
    private let keychain: any KeychainAccessible

    convenience init() {
        self.init(
            configuration: BuildSettings.current.notificationServiceExtensionConfiguration
        )
    }

    init(
        configuration: NotificationServiceExtensionConfiguration,
        keychain: any KeychainAccessible = AppKeychain()
    ) {
        self.configuration = configuration
        self.keychain = keychain
    }

    /// Sets the OAuth Token that should be used by the Notification Service Extension to access WPCOM.
    ///
    /// - Parameter authToken: WordPress.com OAuth Token
    ///
    func storeToken(_ authToken: String) {
        do {
            try keychain.setPassword(
                for: configuration.keychainTokenKey,
                to: authToken,
                serviceName: configuration.keychainServiceName
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
            try keychain.setPassword(
                for: configuration.keychainUsernameKey,
                to: username,
                serviceName: configuration.keychainServiceName
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
            try keychain.setPassword(
                for: configuration.keychainUserIDKey,
                to: userID,
                serviceName: configuration.keychainServiceName
            )
        } catch {
            DDLogDebug("Error while saving Notification Service Extension userID: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM OAuth Token used by the Notification Service Extension.
    ///
    func deleteServiceExtensionToken() {
        do {
            try keychain.setPassword(
                for: configuration.keychainTokenKey,
                to: nil,
                serviceName: configuration.keychainServiceName
            )
        } catch {
            DDLogDebug("Error while removing Notification Service Extension OAuth token: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM Username used by the Notification Service Extension.
    ///
    func deleteServiceExtensionUsername() {
        do {
            try keychain.setPassword(
                for: configuration.keychainUsernameKey,
                to: nil,
                serviceName: configuration.keychainServiceName
            )
        } catch {
            DDLogDebug("Error while removing Notification Service Extension username: \(error)")
        }
    }

    /// Attempts to delete the current WPCOM Username used by the Notification Service Extension.
    ///
    func deleteServiceExtensionUserID() {
        do {
            try keychain.setPassword(
                for: configuration.keychainUserIDKey,
                to: nil,
                serviceName: configuration.keychainServiceName
            )
        } catch {
            DDLogDebug("Error while removing Notification Service Extension userID: \(error)")
        }
    }
}
