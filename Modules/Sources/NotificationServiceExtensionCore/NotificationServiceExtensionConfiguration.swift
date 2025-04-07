import Foundation
import BuildSettingsKit

extension BuildSettings {
    public var notificationServiceExtensionConfiguration: NotificationServiceExtensionConfiguration {
        switch brand {
        case .wordpress: .wordpress
        case .jetpack: .jetpack
        case .reader: .reader
        }
    }
}

public struct NotificationServiceExtensionConfiguration: Sendable {
    public var keychainServiceName: String
    public var keychainTokenKey: String
    public var keychainUsernameKey: String
    public var keychainUserIDKey: String

    static let wordpress = NotificationServiceExtensionConfiguration(
        keychainServiceName: "NotificationServiceExtension",
        keychainTokenKey: "OAuth2Token",
        keychainUsernameKey: "Username",
        keychainUserIDKey: "UserID"
    )

    static let jetpack = NotificationServiceExtensionConfiguration(
        keychainServiceName: "JPNotificationServiceExtension",
        keychainTokenKey: "JPOAuth2Token",
        keychainUsernameKey: "JPUsername",
        keychainUserIDKey: "JPUserID"
    )

    static let reader = NotificationServiceExtensionConfiguration(
        keychainServiceName: "RRNotificationServiceExtension",
        keychainTokenKey: "RROAuth2Token",
        keychainUsernameKey: "RRUsername",
        keychainUserIDKey: "RRUserID"
    )
}
