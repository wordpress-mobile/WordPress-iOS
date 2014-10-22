import UIKit

class AccountToAccount21to22: NSEntityMigrationPolicy {
    override func beginEntityMapping(mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        var defaultAccount: WPAccount!
        
        let objectURL = NSUserDefaults.standardUserDefaults().URLForKey("AccountDefaultDotcom")
        if (objectURL != nil) {
            let objectID = manager.sourceContext.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(objectURL!)
            
            if (objectID != nil) {
                defaultAccount = manager.sourceContext.existingObjectWithID(objectID!, error: nil) as WPAccount
            }
        }
        
        // If a default exists, re-set it so a UUID is generated
        if defaultAccount != nil {
            defaultAccount.uuid = NSUUID().UUIDString
            manager.sourceContext.save(nil)
            
            let accountService = AccountService(managedObjectContext: manager.sourceContext)
            accountService.setDefaultWordPressComAccount(defaultAccount)
        }
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey("AccountDefaultDotcom")
        
        return true
    }
    
    override func createDestinationInstancesForSourceInstance(sInstance: NSManagedObject, entityMapping mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        
        let account = sInstance as WPAccount
        if (account.uuid != nil) {
            account.uuid = NSUUID().UUIDString
        }
        
        return true
    }
    
    override func endEntityMapping(mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        
        return true
    }
}
