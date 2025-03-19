import Foundation
import BuildSettingsKit

extension BuildSettings {
    public var notificationServiceExtensionConfiguration: NotificationServiceExtensionConfiguration {
        switch brand {
        case .wordpress: return .wordpress
        case .jetpack: return .jetpack
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
}
