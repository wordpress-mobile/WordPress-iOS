import UIKit

class BlogToBlog32to33: NSEntityMigrationPolicy {
    override func createDestinationInstancesForSourceInstance(sourceBlog: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        DDLogSwift.logInfo("\(self.dynamicType) \(__FUNCTION__) (\(mapping.sourceEntityName) -> \(mapping.destinationEntityName))")

        let isWPcom = sourceBlog.valueForKeyPath("account.isWpcom") as? Bool ?? false
        let isJetpack = sourceBlog.valueForKey("isJetpack") as? Bool ?? false
        let isJetpackManage = isWPcom && isJetpack
        let isHostedAtWPcom = isWPcom && !isJetpack

        // 1. Create the destination Blog
        let destBlog = NSEntityDescription.insertNewObjectForEntityForName("Blog", inManagedObjectContext: manager.destinationContext) as! NSManagedObject

        // 2. Copy the attributes that don't need migration
        let keysToMigrate = [
            "apiKey", "blogID", "blogName", "currentThemeId", "geolocationEnabled",
            "icon", "isActivated", "isAdmin", "isMultiAuthor", "lastCommentsSync",
            "lastPagesSync", "lastPostsSync", "lastStatsSync", "lastUpdateWarning",
            "options", "postFormats", "url", "visible", "xmlrpc",
        ];
        destBlog.setValuesForKeysWithDictionary(sourceBlog.dictionaryWithValuesForKeys(keysToMigrate))

        // 3. Set the username to the account username, except for Jetpack managed blogs
        if !isJetpackManage {
            destBlog.setValue(sourceBlog.valueForKeyPath("account.username"), forKey: "username")
        } else {
            let xmlrpc = sourceBlog.valueForKey("xmlrpc") as? String ?? "<missing xmlrpc>"
            DDLogSwift.logWarn("Migrating Jetpack blog with unknown username: \(xmlrpc)")
        }

        // 4. Set isHostedAtWPcom
        destBlog.setValue(isHostedAtWPcom, forKey: "isHostedAtWPcom")

        // 5. Verify that account.xmlrpc matches blog.xmlrpc so that it can find its password
        if !isWPcom {
            let blogXmlrpc = sourceBlog.valueForKey("xmlrpc") as! String
            let accountXmlrpc = sourceBlog.valueForKeyPath("account.xmlrpc") as! String
            if blogXmlrpc != accountXmlrpc {
                DDLogSwift.logError("Blog's XML-RPC doesn't match Account's XML-RPC: \(blogXmlrpc) !== \(accountXmlrpc)")

                var error:NSError?
                let username = sourceBlog.valueForKeyPath("account.username") as! String
                let password = SFHFKeychainUtils.getPasswordForUsername(username, andServiceName: accountXmlrpc, error: &error)
                if let getError = error {
                    DDLogSwift.logError("Error getting password for \(accountXmlrpc): \(getError)")
                } else {
                    SFHFKeychainUtils.storeUsername(username, andPassword: password, forServiceName: blogXmlrpc, updateExisting: true, error: &error)
                    if let storeError = error {
                        DDLogSwift.logError("Error storing password for \(blogXmlrpc): \(storeError)")
                    }
                }
            }
        }

        // 6. Associate the source and destination instances
        manager.associateSourceInstance(sourceBlog, withDestinationInstance: destBlog, forEntityMapping: mapping)

        return true
    }
}
