import Foundation
import BuildSettingsKit
import SFHFKeychainUtils

@objc
open class ShareExtensionService: NSObject {
    private let appGroupName: String
    private let appKeychainAccessGroup: String
    private let configuration: ShareExtensionConfiguration

    @objc public convenience override init() {
        let settings = BuildSettings.current
        self.init(
            appGroupName: settings.appGroupName,
            appKeychainAccessGroup: settings.appKeychainAccessGroup,
            configuration: settings.shareExtensionConfiguration
        )
    }

    public init(
        appGroupName: String,
        appKeychainAccessGroup: String,
        configuration: ShareExtensionConfiguration
    ) {
        self.appGroupName = appGroupName
        self.appKeychainAccessGroup = appKeychainAccessGroup
        self.configuration = configuration
    }

    /// Sets the OAuth Token that should be used by the Share Extension to hit the Dotcom Backend.
    ///
    /// - Parameter oauth2Token: WordPress.com OAuth Token
    ///
    @objc public func configureShareExtensionToken(_ oauth2Token: String) {
        do {
            try SFHFKeychainUtils.storeUsername(
                configuration.keychainTokenKey,
                andPassword: oauth2Token,
                forServiceName: configuration.keychainServiceName,
                accessGroup: appKeychainAccessGroup,
                updateExisting: true
            )
        } catch {
            print("Error while saving Share Extension OAuth bearer token: \(error)")
        }
    }

    /// Sets the Username that should be used by the Share Extension to hit the Dotcom Backend.
    ///
    /// - Parameter oauth2Token: WordPress.com OAuth Token
    ///
    @objc public func configureShareExtensionUsername(_ username: String) {
        do {
            try SFHFKeychainUtils.storeUsername(
                configuration.keychainUsernameKey,
                andPassword: username,
                forServiceName: configuration.keychainServiceName,
                accessGroup: appKeychainAccessGroup,
                updateExisting: true
            )
        } catch {
            print("Error while saving Share Extension OAuth bearer token: \(error)")
        }
    }

    /// Sets the Primary Site that should be pre-selected in the Share Extension when no Last
    /// Used Site is present.
    ///
    /// - Parameters:
    ///     - defaultSiteID: The ID of the Primary Site.
    ///     - defaultSiteName: The Primary Site's Name
    ///
    @objc public func configureShareExtensionDefaultSiteID(_ defaultSiteID: Int, defaultSiteName: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return
        }

