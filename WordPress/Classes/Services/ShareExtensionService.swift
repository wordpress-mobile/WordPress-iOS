import Foundation

@objc
public class ShareExtensionService: NSObject
{
    /// Sets the OAuth Token that should be used by the Share Extension to hit the Dotcom Backend.
    ///
    /// -   Parameters:
    ///     - oauth2Token: WordPress.com OAuth Token
    ///
    class func configureShareExtensionToken(oauth2Token: String) {
        do {
            try SFHFKeychainUtils.storeUsername(WPAppOAuth2TokenKeychainUsername,
                andPassword: oauth2Token,
                forServiceName: WPAppOAuth2TokenKeychainServiceName,
                accessGroup: WPAppKeychainAccessGroup,
                updateExisting: true)
        } catch {
            print("Error while saving Share Extension OAuth bearer token: \(error)")
        }
    }

    /// Sets the Primary Site that should be pre-selected in the Share Extension.
    ///
    /// -   Parameters:
    ///     - defaultSiteID: The ID of the Primary Site.
    ///     - defaultSiteName: The Primary Site's Name
    ///
    class func configureShareExtensionDefaultSiteID(defaultSiteID: Int, defaultSiteName: String) {
        guard let userDefaults = NSUserDefaults(suiteName: WPAppDefaultsGroupName) else {
            return
        }
        
        userDefaults.setObject(defaultSiteID, forKey: WPShareUserDefaultsPrimarySiteID)
        userDefaults.setObject(defaultSiteName, forKey: WPShareUserDefaultsPrimarySiteName)
        userDefaults.synchronize()
    }

    /// Nukes all of the Share Extension Configuration
    ///
    class func removeShareExtensionConfiguration() {
        do {
            try SFHFKeychainUtils.deleteItemForUsername(WPAppOAuth2TokenKeychainUsername,
                andServiceName: WPAppOAuth2TokenKeychainServiceName,
                accessGroup: WPAppKeychainAccessGroup)
        } catch {
            print("Error while removing Share Extension OAuth2 bearer token: \(error)")
        }
        
            userDefaults.removeObjectForKey(WPShareUserDefaultsPrimarySiteID)
            userDefaults.removeObjectForKey(WPShareUserDefaultsPrimarySiteName)
        if let userDefaults = NSUserDefaults(suiteName: WPAppDefaultsGroupName) {
            userDefaults.synchronize()
        }
    }
    
    /// Retrieves the WordPress.com OAuth Token, meant for Extension usage.
    ///
    /// - Returns: The OAuth Token, if any.
    ///
    class func retrieveShareExtensionToken() -> String? {
        guard let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(WPAppOAuth2TokenKeychainUsername,
            andServiceName: WPShareExtensionTokenKeychainServiceName, accessGroup: WPAppKeychainAccessGroup) else
        {
            return nil
        }
        
        return oauth2Token
    }
    
    /// Retrieves the Primary Site Details
    ///
    /// - Returns: Tuple with the Primary Site ID + Name. If any.
    ///
    class func retrieveShareExtensionPrimarySite() -> (siteID: Int, siteName: String)? {
        guard let userDefaults = NSUserDefaults(suiteName: WPAppDefaultsGroupName) else {
            return nil
        }
        
        guard let siteID = userDefaults.objectForKey(WPShareUserDefaultsPrimarySiteID) as? Int,
            let siteName = userDefaults.objectForKey(WPShareUserDefaultsPrimarySiteName) as? String else
        {
            return nil
        }
        
        return (siteID, siteName)
    }
}
