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
            try SFHFKeychainUtils.storeUsername(WPShareExtensionTokenKeychainUsername,
                andPassword: oauth2Token,
                forServiceName: WPShareExtensionTokenKeychainServiceName,
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
        guard let userDefaults = NSUserDefaults(suiteName: WPAppGroupName) else {
            return
        }
        
        userDefaults.setObject(defaultSiteID, forKey: WPShareExtensionUserDefaultsPrimarySiteID)
        userDefaults.setObject(defaultSiteName, forKey: WPShareExtensionUserDefaultsPrimarySiteName)
        userDefaults.synchronize()
    }

    /// Nukes all of the Share Extension Configuration
    ///
    class func removeShareExtensionConfiguration() {
        do {
            try SFHFKeychainUtils.deleteItemForUsername(WPShareExtensionTokenKeychainUsername,
                andServiceName: WPShareExtensionTokenKeychainServiceName,
                accessGroup: WPAppKeychainAccessGroup)
        } catch {
            print("Error while removing Share Extension OAuth2 bearer token: \(error)")
        }
        
        if let userDefaults = NSUserDefaults(suiteName: WPAppGroupName) {
            userDefaults.removeObjectForKey(WPShareExtensionUserDefaultsPrimarySiteID)
            userDefaults.removeObjectForKey(WPShareExtensionUserDefaultsPrimarySiteName)
            userDefaults.synchronize()
        }
    }
    
    /// Retrieves the WordPress.com OAuth Token, meant for Extension usage.
    ///
    /// - Returns: The OAuth Token, if any.
    ///
    class func retrieveShareExtensionToken() -> String? {
        guard let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(WPShareExtensionTokenKeychainUsername,
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
        guard let userDefaults = NSUserDefaults(suiteName: WPAppGroupName) else {
            return nil
        }
        
        guard let siteID = userDefaults.objectForKey(WPShareExtensionUserDefaultsPrimarySiteID) as? Int,
            let siteName = userDefaults.objectForKey(WPShareExtensionUserDefaultsPrimarySiteName) as? String else
        {
            return nil
        }
        
        return (siteID, siteName)
    }
}
