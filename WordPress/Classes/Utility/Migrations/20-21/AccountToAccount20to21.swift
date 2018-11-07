import UIKit
import Foundation
import CocoaLumberjack


/// Note:
/// This migration policy handles database migration from WPiOS 4.3 to 4.4
///
class AccountToAccount20to21: NSEntityMigrationPolicy {

    fileprivate let defaultDotcomUsernameKey    = "defaultDotcomUsernameKey"
    fileprivate let defaultDotcomKey            = "AccountDefaultDotcom"


    override func begin(_ mapping: NSEntityMapping, with manager: NSMigrationManager) throws {
        // Note:
        // NSEntityMigrationPolicy instance might not be the same all over. Let's use NSUserDefaults
        if let unwrappedAccount = legacyDefaultWordPressAccount(manager.sourceContext) {
            let username = unwrappedAccount.value(forKey: "username") as! String

            let userDefaults = UserDefaults.standard
            userDefaults.setValue(username, forKey: defaultDotcomUsernameKey)

            DDLogWarn(">> Migration process matched [\(username)] as the default WordPress.com account")
        } else {
            DDLogError(">> Migration process couldn't locate a default WordPress.com account")
        }
    }

    override func end(_ mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // Load the default username
        let userDefaults = UserDefaults.standard
        let defaultUsername = userDefaults.string(forKey: defaultDotcomUsernameKey) ?? String()

        // Find the Default Account
        let context = manager.destinationContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Account")
        let predicate = NSPredicate(format: "username == %@ AND isWpcom == true", defaultUsername)
        request.predicate = predicate

        let accounts = try context.fetch(request) as! [NSManagedObject]

        if let defaultAccount = accounts.first {
            setLegacyDefaultWordPressAccount(defaultAccount)
            DDLogInfo(">> Migration process located default account with username [\(defaultUsername)\")")
        } else {
            DDLogError(">> Migration process failed to locate default account)")
        }

        // Cleanup!
        userDefaults.removeObject(forKey: defaultDotcomUsernameKey)
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
            try defaultAccount = context.existingObject(with: objectID!)
        } catch {
            DDLogError("\(error)")
            return nil
        }

        return defaultAccount
    }

    fileprivate func setLegacyDefaultWordPressAccount(_ account: NSManagedObject) {

        // Just in case
        if account.objectID.isTemporaryID {
            do {
                try account.managedObjectContext?.obtainPermanentIDs(for: [account])
            } catch {}
        }

        let accountURL = account.objectID.uriRepresentation()

        let defaults = UserDefaults.standard
        defaults.set(accountURL, forKey: defaultDotcomKey)
    }
}
