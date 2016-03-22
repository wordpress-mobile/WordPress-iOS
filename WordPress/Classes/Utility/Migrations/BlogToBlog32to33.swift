import UIKit

class BlogToBlog32to33: NSEntityMigrationPolicy {
    
    override func createDestinationInstancesForSourceInstance(sInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        DDLogSwift.logInfo("\(self.dynamicType) \(#function) \(mapping.sourceEntityName) -> \(mapping.destinationEntityName))")

        let isWPcom = sInstance.valueForKeyPath("account.isWpcom") as? Bool ?? false
        let isJetpack = sInstance.valueForKey("isJetpack") as? Bool ?? false
        let isJetpackManage = isWPcom && isJetpack
        let isHostedAtWPcom = isWPcom && !isJetpack

        // 1. Create the destination Blog
        let destBlog = NSEntityDescription.insertNewObjectForEntityForName("Blog", inManagedObjectContext: manager.destinationContext)

        // 2. Copy the attributes that don't need migration
        let keysToMigrate = [
            "apiKey", "blogID", "blogName", "currentThemeId", "geolocationEnabled",
            "icon", "isActivated", "isAdmin", "isMultiAuthor", "lastCommentsSync",
            "lastPagesSync", "lastPostsSync", "lastStatsSync", "lastUpdateWarning",
            "options", "postFormats", "url", "visible", "xmlrpc",
        ];
        destBlog.setValuesForKeysWithDictionary(sInstance.dictionaryWithValuesForKeys(keysToMigrate))

        // 3. Set the username to the account username, except for Jetpack managed blogs
        if !isJetpackManage {
            destBlog.setValue(sInstance.valueForKeyPath("account.username"), forKey: "username")
        } else {
            let xmlrpc = sInstance.valueForKey("xmlrpc") as? String ?? "<missing xmlrpc>"
            DDLogSwift.logWarn("Migrating Jetpack blog with unknown username: \(xmlrpc)")
        }

        // 4. Set isHostedAtWPcom
        destBlog.setValue(isHostedAtWPcom, forKey: "isHostedAtWPcom")

        // 5. Verify that account.xmlrpc matches blog.xmlrpc so that it can find its password
        if !isWPcom {
            let blogXmlrpc = sInstance.valueForKey("xmlrpc") as! String
            let accountXmlrpc = sInstance.valueForKeyPath("account.xmlrpc") as! String
            if blogXmlrpc != accountXmlrpc {
                DDLogSwift.logError("Blog's XML-RPC doesn't match Account's XML-RPC: \(blogXmlrpc) !== \(accountXmlrpc)")

                let username = sInstance.valueForKeyPath("account.username") as! String
                
                do {
                    let password = try SFHFKeychainUtils.getPasswordForUsername(username, andServiceName: accountXmlrpc)
                    try SFHFKeychainUtils.storeUsername(username, andPassword: password, forServiceName: blogXmlrpc, updateExisting: true)
                } catch {
                    DDLogSwift.logError("Error getting/saving password for \(accountXmlrpc): \(error)")
                }
            }
        }

        // 6. Associate the source and destination instances
        manager.associateSourceInstance(sInstance, withDestinationInstance: destBlog, forEntityMapping: mapping)
    }
}
