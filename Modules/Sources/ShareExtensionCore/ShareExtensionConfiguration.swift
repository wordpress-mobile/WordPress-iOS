import Foundation
import BuildSettingsKit

extension BuildSettings {
    public var shareExtensionConfiguration: ShareExtensionConfiguration {
        switch brand {
        case .wordpress: return .wordpress
        case .jetpack: return .jetpack
        }
    }
}

public struct ShareExtensionConfiguration: Sendable {
    public var keychainUsernameKey: String
    public var keychainTokenKey: String
    public var keychainServiceName: String
    public var userDefaultsPrimarySiteName: String
    public var userDefaultsPrimarySiteID: String
    public var userDefaultsLastUsedSiteName: String
    public var userDefaultsLastUsedSiteID: String
    public var maximumMediaDimensionKey: String
    public var recentSitesKey: String

    static let wordpress = ShareExtensionConfiguration(
        keychainUsernameKey: "Username",
        keychainTokenKey: "OAuth2Token",
        keychainServiceName: "ShareExtension",
        userDefaultsPrimarySiteName: "WPShareUserDefaultsPrimarySiteName",
        userDefaultsPrimarySiteID: "WPShareUserDefaultsPrimarySiteID",
        userDefaultsLastUsedSiteName: "WPShareUserDefaultsLastUsedSiteName",
        userDefaultsLastUsedSiteID: "WPShareUserDefaultsLastUsedSiteID",
        maximumMediaDimensionKey: "WPShareExtensionMaximumMediaDimensionKey",
        recentSitesKey: "WPShareExtensionRecentSitesKey"
    )

    static let jetpack = ShareExtensionConfiguration(
        keychainUsernameKey: "JPUsername",
        keychainTokenKey: "JPOAuth2Token",
        keychainServiceName: "JPShareExtension",
        userDefaultsPrimarySiteName: "JPShareUserDefaultsPrimarySiteName",
        userDefaultsPrimarySiteID: "JPShareUserDefaultsPrimarySiteID",
        userDefaultsLastUsedSiteName: "JPShareUserDefaultsLastUsedSiteName",
        userDefaultsLastUsedSiteID: "JPShareUserDefaultsLastUsedSiteID",
        maximumMediaDimensionKey: "JPShareExtensionMaximumMediaDimensionKey",
        recentSitesKey: "JPShareExtensionRecentSitesKey"
    )
}
