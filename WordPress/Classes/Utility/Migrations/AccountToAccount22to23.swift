import UIKit
import Foundation
import CocoaLumberjack
import WordPressShared

/// Note:
/// This migration policy handles database migration from WPiOS 4.4 to 4.5.
/// WPiOS 4.5 introduces two extra data models (22 and 23).
///
class AccountToAccount22to23: NSEntityMigrationPolicy {

    fileprivate let defaultDotcomUsernameKey    = "AccountDefaultUsername"
    fileprivate let defaultDotcomKey            = "AccountDefaultDotcom"
    fileprivate let defaultDotcomUUIDKey        = "AccountDefaultDotcomUUID"

    override func begin(_ mapping: NSEntityMapping, with manager: NSMigrationManager) throws {
        // Note:
        // NSEntityMigrationPolicy instance might not be the same all over. Let's use NSUserDefaults
        let defaultAccount = legacyDefaultWordPressAccount(manager.sourceContext)
        if defaultAccount == nil {
            DDLogError(">> Migration process couldn't locate a default WordPress.com account")
            return
        }

        let unwrappedAccount = defaultAccount!
        let username = unwrappedAccount.value(forKey: "username") as? String
        let isDotCom = unwrappedAccount.value(forKey: "isWpcom") as? Bool

        if username == nil || isDotCom == nil {
            DDLogError(">> Migration process found an invalid default DotCom account")
        }

        if isDotCom! == true {
            let userDefaults = UserDefaults.standard
            userDefaults.setValue(username!, forKey: defaultDotcomUsernameKey)

            DDLogWarn(">> Migration process matched [\(username!)] as the default WordPress.com account")
        } else {
            DDLogError(">> Migration process found [\(username!)] as an invalid Default Account (Non DotCom!)")
        }
    }

    override func end(_ mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Load every WPAccount instance
        let context = manager.destinationContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Account")
        let accounts = try context.fetch(request) as! [NSManagedObject]

        if accounts.count == 0 {
            return
        }

        // Assign the UUID's + Find the old defaultAccount (if any)
        let defaultUsername: String = UserDefaults.standard.string(forKey: defaultDotcomUsernameKey) ?? String()
        var defaultAccount: NSManagedObject?

        for account in accounts {
            let uuid = UUID().uuidString
            account.setValue(uuid, forKey: "uuid")

            let username = account.value(forKey: "username") as? String
            let isDotCom = account.value(forKey: "isWpcom") as? Bool

            if username == nil || isDotCom == nil {
                continue
            }

            if defaultUsername == username! && isDotCom! == true {
                defaultAccount = account
                DDLogWarn(">> Assigned UUID [\(uuid)] to DEFAULT account [\(username!)]. IsDotCom [\(isDotCom!)]")
            } else {
                DDLogWarn(">> Assigned UUID [\(uuid)] to account [\(username!)]. IsDotCom [\(isDotCom!)]")
            }
        }

        // Set the defaultAccount (if any)
        let userDefaults = UserDefaults.standard

        if defaultAccount != nil {
            let uuid = defaultAccount!.value(forKey: "uuid") as! String
            userDefaults.set(uuid, forKey: defaultDotcomUUIDKey)
        }

        userDefaults.removeObject(forKey: defaultDotcomKey)
        userDefaults.removeObject(forKey: defaultDotcomUsernameKey)

        // At last: Execute the Default Account Fix (if needed)
        fixDefaultAccountIfNeeded(context)
    }


    // MARK: - Private Helpers

    fileprivate func legacyDefaultWordPressAccount(_ context: NSManagedObjectContext) -> NSManagedObject? {
        let objectURL = UserDefaults.standard.url(forKey: defaultDotcomKey)
        if objectURL == nil {
            return nil
        }

        let objectID = context.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: objectURL!)
        if objectID == nil {
            return nil
        }

        var defaultAccount: NSManagedObject

        do {
            defaultAccount = try context.existingObject(with: objectID!)
        } catch {
            DDLogError("\(error)")
            return nil
        }

        return defaultAccount
    }

    fileprivate func defaultWordPressAccount(_ context: NSManagedObjectContext) -> NSManagedObject? {
        let objectUUID = UserDefaults.standard.string(forKey: defaultDotcomUUIDKey)
        if objectUUID == nil {
            return nil
        }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Account")
        request.predicate = NSPredicate(format: "uuid == %@", objectUUID!)

        var accounts: [NSManagedObject]

        do {
            accounts = try context.fetch(request) as! [NSManagedObject]
        } catch {
            DDLogError("\(error)")
            return nil
        }

        return accounts.first
    }

    fileprivate func setDefaultWordPressAccount(_ account: NSManagedObject) {
        let uuid = account.value(forKey: "uuid") as? String
        if uuid == nil {
            DDLogError(">> Error setting the default WordPressDotCom Account")
            return
        }

        let defaults = UserDefaults.standard
        defaults.set(uuid, forKey: defaultDotcomUUIDKey)
    }


    // MARK: Invalid Default WordPress Account Fix

    fileprivate func fixDefaultAccountIfNeeded(_ context: NSManagedObjectContext) {
        let oldDefaultAccount = defaultWordPressAccount(context)
        if let isWpcom = oldDefaultAccount?.value(forKey: "isWpcom") as? NSNumber, isWpcom.boolValue == true {
            DDLogWarn("<< Default Account Fix not required!")
            return
        }

        DDLogInfo(">> Proceeding with Default Account Fix")

        // Load all of the WPAccount instances
        let request         = NSFetchRequest<NSFetchRequestResult>(entityName: "Account")
        request.predicate   = NSPredicate(format: "isWpcom == true")

        var results: [NSManagedObject]

        do {
            results = try context.fetch(request) as! [NSManagedObject]
        } catch {
            DDLogError(">> Error while executing accounts fix: couldn't locate any WPAccount instances")
            return
        }

        // Attempt to infer the right default WordPress.com account
        let unwrappedAccounts = NSMutableArray(array: results)

        unwrappedAccounts.sort(using: [
            NSSortDescriptor(key: "blogs.@count", ascending: false),
            NSSortDescriptor(key: "jetpackBlogs.@count", ascending: true)
        ])

        // Pick up the first account!
        if let defaultAccount = unwrappedAccounts.firstObject as? NSManagedObject {
            DDLogInfo(">> Updating defaultAccount \(defaultAccount)")

            setDefaultWordPressAccount(defaultAccount)
            WPAnalytics.track(.performedCoreDataMigrationFixFor45)
        } else {
            DDLogError(">> Error: couldn't update the Default WordPress.com account")
        }
    }
}