        userDefaults.set(defaultSiteID, forKey: configuration.userDefaultsPrimarySiteID)
        userDefaults.set(defaultSiteName, forKey: configuration.userDefaultsPrimarySiteName)
    }

    /// Sets the Last Used Site that should be pre-selected in the Share Extension.
    ///
    /// - Parameters:
    ///     - lastUsedSiteID: The ID of the Last Used Site.
    ///     - lastUsedSiteName: The Last Used Site's Name
    ///
    @objc public func configureShareExtensionLastUsedSiteID(_ lastUsedSiteID: Int, lastUsedSiteName: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return
        }

        userDefaults.set(lastUsedSiteID, forKey: configuration.userDefaultsLastUsedSiteID)
        userDefaults.set(lastUsedSiteName, forKey: configuration.userDefaultsLastUsedSiteName)
    }

    /// Sets the Maximum Media Size.
    ///
    /// - Parameter maximumMediaSize: The maximum size a media attachment might occupy.
    ///
    @objc public func configureShareExtensionMaximumMediaDimension(_ maximumMediaDimension: Int) {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return
        }

        userDefaults.set(maximumMediaDimension, forKey: configuration.maximumMediaDimensionKey)
    }

    /// Sets the recently used sites.
    ///
    /// - Parameter recentSites: An array of URL's representing the recently used sites.
    ///
    @objc public func configureShareExtensionRecentSites(_ recentSites: [String]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return
        }

        userDefaults.set(recentSites, forKey: configuration.recentSitesKey)
    }

    /// Nukes all of the Share Extension Configuration
    ///
    @objc public func removeShareExtensionConfiguration() {
        do {
            try SFHFKeychainUtils.deleteItem(
                forUsername: configuration.keychainTokenKey,
                andServiceName: configuration.keychainServiceName,
                accessGroup: appKeychainAccessGroup
            )
        } catch {
            print("Error while removing Share Extension OAuth2 bearer token: \(error)")
        }

        do {
            try SFHFKeychainUtils.deleteItem(
                forUsername: configuration.keychainUsernameKey,
                andServiceName: configuration.keychainServiceName,
                accessGroup: appKeychainAccessGroup
            )
        } catch {
            print("Error while removing Share Extension Username: \(error)")
        }

        if let userDefaults = UserDefaults(suiteName: appGroupName) {
            userDefaults.removeObject(forKey: configuration.userDefaultsPrimarySiteID)
            userDefaults.removeObject(forKey: configuration.userDefaultsPrimarySiteName)
            userDefaults.removeObject(forKey: configuration.userDefaultsLastUsedSiteID)
            userDefaults.removeObject(forKey: configuration.userDefaultsLastUsedSiteName)
            userDefaults.removeObject(forKey: configuration.maximumMediaDimensionKey)
            userDefaults.removeObject(forKey: configuration.recentSitesKey)
        }
    }

    /// Retrieves the WordPress.com OAuth Token, meant for Extension usage.
    ///
    @objc public func retrieveShareExtensionToken() -> String? {
        guard let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(
            configuration.keychainTokenKey,
            andServiceName: configuration.keychainServiceName,
            accessGroup: appKeychainAccessGroup
        ) else {
            return nil
        }

        return oauth2Token
    }

    /// Retrieves the WordPress.com Username, meant for Extension usage.
    ///
    @objc public func retrieveShareExtensionUsername() -> String? {
        guard let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(
            configuration.keychainUsernameKey,
            andServiceName: configuration.keychainServiceName,
            accessGroup: appKeychainAccessGroup
        ) else {
            return nil
        }

        return oauth2Token
    }

    /// Retrieves the Primary Site Details (ID + Name), if any.
    ///
    public func retrieveShareExtensionPrimarySite() -> (siteID: Int, siteName: String)? {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return nil
        }

        if let siteID = userDefaults.object(forKey: configuration.userDefaultsPrimarySiteID) as? Int,
            let siteName = userDefaults.object(forKey: configuration.userDefaultsPrimarySiteName) as? String {
            return (siteID, siteName)
        }

        return nil
    }

    /// Retrieves the Last Used Site Details (ID + Name) or, when that one is not present, the
    /// Primary Site Details, if any.
    ///
    public func retrieveShareExtensionDefaultSite() -> (siteID: Int, siteName: String)? {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return nil
        }

        if let siteID = userDefaults.object(forKey: configuration.userDefaultsLastUsedSiteID) as? Int,
            let siteName = userDefaults.object(forKey: configuration.userDefaultsLastUsedSiteName) as? String {
            return (siteID, siteName)
        }

        if let siteID = userDefaults.object(forKey: configuration.userDefaultsPrimarySiteID) as? Int,
            let siteName = userDefaults.object(forKey: configuration.userDefaultsPrimarySiteName) as? String {
            return (siteID, siteName)
        }

        return nil
    }

    /// Retrieves the Maximum Media Attachment Size
    ///
    public func retrieveShareExtensionMaximumMediaDimension() -> Int? {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return nil
        }

        return userDefaults.object(forKey: configuration.maximumMediaDimensionKey) as? Int
    }

    /// Retrieves the recently used sites, if any.
    ///
    public func retrieveShareExtensionRecentSites() -> [String]? {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return nil
        }

        return userDefaults.object(forKey: configuration.recentSitesKey) as? [String]
    }
}
