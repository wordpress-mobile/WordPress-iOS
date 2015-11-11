import UIKit
import Foundation
import WordPressComAnalytics

/**
    Note:
    This migration policy handles database migration from WPiOS 4.4 to 4.5.
    WPiOS 4.5 introduces two extra data models (22 and 23).
*/

class AccountToAccount22to23: NSEntityMigrationPolicy {
    
    private let defaultDotcomUsernameKey    = "AccountDefaultUsername"
    private let defaultDotcomKey            = "AccountDefaultDotcom"
    private let defaultDotcomUUIDKey        = "AccountDefaultDotcomUUID"
    
    override func beginEntityMapping(mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Note:
        // NSEntityMigrationPolicy instance might not be the same all over. Let's use NSUserDefaults
        let defaultAccount = legacyDefaultWordPressAccount(manager.sourceContext)
        if defaultAccount == nil {
            DDLogSwift.logError(">> Migration process couldn't locate a default WordPress.com account")
            return
        }
        
        let unwrappedAccount = defaultAccount!
        let username = unwrappedAccount.valueForKey("username") as? String
        let isDotCom = unwrappedAccount.valueForKey("isWpcom") as? Bool
        
        if username == nil || isDotCom == nil {
            DDLogSwift.logError(">> Migration process found an invalid default DotCom account")
        }
        
        if isDotCom! == true {
            let userDefaults = NSUserDefaults.standardUserDefaults()
            userDefaults.setValue(username!, forKey: defaultDotcomUsernameKey)
            userDefaults.synchronize()
            
            DDLogSwift.logWarn(">> Migration process matched [\(username!)] as the default WordPress.com account")
        } else {
            DDLogSwift.logError(">> Migration process found [\(username!)] as an invalid Default Account (Non DotCom!)")
        }
    }

    override func endEntityMapping(mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Load every WPAccount instance
        let context = manager.destinationContext
        let request = NSFetchRequest(entityName: "Account")
        let accounts = try context.executeFetchRequest(request) as! [NSManagedObject]
        
        if accounts.count == 0 {
            return
        }

        // Assign the UUID's + Find the old defaultAccount (if any)
        let defaultUsername: String = NSUserDefaults.standardUserDefaults().stringForKey(defaultDotcomUsernameKey) ?? String()
        var defaultAccount: NSManagedObject?

        for account in accounts {
            let uuid = NSUUID().UUIDString
            account.setValue(uuid, forKey: "uuid")
            
            let username = account.valueForKey("username") as? String
            let isDotCom = account.valueForKey("isWpcom") as? Bool
            
            if username == nil || isDotCom == nil {
                continue
            }
            
            if defaultUsername == username! && isDotCom! == true {
                defaultAccount = account
                DDLogSwift.logWarn(">> Assigned UUID [\(uuid)] to DEFAULT account [\(username!)]. IsDotCom [\(isDotCom!)]")
            } else {
                DDLogSwift.logWarn(">> Assigned UUID [\(uuid)] to account [\(username!)]. IsDotCom [\(isDotCom!)]")
            }
        }
        
        // Set the defaultAccount (if any)
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if defaultAccount != nil {
            let uuid = defaultAccount!.valueForKey("uuid") as! String
            userDefaults.setObject(uuid, forKey: defaultDotcomUUIDKey)
        }
        
        userDefaults.removeObjectForKey(defaultDotcomKey)
        userDefaults.removeObjectForKey(defaultDotcomUsernameKey)
        userDefaults.synchronize()
        
        // At last: Execute the Default Account Fix (if needed)
        fixDefaultAccountIfNeeded(context)
    }
    
    
    // MARK: - Private Helpers
    
    private func legacyDefaultWordPressAccount(context: NSManagedObjectContext) -> NSManagedObject? {
        let objectURL = NSUserDefaults.standardUserDefaults().URLForKey(defaultDotcomKey)
        if objectURL == nil {
            return nil
        }
        
        let objectID = context.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectURL!)
        if objectID == nil {
            return nil
        }
        
        var defaultAccount:NSManagedObject
        
        do {
            defaultAccount = try context.existingObjectWithID(objectID!)
        } catch {
            DDLogSwift.logError("\(error)")
            return nil
        }
        
        return defaultAccount
    }

    private func defaultWordPressAccount(context: NSManagedObjectContext) -> NSManagedObject? {
        let objectUUID = NSUserDefaults.standardUserDefaults().stringForKey(defaultDotcomUUIDKey)
        if objectUUID == nil {
            return nil
        }
        
        let request = NSFetchRequest(entityName: "Account")
        request.predicate = NSPredicate(format: "uuid == %@", objectUUID!)
        
        var accounts:[NSManagedObject]
        
        do {
            accounts = try context.executeFetchRequest(request) as! [NSManagedObject]
        } catch {
            DDLogSwift.logError("\(error)")
            return nil
        }
        
        return accounts.first
    }
    
    private func setDefaultWordPressAccount(account: NSManagedObject) {
        let uuid = account.valueForKey("uuid") as? String
        if uuid == nil {
            DDLogSwift.logError(">> Error setting the default WordPressDotCom Account")
            return
        }

        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(uuid, forKey: defaultDotcomUUIDKey)
        defaults.synchronize()
    }
    
    
    // MARK: Invalid Default WordPress Account Fix
    
    private func fixDefaultAccountIfNeeded(context: NSManagedObjectContext) {
        let oldDefaultAccount = defaultWordPressAccount(context)
        if oldDefaultAccount?.valueForKey("isWpcom")?.boolValue == true {
            DDLogSwift.logWarn("<< Default Account Fix not required!")
            return
        }
        
        DDLogSwift.logInfo(">> Proceeding with Default Account Fix")

        // Load all of the WPAccount instances
        let request         = NSFetchRequest(entityName: "Account")
        request.predicate   = NSPredicate(format: "isWpcom == true")

        var results:[NSManagedObject]
        
        do {
            results = try context.executeFetchRequest(request) as! [NSManagedObject]
        } catch {
            DDLogSwift.logError(">> Error while executing accounts fix: couldn't locate any WPAccount instances")
            return
        }
        
        // Attempt to infer the right default WordPress.com account
        let unwrappedAccounts = NSMutableArray(array: results)

        unwrappedAccounts.sortUsingDescriptors([
            NSSortDescriptor(key: "blogs.@count", ascending: false),
            NSSortDescriptor(key: "jetpackBlogs.@count", ascending: true)
        ])

        // Pick up the first account!
        if let defaultAccount = unwrappedAccounts.firstObject as? NSManagedObject {
            DDLogSwift.logInfo(">> Updating defaultAccount \(defaultAccount)")

            setDefaultWordPressAccount(defaultAccount)
            WPAnalytics.track(.PerformedCoreDataMigrationFixFor45)
        } else {
            DDLogSwift.logError(">> Error: couldn't update the Default WordPress.com account")
        }
    }
}
