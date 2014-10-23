import UIKit
import Foundation

class AccountToAccount21to22: NSEntityMigrationPolicy {
    override func beginEntityMapping(mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        var defaultAccount: NSManagedObject?
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let objectURL = userDefaults.URLForKey(defaultDotcomKey)
        if (objectURL != nil) {
            let objectID = manager.sourceContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectURL!)
            
            if (objectID != nil) {
                var error: NSError?
                defaultAccount = manager.sourceContext.existingObjectWithID(objectID!, error: &error)
                println(error)
            }
        }
        
        // Note: Why life has to be so complicated?
        // NSEntityMigrationPolicy instance might not be the same all over. We need to store in one safe spot the authToken,
        // so that when the migration sequence is over, we can pinpoint the old default account!
        if let unwrappedAccount = defaultAccount {
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

    private let defaultDotcomUsernameKey    = "AccountDefaultAuthToken"
    private let defaultDotcomKey            = "AccountDefaultDotcom"
    private let defaultDotcomUUIDKey        = "AccountDefaultDotcomUUID"
}
