import UIKit
import Foundation

class AccountToAccount21to22: NSEntityMigrationPolicy {
    override func beginEntityMapping(mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        var defaultAccount: WPAccount?
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let objectURL = userDefaults.URLForKey(defaultDotcomKey)
        if (objectURL != nil) {
            let objectID = manager.sourceContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectURL!)
            
            if (objectID != nil) {
                defaultAccount = manager.sourceContext.existingObjectWithID(objectID!, error: nil) as? WPAccount
            }
        }
        
        // Note: Why life has to be so complicated?
        // NSEntityMigrationPolicy instance might not be the same all over. We need to store in one safe spot the authToken,
        // so that when the migration sequence is over, we can pinpoint the old default account!
        if let unwrappedAccount = defaultAccount {
            userDefaults.setValue(unwrappedAccount.authToken, forKey: defaultAuthTokenKey)
        }
        
        userDefaults.removeObjectForKey(defaultDotcomKey)
        userDefaults.synchronize()
        
        return true
    }
    
    override func endEntityMapping(mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        // Load every WPAccount instance
        let context = manager.destinationContext
        let request = NSFetchRequest(entityName: "Account")
        let accounts = context.executeFetchRequest(request, error: nil) as? [WPAccount]
        
        if accounts == nil {
            return true
        }

        // Assign the UUID's + Find the old defaultAccount (if any)
        let defaultAuthToken: String = NSUserDefaults.standardUserDefaults().stringForKey(defaultAuthTokenKey) ?? String()
        var defaultAccount: WPAccount?
        
        for account in accounts! {
            account.uuid = NSUUID().UUIDString
            
            if account.authToken == defaultAuthToken {
                defaultAccount = account
            }
        }
        
        // Set the defaultAccount (if any)
        let accountService = AccountService(managedObjectContext: context)
        if let unwrappedDefaultAccount = defaultAccount {
            accountService.setDefaultWordPressComAccount(unwrappedDefaultAccount)
        }
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey(defaultAuthTokenKey)
        
        // At last: Execute the Default Account Fix (if needed)
        accountService.fixDefaultAccountIfNeeded()
        
        return true
    }

    private let defaultAuthTokenKey = "AccountDefaultAuthToken"
    private let defaultDotcomKey    = "AccountDefaultDotcom"
}
