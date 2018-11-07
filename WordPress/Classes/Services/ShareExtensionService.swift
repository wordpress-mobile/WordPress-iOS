import Foundation

@objc
open class ShareExtensionService: NSObject {
    /// Sets the OAuth Token that should be used by the Share Extension to hit the Dotcom Backend.
    ///
    /// - Parameter oauth2Token: WordPress.com OAuth Token
    ///
    @objc class func configureShareExtensionToken(_ oauth2Token: String) {
        do {
            try SFHFKeychainUtils.storeUsername(WPShareExtensionKeychainTokenKey,
                andPassword: oauth2Token,
                forServiceName: WPShareExtensionKeychainServiceName,
                accessGroup: WPAppKeychainAccessGroup,
                updateExisting: true)
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
            try SFHFKeychainUtils.storeUsername(WPShareExtensionKeychainUsernameKey,
                andPassword: username,
                forServiceName: WPShareExtensionKeychainServiceName,
                accessGroup: WPAppKeychainAccessGroup,
                updateExisting: true)
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

        userDefaults.set(defaultSiteID, forKey: WPShareExtensionUserDefaultsPrimarySiteID)
        userDefaults.set(defaultSiteName, forKey: WPShareExtensionUserDefaultsPrimarySiteName)
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

        userDefaults.set(lastUsedSiteID, forKey: WPShareExtensionUserDefaultsLastUsedSiteID)
        userDefaults.set(lastUsedSiteName, forKey: WPShareExtensionUserDefaultsLastUsedSiteName)
    }

    /// Sets the Maximum Media Size.
    ///
    /// - Parameter maximumMediaSize: The maximum size a media attachment might occupy.
    ///
    @objc class func configureShareExtensionMaximumMediaDimension(_ maximumMediaDimension: Int) {
        guard let userDefaults = UserDefaults(suiteName: WPAppGroupName) else {
            return
        }

        userDefaults.set(maximumMediaDimension, forKey: WPShareExtensionMaximumMediaDimensionKey)
    }


    /// Sets the recently used sites.
    ///
    /// - Parameter recentSites: An array of URL's representing the recently used sites.
    ///
    @objc class func configureShareExtensionRecentSites(_ recentSites: [String]) {
        guard let userDefaults = UserDefaults(suiteName: WPAppGroupName) else {
            return
        }

        userDefaults.set(recentSites, forKey: WPShareExtensionRecentSitesKey)
    }

    /// Nukes all of the Share Extension Configuration
    ///
    @objc class func removeShareExtensionConfiguration() {
        do {
            try SFHFKeychainUtils.deleteItem(forUsername: WPShareExtensionKeychainTokenKey,
                andServiceName: WPShareExtensionKeychainServiceName,
                accessGroup: WPAppKeychainAccessGroup)
        } catch {
            print("Error while removing Share Extension OAuth2 bearer token: \(error)")
        }

        do {
            try SFHFKeychainUtils.deleteItem(forUsername: WPShareExtensionKeychainUsernameKey,
                andServiceName: WPShareExtensionKeychainServiceName,
                accessGroup: WPAppKeychainAccessGroup)
        } catch {
            print("Error while removing Share Extension Username: \(error)")
        }

        if let userDefaults = UserDefaults(suiteName: WPAppGroupName) {
            userDefaults.removeObject(forKey: WPShareExtensionUserDefaultsPrimarySiteID)
            userDefaults.removeObject(forKey: WPShareExtensionUserDefaultsPrimarySiteName)
            userDefaults.removeObject(forKey: WPShareExtensionUserDefaultsLastUsedSiteID)
            userDefaults.removeObject(forKey: WPShareExtensionUserDefaultsLastUsedSiteName)
            userDefaults.removeObject(forKey: WPShareExtensionMaximumMediaDimensionKey)
            userDefaults.removeObject(forKey: WPShareExtensionRecentSitesKey)
        }
    }

    /// Retrieves the WordPress.com OAuth Token, meant for Extension usage.
    ///
    @objc class func retrieveShareExtensionToken() -> String? {
        guard let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(WPShareExtensionKeychainTokenKey,
            andServiceName: WPShareExtensionKeychainServiceName, accessGroup: WPAppKeychainAccessGroup) else {
            return nil
        }

        return oauth2Token
    }

    /// Retrieves the WordPress.com Username, meant for Extension usage.
    ///
    @objc class func retrieveShareExtensionUsername() -> String? {
        guard let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(WPShareExtensionKeychainUsernameKey,
            andServiceName: WPShareExtensionKeychainServiceName, accessGroup: WPAppKeychainAccessGroup) else {
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

        if let siteID = userDefaults.object(forKey: WPShareExtensionUserDefaultsPrimarySiteID) as? Int,
            let siteName = userDefaults.object(forKey: WPShareExtensionUserDefaultsPrimarySiteName) as? String {
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

        if let siteID = userDefaults.object(forKey: WPShareExtensionUserDefaultsLastUsedSiteID) as? Int,
            let siteName = userDefaults.object(forKey: WPShareExtensionUserDefaultsLastUsedSiteName) as? String {
            return (siteID, siteName)
        }

        if let siteID = userDefaults.object(forKey: WPShareExtensionUserDefaultsPrimarySiteID) as? Int,
            let siteName = userDefaults.object(forKey: WPShareExtensionUserDefaultsPrimarySiteName) as? String {
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

        return userDefaults.object(forKey: WPShareExtensionMaximumMediaDimensionKey) as? Int
    }

    /// Retrieves the recently used sites, if any.
    ///
    class func retrieveShareExtensionRecentSites() -> [String]? {
        guard let userDefaults = UserDefaults(suiteName: WPAppGroupName) else {
            return nil
        }

        return userDefaults.object(forKey: WPShareExtensionRecentSitesKey) as? [String]
    }
}
