import Foundation
import BuildSettingsKit
import SFHFKeychainUtils

@objc
open class ShareExtensionService: NSObject {
    private let appGroupName: String
    private let appKeychainAccessGroup: String

    @objc public convenience override init() {
        self.init(
            appGroupName: BuildSettings.appGroupName,
            appKeychainAccessGroup: BuildSettings.appKeychainAccessGroup
        )
    }

    public init(appGroupName: String, appKeychainAccessGroup: String) {
        self.appGroupName = appGroupName
        self.appKeychainAccessGroup = appKeychainAccessGroup
    }

    /// Sets the OAuth Token that should be used by the Share Extension to hit the Dotcom Backend.
    ///
    /// - Parameter oauth2Token: WordPress.com OAuth Token
    ///
    @objc func configureShareExtensionToken(_ oauth2Token: String) {
        do {
            try SFHFKeychainUtils.storeUsername(
                AppConfiguration.Extension.Share.keychainTokenKey,
                andPassword: oauth2Token,
                forServiceName: AppConfiguration.Extension.Share.keychainServiceName,
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
    @objc func configureShareExtensionUsername(_ username: String) {
        do {
            try SFHFKeychainUtils.storeUsername(
                AppConfiguration.Extension.Share.keychainUsernameKey,
                andPassword: username,
                forServiceName: AppConfiguration.Extension.Share.keychainServiceName,
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
    @objc func configureShareExtensionDefaultSiteID(_ defaultSiteID: Int, defaultSiteName: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return
        }

        userDefaults.set(defaultSiteID, forKey: AppConfiguration.Extension.Share.userDefaultsPrimarySiteID)
        userDefaults.set(defaultSiteName, forKey: AppConfiguration.Extension.Share.userDefaultsPrimarySiteName)
    }

    /// Sets the Last Used Site that should be pre-selected in the Share Extension.
    ///
    /// - Parameters:
    ///     - lastUsedSiteID: The ID of the Last Used Site.
    ///     - lastUsedSiteName: The Last Used Site's Name
    ///
    @objc func configureShareExtensionLastUsedSiteID(_ lastUsedSiteID: Int, lastUsedSiteName: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return
        }

        userDefaults.set(lastUsedSiteID, forKey: AppConfiguration.Extension.Share.userDefaultsLastUsedSiteID)
        userDefaults.set(lastUsedSiteName, forKey: AppConfiguration.Extension.Share.userDefaultsLastUsedSiteName)
    }

    /// Sets the Maximum Media Size.
    ///
    /// - Parameter maximumMediaSize: The maximum size a media attachment might occupy.
    ///
    @objc func configureShareExtensionMaximumMediaDimension(_ maximumMediaDimension: Int) {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return
        }

        userDefaults.set(maximumMediaDimension, forKey: AppConfiguration.Extension.Share.maximumMediaDimensionKey)
    }

    /// Sets the recently used sites.
    ///
    /// - Parameter recentSites: An array of URL's representing the recently used sites.
    ///
    @objc func configureShareExtensionRecentSites(_ recentSites: [String]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return
        }

        userDefaults.set(recentSites, forKey: AppConfiguration.Extension.Share.recentSitesKey)
    }

    /// Nukes all of the Share Extension Configuration
    ///
    @objc func removeShareExtensionConfiguration() {
        do {
            try SFHFKeychainUtils.deleteItem(
                forUsername: AppConfiguration.Extension.Share.keychainTokenKey,
                andServiceName: AppConfiguration.Extension.Share.keychainServiceName,
                accessGroup: appKeychainAccessGroup
            )
        } catch {
            print("Error while removing Share Extension OAuth2 bearer token: \(error)")
        }

        do {
            try SFHFKeychainUtils.deleteItem(
                forUsername: AppConfiguration.Extension.Share.keychainUsernameKey,
                andServiceName: AppConfiguration.Extension.Share.keychainServiceName,
                accessGroup: appKeychainAccessGroup
            )
        } catch {
            print("Error while removing Share Extension Username: \(error)")
        }

        if let userDefaults = UserDefaults(suiteName: appGroupName) {
            userDefaults.removeObject(forKey: AppConfiguration.Extension.Share.userDefaultsPrimarySiteID)
            userDefaults.removeObject(forKey: AppConfiguration.Extension.Share.userDefaultsPrimarySiteName)
            userDefaults.removeObject(forKey: AppConfiguration.Extension.Share.userDefaultsLastUsedSiteID)
            userDefaults.removeObject(forKey: AppConfiguration.Extension.Share.userDefaultsLastUsedSiteName)
            userDefaults.removeObject(forKey: AppConfiguration.Extension.Share.maximumMediaDimensionKey)
            userDefaults.removeObject(forKey: AppConfiguration.Extension.Share.recentSitesKey)
        }
    }

    /// Retrieves the WordPress.com OAuth Token, meant for Extension usage.
    ///
    @objc func retrieveShareExtensionToken() -> String? {
        guard let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(AppConfiguration.Extension.Share.keychainTokenKey,
                                                                              andServiceName: AppConfiguration.Extension.Share.keychainServiceName,
                                                                              accessGroup: appKeychainAccessGroup) else {
            return nil
        }

        return oauth2Token
    }

    /// Retrieves the WordPress.com Username, meant for Extension usage.
    ///
    @objc func retrieveShareExtensionUsername() -> String? {
        guard let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(AppConfiguration.Extension.Share.keychainUsernameKey,
                                                                              andServiceName: AppConfiguration.Extension.Share.keychainServiceName,
                                                                              accessGroup: appKeychainAccessGroup) else {
            return nil
        }

        return oauth2Token
    }

    /// Retrieves the Primary Site Details (ID + Name), if any.
    ///
    func retrieveShareExtensionPrimarySite() -> (siteID: Int, siteName: String)? {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return nil
        }

        if let siteID = userDefaults.object(forKey: AppConfiguration.Extension.Share.userDefaultsPrimarySiteID) as? Int,
            let siteName = userDefaults.object(forKey: AppConfiguration.Extension.Share.userDefaultsPrimarySiteName) as? String {
            return (siteID, siteName)
        }

        return nil
    }

    /// Retrieves the Last Used Site Details (ID + Name) or, when that one is not present, the
    /// Primary Site Details, if any.
    ///
    func retrieveShareExtensionDefaultSite() -> (siteID: Int, siteName: String)? {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return nil
        }

        if let siteID = userDefaults.object(forKey: AppConfiguration.Extension.Share.userDefaultsLastUsedSiteID) as? Int,
            let siteName = userDefaults.object(forKey: AppConfiguration.Extension.Share.userDefaultsLastUsedSiteName) as? String {
            return (siteID, siteName)
        }

        if let siteID = userDefaults.object(forKey: AppConfiguration.Extension.Share.userDefaultsPrimarySiteID) as? Int,
            let siteName = userDefaults.object(forKey: AppConfiguration.Extension.Share.userDefaultsPrimarySiteName) as? String {
            return (siteID, siteName)
        }

        return nil
    }

    /// Retrieves the Maximum Media Attachment Size
    ///
    func retrieveShareExtensionMaximumMediaDimension() -> Int? {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return nil
        }

        return userDefaults.object(forKey: AppConfiguration.Extension.Share.maximumMediaDimensionKey) as? Int
    }

    /// Retrieves the recently used sites, if any.
    ///
    func retrieveShareExtensionRecentSites() -> [String]? {
        guard let userDefaults = UserDefaults(suiteName: appGroupName) else {
            return nil
        }

        return userDefaults.object(forKey: AppConfiguration.Extension.Share.recentSitesKey) as? [String]
    }
}
