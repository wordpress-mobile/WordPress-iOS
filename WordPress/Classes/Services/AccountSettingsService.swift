import Foundation
import Reachability
import RxCocoa
import RxSwift

let AccountSettingsServiceChangeSaveFailedNotification = "AccountSettingsServiceChangeSaveFailed"

protocol AccountSettingsRemoteInterface {
    var settings: Observable<AccountSettings> { get }
    func updateSetting(change: AccountSettingsChange, success: () -> Void, failure: ErrorType -> Void)
}

extension AccountSettingsRemote: AccountSettingsRemoteInterface {}

class AccountSettingsService {
    struct Defaults {
        static let stallTimeout = 4.0
        static let maxRetries = 3
        static let pollingInterval = 60.0
    }

    let remote: AccountSettingsRemoteInterface
    let userID: Int

    private let context = ContextManager.sharedInstance().mainContext

    init(userID: Int, api: WordPressComApi) {
        self.remote = AccountSettingsRemote.remoteWithApi(api)
        self.userID = userID
    }

    init(userID: Int, remote: AccountSettingsRemoteInterface) {
        self.userID = userID
        self.remote = remote
    }

    /// Emits a boolean value each time reachability changes for the internet connection.
    private let reachable = Reachability.internetConnection

    /// Performs a network refresh of settings and emits values with the refresh status.
    ///
    /// - When it's subscribed, it requests a refresh from the server
    /// - If a networking error happens it doesn't emit a new value and will retry the request.
    /// - If it reaches the maximum permitted number of retries it will emit an Error.
    /// - If an error not related to networking happens, it will emit an Error.
    /// - When the data is refreshed, it will emit an `.Idle` value and complete.
    lazy var remoteSettings: Observable<RefreshStatus> = {
        return self.remote.settings
            .map({ settings -> RefreshStatus in
                self.updateSettings(settings)
                return .Idle
            })
            .retryIf({ (count, error) in
                if error.domain == NSURLErrorDomain {
                    DDLogSwift.logError("Error refreshing settings (attempt \(count)): \(error)")
                } else {
                    DDLogSwift.logError("Error refreshing settings (unrecoverable): \(error)")
                }

                return error.domain == NSURLErrorDomain && count < Defaults.maxRetries
            })
            .startWith(.Refreshing)
    }()

    /// Emits one `.Stalled` value after a timeout and then completes
    let stalled = Observable<RefreshStatus>
            .just(.Stalled)
            .delaySubscription(Defaults.stallTimeout, scheduler: MainScheduler.instance)

    /// Performs a network refresh, emitting a `.Stalled` value if it's taking too long. It initially emits a `.Refreshing` value.
    /// - seealso: remoteSettings
    lazy private var request: Observable<RefreshStatus> = {
        let remoteSettings = self.remoteSettings
        let stalledSettings = Observable.of(self.stalled, remoteSettings)
            .merge()

        return remoteSettings
            .amb(stalledSettings)
    }()

    /// Emits values when the refresh status changes.
    ///
    /// On subscription, this will start refreshing settings, polling each minute, while there's an internet connection.
    /// Possible values:
    /// - `.Refreshing` when it starts getting remote data.
    /// - `.Stalled` when it's getting remote data and hasn't succeeded before `stallTimeout`.
    /// - `.Failed` when the request couldn't complete. It will retry after the polling interval.
    /// - `.Offline` when there is no internet connection.
    /// - `.Idle` when the request was successful and it's waiting for the polling interval.
    lazy var refresh: Observable<RefreshStatus> = {
        // Copy request to avoid capture of self in closure
        let request = self.request

        // Convert to a polling request
        let polling = Observable<Int>
            .interval(Defaults.pollingInterval, scheduler: MainScheduler.instance)
            .startWith(0)
            .flatMapLatest({ _ in request })

        // Enable only when reachable, otherwise emit .Offline
        return self.reachable.flatMapLatest({ reachable -> Observable<RefreshStatus> in
            if reachable {
                return polling
            } else {
                return Observable.just(.Offline)
            }
        })
    }()

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
