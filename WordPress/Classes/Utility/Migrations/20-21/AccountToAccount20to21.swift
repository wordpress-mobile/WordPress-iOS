import UIKit
import Foundation

class AccountToAccount20to21: NSEntityMigrationPolicy {
    override func beginEntityMapping(mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {

        // Note: 
        // NSEntityMigrationPolicy instance might not be the same all over. Let's use NSUserDefaults
        if let unwrappedAccount = legacyDefaultWordPressAccount(manager.sourceContext) {
            let username = unwrappedAccount.valueForKey("username") as String
            
            let userDefaults = NSUserDefaults.standardUserDefaults()
            userDefaults.setValue(username, forKey: defaultDotcomUsernameKey)
            userDefaults.synchronize()
            
            println(">> Migration process matched [\(username)] as the default WordPress.com account")
        } else {
            println(">> Migration process couldn't locate a default WordPress.com account")
        }
        
        return true
    }
    
    override func endEntityMapping(mapping: NSEntityMapping, manager: NSMigrationManager, error: NSErrorPointer) -> Bool {
        // Load the default username
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let defaultUsername = userDefaults.stringForKey(defaultDotcomUsernameKey) ?? String()
        
        // Find the Default Account
        let context = manager.destinationContext
        let request = NSFetchRequest(entityName: "Account")
        let predicate = NSPredicate(format: "username == %@ AND isWpcom == true", defaultUsername)
        request.predicate = predicate
        
        let accounts = context.executeFetchRequest(request, error: nil) as [NSManagedObject]?
        
        if let defaultAccount = accounts?.first {
            setLegacyDefaultWordPressAccount(defaultAccount)
        }

        // Cleanup!
        userDefaults.removeObjectForKey(defaultDotcomUsernameKey)
        userDefaults.synchronize()
        
        return true
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
        
        var error: NSError?
        var defaultAccount = context.existingObjectWithID(objectID!, error: &error)
        
        if let unwrappedError = error {
            println(unwrappedError)
        }
        
        return defaultAccount
    }
    
    private func setLegacyDefaultWordPressAccount(account: NSManagedObject) {

        // Just in case
        if account.objectID.temporaryID {
            account.managedObjectContext?.obtainPermanentIDsForObjects([account], error: nil)
        }

        let accountURL = account.objectID.URIRepresentation()
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setURL(accountURL, forKey: defaultDotcomKey)
        defaults.synchronize()
    }
    
    
    private let defaultDotcomUsernameKey    = "defaultDotcomUsernameKey"
    private let defaultDotcomKey            = "AccountDefaultDotcom"
}
