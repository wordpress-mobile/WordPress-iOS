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

    var testScheduler: SchedulerType? = nil
    private var scheduler: SchedulerType {
        return testScheduler ?? MainScheduler.instance
    }

    convenience init(userID: Int, api: WordPressComApi) {
        let remote = AccountSettingsRemote.remoteWithApi(api)
        self.init(userID: userID, remote: remote)
    }

    init(userID: Int, remote: AccountSettingsRemoteInterface) {
        self.userID = userID
        self.remote = remote
    }

    var testReachability: Observable<Bool>? = nil
    /// Emits a boolean value each time reachability changes for the internet connection.
    private lazy var reachable: Observable<Bool> = {
        return self.testReachability ?? Reachability.internetConnection
    }()

    /// Performs a network refresh of settings and emits values with the refresh status.
    ///
    /// - When it's subscribed, it requests a refresh from the server
    /// - If a networking error happens it doesn't emit a new value and will retry the request.
    /// - If it reaches the maximum permitted number of retries it will emit an Error.
    /// - If an error not related to networking happens, it will emit an Error.
    /// - When the data is refreshed, it will emit an `.Idle` value and complete.
    private lazy var remoteSettings: Observable<RefreshStatus> = {
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
    }()

    /// Emits one `.Stalled` value after a timeout and then completes
    private lazy var stalled: Observable<RefreshStatus> = {
        return Observable<RefreshStatus>
            .just(.Stalled)
            .delaySubscription(Defaults.stallTimeout, scheduler: self.scheduler)
    }()

    /// Performs a network refresh of settings and emits values with the refresh status.
    ///
    /// - When it's subscribed, it requests a refresh from the server
    /// - If it takes more than `stallTimeout` to complete, it will emit a `.Stalled` value and continue waiting for the request to finish.
    /// - If a networking error happens it doesn't emit a new value and will retry the request.
    /// - If it reaches the maximum permitted number of retries it will emit an Error.
    /// - If an error not related to networking happens, it will emit an Error.
    /// - When the data is refreshed, it will emit an `.Idle` value and complete.
    lazy private(set) var request: Observable<RefreshStatus> = {
        let remoteSettings = self.remoteSettings.shareReplayLatestWhileConnected()
        let stalledSettings = Observable.of(self.stalled, remoteSettings)
            .merge()

        return remoteSettings
            .amb(stalledSettings)
            .startWith(.Refreshing)
    }()

    /// Emits values when the refresh status changes.
    ///
    /// On subscription, this will start refreshing settings, polling each minute, while there's an internet connection.
    /// Possible values:
    /// - `.Refreshing` when it starts getting remote data.
    /// - `.Stalled` when it's getting remote data and hasn't succeeded before `stallTimeout`.
    /// - `.Offline` when there is no internet connection.
    /// - `.Idle` when the request was successful and it's waiting for the polling interval.
    /// - An error when the request couldn't complete. It will stop retrying.
    lazy var refresh: Observable<RefreshStatus> = {
        // Copy request to avoid capture of self in closure
        let request = self.request

        // Convert to a polling request
        let polling = Observable<Int>
            .interval(Defaults.pollingInterval, scheduler: self.scheduler)
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

    /// Emits a value when the settings for the associated account change.
    var settings: Observable<AccountSettings?> {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let notificationObserver = notificationCenter.rx_notification(NSManagedObjectContextDidSaveNotification, object: context)
        // This was the simplest implementation. If performance is an issue, we could try
        // adding `distinctUntilChanged` or `filter` on the notification userInfo and only
        // emit if the changed objects include the observed account.
        return notificationObserver.map(getSettings).startWith(getSettings())
    }

    func primarySiteNameForSettings(settings: AccountSettings) -> String? {        
        let service = BlogService(managedObjectContext: context)
        let blog = service.blogByBlogId(settings.primarySiteID)
        
        return blog?.settings?.name
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
