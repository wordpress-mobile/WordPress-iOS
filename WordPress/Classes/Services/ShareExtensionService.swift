import Foundation

@objc
public class ShareExtensionService: NSObject {
    class func configureShareExtension(oauth2Token: String, defaultSiteID: Int, defaultSiteName: String) {
        do {
            try SFHFKeychainUtils.storeUsername(WPAppOAuth2TokenKeychainUsername,
                andPassword: oauth2Token,
                forServiceName: WPAppOAuth2TokenKeychainServiceName,
                accessGroup: WPAppGroupName,
                updateExisting: true)
        } catch {
            print("Error while saving Share Extension OAuth bearer token: \(error)")
        }
        
        if let userDefaults = NSUserDefaults(suiteName: WPAppGroupName) {
            userDefaults.setObject(defaultSiteID, forKey: WPShareUserDefaultsPrimarySiteID)
            userDefaults.setObject(defaultSiteName, forKey: WPShareUserDefaultsPrimarySiteName)
            userDefaults.synchronize()
        }
    }
    
    class func removeShareExtensionConfiguration() {
        do {
            try SFHFKeychainUtils.deleteItemForUsername(WPAppOAuth2TokenKeychainUsername,
                andServiceName: WPAppOAuth2TokenKeychainServiceName,
                accessGroup: WPAppGroupName)
        } catch {
            print("Error while removing Share Extension OAuth2 bearer token: \(error)")
        }
        
        if let userDefaults = NSUserDefaults(suiteName: WPAppGroupName) {
            userDefaults.removeObjectForKey(WPShareUserDefaultsPrimarySiteID)
            userDefaults.removeObjectForKey(WPShareUserDefaultsPrimarySiteName)
            userDefaults.synchronize()
        }
    }
    
    class func retrieveShareExtensionConfiguration() -> (oauth2Token: String, defaultSiteID: Int, defaultSiteName: String)? {
        guard let oauth2Token = try? SFHFKeychainUtils.getPasswordForUsername(WPAppOAuth2TokenKeychainUsername, andServiceName: WPAppOAuth2TokenKeychainServiceName, accessGroup: WPAppGroupName),
            let userDefaults = NSUserDefaults(suiteName: WPAppGroupName) else {
                return nil
        }
        
        guard let primarySiteID = userDefaults.objectForKey(WPShareUserDefaultsPrimarySiteID) as? Int,
            let primarySiteName = userDefaults.objectForKey(WPShareUserDefaultsPrimarySiteName) as? String else {
                return nil
        }
        
        return (oauth2Token, primarySiteID, primarySiteName)
    }
}