import UIKit
import CocoaLumberjack

class BlogToBlog32to33: NSEntityMigrationPolicy {

    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        DDLogInfo("\(type(of: self)) \(#function) \(String(describing: mapping.sourceEntityName)) -> \(String(describing: mapping.destinationEntityName)))")

        let isWPcom = sInstance.value(forKeyPath: "account.isWpcom") as? Bool ?? false
        let isJetpack = sInstance.value(forKey: "isJetpack") as? Bool ?? false
        let isJetpackManage = isWPcom && isJetpack
        let isHostedAtWPcom = isWPcom && !isJetpack

        // 1. Create the destination Blog
        let destBlog = NSEntityDescription.insertNewObject(forEntityName: "Blog", into: manager.destinationContext)

        // 2. Copy the attributes that don't need migration
        let keysToMigrate = [
            "apiKey", "blogID", "blogName", "currentThemeId", "geolocationEnabled",
            "icon", "isActivated", "isAdmin", "isMultiAuthor", "lastCommentsSync",
            "lastPagesSync", "lastPostsSync", "lastStatsSync", "lastUpdateWarning",
            "options", "postFormats", "url", "visible", "xmlrpc",
        ]
        destBlog.setValuesForKeys(sInstance.dictionaryWithValues(forKeys: keysToMigrate))

        // 3. Set the username to the account username, except for Jetpack managed blogs
        if !isJetpackManage {
            destBlog.setValue(sInstance.value(forKeyPath: "account.username"), forKey: "username")
        } else {
            let xmlrpc = sInstance.value(forKey: "xmlrpc") as? String ?? "<missing xmlrpc>"
            DDLogWarn("Migrating Jetpack blog with unknown username: \(xmlrpc)")
        }

        // 4. Set isHostedAtWPcom
        destBlog.setValue(isHostedAtWPcom, forKey: "isHostedAtWPcom")

        // 5. Verify that account.xmlrpc matches blog.xmlrpc so that it can find its password
        if !isWPcom {
            let blogXmlrpc = sInstance.value(forKey: "xmlrpc") as! String
            let accountXmlrpc = sInstance.value(forKeyPath: "account.xmlrpc") as! String
            if blogXmlrpc != accountXmlrpc {
                DDLogError("Blog's XML-RPC doesn't match Account's XML-RPC: \(blogXmlrpc) !== \(accountXmlrpc)")

                let username = sInstance.value(forKeyPath: "account.username") as! String

                do {
                    let password = try SFHFKeychainUtils.getPasswordForUsername(username, andServiceName: accountXmlrpc)
                    try SFHFKeychainUtils.storeUsername(username, andPassword: password, forServiceName: blogXmlrpc, updateExisting: true)
                } catch {
                    DDLogError("Error getting/saving password for \(accountXmlrpc): \(error)")
                }
            }
        }

        // 6. Associate the source and destination instances
        manager.associate(sourceInstance: sInstance, withDestinationInstance: destBlog, for: mapping)
    }
}
