import Foundation
import RxCocoa
import RxSwift

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

    var settingsObserver: Observable<AccountSettings?> {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let notificationObserver = notificationCenter.rx_notification(NSManagedObjectContextDidSaveNotification, object: context)
        return notificationObserver.map(getSettings).startWith(getSettings())
    }

    private func getSettings(_: Any? = nil) -> AccountSettings? {
        return accountSettingsWithID(self.userID)
    }

    private func applyChange(change: AccountSettingsChange) throws -> AccountSettingsChange {
        guard let settings = managedAccountSettingsWithID(userID) else {
            DDLogSwift.logError("Tried to apply a change to nonexistent settings (ID: \(userID)")
            throw Errors.NotFound
        }

        let reverse = settings.applyChange(change)

        ContextManager.sharedInstance().saveContext(context)

        return reverse
    }

    private func updateSettings(settings: AccountSettings) {
        if let managedSettings = managedAccountSettingsWithID(userID) {
            managedSettings.updateWith(settings)
        } else {
            createAccountSettings(userID, settings: settings)
        }

        ContextManager.sharedInstance().saveContext(context)
    }

    private func accountSettingsWithID(userID: Int) -> AccountSettings? {
        return managedAccountSettingsWithID(userID).map(AccountSettings.init)
    }

    private func managedAccountSettingsWithID(userID: Int) -> ManagedAccountSettings? {
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
