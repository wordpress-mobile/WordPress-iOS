import Foundation

@objc
open class ShareExtensionService: NSObject {
    /// Sets the OAuth Token that should be used by the Share Extension to hit the Dotcom Backend.
    ///
    /// - Parameter oauth2Token: WordPress.com OAuth Token
    ///
    @objc class func configureShareExtensionToken(_ oauth2Token: String) {
        do {
            try SFHFKeychainUtils.storeUsername(
                AppConfiguration.Extension.Share.keychainTokenKey,
                andPassword: oauth2Token,
                forServiceName: AppConfiguration.Extension.Share.keychainServiceName,
                accessGroup: WPAppKeychainAccessGroup,
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
    @objc class func configureShareExtensionUsername(_ username: String) {
        do {
            try SFHFKeychainUtils.storeUsername(
                AppConfiguration.Extension.Share.keychainUsernameKey,
                andPassword: username,
                forServiceName: AppConfiguration.Extension.Share.keychainServiceName,
                accessGroup: WPAppKeychainAccessGroup,
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
    @objc class func configureShareExtensionDefaultSiteID(_ defaultSiteID: Int, defaultSiteName: String) {
        guard let userDefaults = UserDefaults(suiteName: WPAppGroupName) else {
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
    @objc class func configureShareExtensionLastUsedSiteID(_ lastUsedSiteID: Int, lastUsedSiteName: String) {
        guard let userDefaults = UserDefaults(suiteName: WPAppGroupName) else {
            return
        }

        userDefaults.set(lastUsedSiteID, forKey: AppConfiguration.Extension.Share.userDefaultsLastUsedSiteID)
        userDefaults.set(lastUsedSiteName, forKey: AppConfiguration.Extension.Share.userDefaultsLastUsedSiteName)
    }

    /// Sets the Maximum Media Size.
    ///
    /// - Parameter maximumMediaSize: The maximum size a media attachment might occupy.
    ///
    @objc class func configureShareExtensionMaximumMediaDimension(_ maximumMediaDimension: Int) {
        guard let userDefaults = UserDefaults(suiteName: WPAppGroupName) else {
            return
        }

        userDefaults.set(maximumMediaDimension, forKey: AppConfiguration.Extension.Share.maximumMediaDimensionKey)
    }

    /// Sets the recently used sites.
    ///
    /// - Parameter recentSites: An array of URL's representing the recently used sites.
    ///
    @objc class func configureShareExtensionRecentSites(_ recentSites: [String]) {
        guard let userDefaults = UserDefaults(suiteName: WPAppGroupName) else {
            return
        }

        userDefaults.set(recentSites, forKey: AppConfiguration.Extension.Share.recentSitesKey)
    }

    /// Nukes all of the Share Extension Configuration
    ///
    @objc class func removeShareExtensionConfiguration() {
        do {
            try SFHFKeychainUtils.deleteItem(
                forUsername: AppConfiguration.Extension.Share.keychainTokenKey,
                andServiceName: AppConfiguration.Extension.Share.keychainServiceName,
                accessGroup: WPAppKeychainAccessGroup
            )
        } catch {
            print("Error while removing Share Extension OAuth2 bearer token: \(error)")
        }

        do {
            try SFHFKeychainUtils.deleteItem(
                forUsername: AppConfiguration.Extension.Share.keychainUsernameKey,
                andServiceName: AppConfiguration.Extension.Share.keychainServiceName,
                accessGroup: WPAppKeychainAccessGroup
            )
        } catch {
            print("Error while removing Share Extension Username: \(error)")
        }

        if let userDefaults = UserDefaults(suiteName: WPAppGroupName) {
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
    @objc class func retrieveShareExtensionToken() -> String? {
        guard let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(AppConfiguration.Extension.Share.keychainTokenKey,
                                                                              andServiceName: AppConfiguration.Extension.Share.keychainServiceName,
                                                                              accessGroup: WPAppKeychainAccessGroup) else {
            return nil
        }

        return oauth2Token
    }

    /// Retrieves the WordPress.com Username, meant for Extension usage.
    ///
    @objc class func retrieveShareExtensionUsername() -> String? {
        guard let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(AppConfiguration.Extension.Share.keychainUsernameKey,
                                                                              andServiceName: AppConfiguration.Extension.Share.keychainServiceName,
                                                                              accessGroup: WPAppKeychainAccessGroup) else {
            return nil
        }

        return oauth2Token
    }

    /// Retrieves the Primary Site Details (ID + Name), if any.
    ///
    class func retrieveShareExtensionPrimarySite() -> (siteID: Int, siteName: String)? {
        guard let userDefaults = UserDefaults(suiteName: WPAppGroupName) else {
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
    class func retrieveShareExtensionDefaultSite() -> (siteID: Int, siteName: String)? {
        guard let userDefaults = UserDefaults(suiteName: WPAppGroupName) else {
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
    class func retrieveShareExtensionMaximumMediaDimension() -> Int? {
        guard let userDefaults = UserDefaults(suiteName: WPAppGroupName) else {
            return nil
        }

        return userDefaults.object(forKey: AppConfiguration.Extension.Share.maximumMediaDimensionKey) as? Int
    }

    /// Retrieves the recently used sites, if any.
    ///
    class func retrieveShareExtensionRecentSites() -> [String]? {
        guard let userDefaults = UserDefaults(suiteName: WPAppGroupName) else {
            return nil
        }

        return userDefaults.object(forKey: AppConfiguration.Extension.Share.recentSitesKey) as? [String]
    }
}
