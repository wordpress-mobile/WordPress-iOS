import Foundation

let AccountSettingsServiceChangeSaveFailedNotification = "AccountSettingsServiceChangeSaveFailed"

struct AccountSettingsService {
    let remote: AccountSettingsRemote
    let accountID: Int

    private let context = ContextManager.sharedInstance().mainContext

    init(accountID: Int, api: WordPressComApi) {
        self.remote = AccountSettingsRemote(api: api)
        self.accountID = accountID
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
        return AccountSettingsSubscription(accountID: accountID, context: context, changed: { (managedSettings) -> Void in
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
        guard let settings = accountSettingsWithID(accountID) else {
            DDLogSwift.logError("Tried to apply a change to nonexistent settings (ID: \(accountID)")
            throw Errors.NotFound
        }

        let reverse = settings.applyChange(change)

        ContextManager.sharedInstance().saveContext(context)

        return reverse
    }

    private func updateSettings(settings: AccountSettings) {
        if let managedSettings = accountSettingsWithID(accountID) {
            managedSettings.updateWith(settings)
        } else {
            createAccountSettings(accountID, settings: settings)
        }

        ContextManager.sharedInstance().saveContext(context)
    }

    private func accountSettingsWithID(accountID: Int) -> ManagedAccountSettings? {
        let request = NSFetchRequest(entityName: ManagedAccountSettings.entityName)
        request.predicate = NSPredicate(format: "account.userID = %d", accountID)
        request.fetchLimit = 1
        let results = (try? context.executeFetchRequest(request) as! [ManagedAccountSettings]) ?? []
        return results.first
    }

    private func createAccountSettings(accountID: Int, settings: AccountSettings) {
        let accountService = AccountService(managedObjectContext: context)
        guard let account = accountService.findAccountWithUserID(accountID) else {
            DDLogSwift.logError("Tried to create settings for a missing account (ID: \(accountID)): \(settings)")
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

    init(accountID: Int, context: NSManagedObjectContext, changed: ManagedAccountSettings? -> Void) {
        self.subscription = NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextDidSaveNotification, object: context, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            // FIXME: Inspect changed objects in notification instead of fetching for performance (@koke 2015-11-23)
            let account = self.fetchAccount(accountID, context: context)
            changed(account)
        }

        let initial = fetchAccount(accountID, context: context)
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            changed(initial)
        }
    }

    private func fetchAccount(accountID: Int, context: NSManagedObjectContext) -> ManagedAccountSettings? {
        let request = NSFetchRequest(entityName: ManagedAccountSettings.entityName)
        request.predicate = NSPredicate(format: "account.userID = %d", accountID)
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

