import Foundation

let AccountSettingsServiceChangeSaveFailedNotification = "AccountSettingsServiceChangeSaveFailed"

struct AccountSettingsService {
    let remote: AccountSettingsRemote
    let userID: Int

    private let context = ContextManager.sharedInstance().mainContext

    init(userID: Int, api: WordPressComApi) {
        self.remote = AccountSettingsRemote(api: api)
        self.userID = userID
    }

    func refreshSettings(completion: (Bool) -> Void) {
        remote.getSettings(
            success: {
                (settings) -> Void in

                self.updateSettings(settings)
                completion(true)
            }, failure: {
                (error) -> Void in

                DDLogSwift.logError(String(error))
                completion(false)
        })
    }

    func subscribeSettings(next: AccountSettings? -> Void) -> AccountSettingsSubscription {
        return AccountSettingsSubscription(userID: userID, context: context, changed: { (managedSettings) -> Void in
            let settings = managedSettings.map({ AccountSettings(managed: $0) })
            next(settings)
        })
    }

    func saveChange(change: AccountSettingsChange) {
        guard let reverse = try? applyChange(change) else {
            return
        }
        remote.updateSetting(change, success: { }) { (error) -> Void in
            do {
                // revert change
                try self.applyChange(reverse)
            } catch {
                DDLogSwift.logError("Error reverting change \(error)")
            }
            DDLogSwift.logError("Error saving account settings change \(error)")
            // TODO: show/return error to the user (@koke 2015-11-24)
            // What should be showing the error? Let's post a notification for now so something else can handle it
            NSNotificationCenter.defaultCenter().postNotificationName(AccountSettingsServiceChangeSaveFailedNotification, object: error as NSError)
        }
    }

    private func applyChange(change: AccountSettingsChange) throws -> AccountSettingsChange {
        guard let settings = accountSettingsWithID(userID) else {
            DDLogSwift.logError("Tried to apply a change to nonexistent settings (ID: \(userID)")
            throw Errors.NotFound
        }

        let reverse = settings.applyChange(change)
        settings.account.applyChange(change)

        ContextManager.sharedInstance().saveContext(context)

        return reverse
    }

    private func updateSettings(settings: AccountSettings) {
        if let managedSettings = accountSettingsWithID(userID) {
            managedSettings.updateWith(settings)
        } else {
            createAccountSettings(userID, settings: settings)
        }

        ContextManager.sharedInstance().saveContext(context)
    }

    private func accountSettingsWithID(userID: Int) -> ManagedAccountSettings? {
        let request = NSFetchRequest(entityName: ManagedAccountSettings.entityName)
        request.predicate = NSPredicate(format: "account.userID = %d", userID)
        request.fetchLimit = 1
        let results = (try? context.executeFetchRequest(request) as! [ManagedAccountSettings]) ?? []
        return results.first
    }

    private func createAccountSettings(userID: Int, settings: AccountSettings) {
        let accountService = AccountService(managedObjectContext: context)
        guard let account = accountService.findAccountWithUserID(userID) else {
            DDLogSwift.logError("Tried to create settings for a missing account (ID: \(userID)): \(settings)")
            return
        }

        let managedSettings = NSEntityDescription.insertNewObjectForEntityForName(ManagedAccountSettings.entityName, inManagedObjectContext: context) as! ManagedAccountSettings
        managedSettings.updateWith(settings)
        managedSettings.account = account
    }

    enum Errors: ErrorType {
        case NotFound
    }
}

class AccountSettingsSubscription {
    private var subscription: NSObjectProtocol? = nil

    init(userID: Int, context: NSManagedObjectContext, changed: ManagedAccountSettings? -> Void) {
        subscription = NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextDidSaveNotification, object: context, queue: NSOperationQueue.mainQueue()) {
            [unowned self]
            notification in
            // FIXME: Inspect changed objects in notification instead of fetching for performance (@koke 2015-11-23)
            let account = self.fetchAccount(userID, context: context)
            changed(account)
        }

        let initial = fetchAccount(userID, context: context)
        dispatch_async(dispatch_get_main_queue()) {
            changed(initial)
        }
    }

    private func fetchAccount(userID: Int, context: NSManagedObjectContext) -> ManagedAccountSettings? {
        let request = NSFetchRequest(entityName: ManagedAccountSettings.entityName)
        request.predicate = NSPredicate(format: "account.userID = %d", userID)
        request.fetchLimit = 1
        let results = (try? context.executeFetchRequest(request) as! [ManagedAccountSettings]) ?? []
        return results.first
    }

    deinit {
        if let subscription = subscription {
            NSNotificationCenter.defaultCenter().removeObserver(subscription)
        }
    }
}

