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

    var refresh: Observable<RefreshStatus> {
        let remote = self.remote
        let stalledTimeout = 4.0

        let refresh: Observable<RefreshStatus> = remote.settings()
            .map { settings in
                self.updateSettings(settings)
                return .Idle
            }
            .share()

        let stalled: Observable<RefreshStatus> = Observable<Int>
            .timer(stalledTimeout, scheduler: MainScheduler.instance)
            .map({ _ in .Stalled })

        return Observable.of(refresh, stalled)
            .merge()
            .startWith(.Refreshing)
            .distinctUntilChanged()
            .takeUntil(refresh)
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
        settings.account.applyChange(change)

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

    enum RefreshStatus {
        case Idle
        case Refreshing
        case Stalled
        case Failed
        case Offline

        var errorMessage: String? {
            switch self {
            case Stalled:
                return NSLocalizedString("We are having trouble loading data", comment: "Error message displayed when a refresh is taking longer than usual. The refresh hasn't failed and it might still succeed")
            case Failed:
                return NSLocalizedString("We had trouble loading data", comment: "Error message displayed when a refresh failed")
            case Offline:
                return NSLocalizedString("You are currently offline", comment: "Error message displayed when the app can't connect to the API servers")
            case Idle, Refreshing:
                return nil
            }
        }
    }
}
