import UIKit
import Foundation

class AccountToAccount21to22: NSEntityMigrationPolicy {
    override func beginEntityMapping(mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {

        // Note: 
        // NSEntityMigrationPolicy instance might not be the same all over. Let's use NSUserDefaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let unwrappedAccount = defaultWordPressAccount(manager.sourceContext) {
            let username = unwrappedAccount.valueForKey("username") as String;
            userDefaults.setValue(username, forKey: defaultDotcomUsernameKey)
        }
        
        userDefaults.removeObjectForKey(defaultDotcomKey)
        userDefaults.synchronize()
        
        return true
    }
    
    override func endEntityMapping(mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        // Load every WPAccount instance
        let context = manager.destinationContext
        let request = NSFetchRequest(entityName: "Account")
        var error: NSError?
        let accounts = context.executeFetchRequest(request, error: &error) as [NSManagedObject]?
        
        if accounts == nil {
            return true
        }

        // Assign the UUID's + Find the old defaultAccount (if any)
        let defaultUsername: String = NSUserDefaults.standardUserDefaults().stringForKey(defaultDotcomUsernameKey) ?? String()
        var defaultAccount: NSManagedObject?
        
        for account in accounts! {
            account.setValue(NSUUID().UUIDString, forKey: "uuid")
            
            if let username = account.valueForKey("username") as? String {
                if username == defaultUsername {
                    defaultAccount = account
                }
            }
        }
        
        // Set the defaultAccount (if any)
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if defaultAccount != nil {
            let uuid = defaultAccount!.valueForKey("uuid") as String
            userDefaults.setObject(uuid, forKey: defaultDotcomUUIDKey)
        }
        userDefaults.removeObjectForKey(defaultDotcomUsernameKey)
        userDefaults.synchronize()
        
        // At last: Execute the Default Account Fix (if needed)
//        accountService.fixDefaultAccountIfNeeded()
        
        return true
    }
    
    
    // MARK: - Private Helpers
    
    private func defaultWordPressAccount(context: NSManagedObjectContext) -> NSManagedObject? {
        let objectURL = NSUserDefaults.standardUserDefaults().URLForKey(defaultDotcomKey)
        if objectURL == nil {
            return nil
        }
        
        let objectID = context.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectURL!)
        if objectID == nil {
            return nil
        }
        
        var error: NSError?
        var defaultAccount = context.existingObjectWithID(objectID!, error: &error)
        
        if let unwrappedError = error {
            println(unwrappedError)
        }
        
        return defaultAccount
    }

    private let defaultDotcomUsernameKey    = "AccountDefaultAuthToken"
    private let defaultDotcomKey            = "AccountDefaultDotcom"
    private let defaultDotcomUUIDKey        = "AccountDefaultDotcomUUID"
}
