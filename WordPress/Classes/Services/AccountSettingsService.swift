import Foundation
import Reachability

let AccountSettingsServiceChangeSaveFailedNotification = "AccountSettingsServiceChangeSaveFailed"

protocol AccountSettingsRemoteInterface {
    func getSettings(success success: AccountSettings -> Void, failure: ErrorType -> Void)
    func updateSetting(change: AccountSettingsChange, success: () -> Void, failure: ErrorType -> Void)
}

extension AccountSettingsRemote: AccountSettingsRemoteInterface {}

class AccountSettingsService {
    struct Defaults {
        static let stallTimeout = 4.0
        static let maxRetries = 3
        static let pollingInterval = 60.0
    }

    enum Notifications {
        static let accountSettingsChanged = "AccountSettingsServiceSettingsChanged"
        static let refreshStatusChanged = "AccountSettingsServiceRefreshStatusChanged"
    }

    let remote: AccountSettingsRemoteInterface
    let userID: Int

    var status: RefreshStatus = .Idle {
        didSet {
            stallTimer?.invalidate()
            stallTimer = nil
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.refreshStatusChanged, object: nil)
        }
    }
    var settings: AccountSettings? = nil {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.accountSettingsChanged, object: nil)
        }
    }

    var stallTimer: NSTimer?

    private let context = ContextManager.sharedInstance().mainContext

    convenience init(userID: Int, api: WordPressComApi) {
        let remote = AccountSettingsRemote.remoteWithApi(api)
        self.init(userID: userID, remote: remote)
    }

    init(userID: Int, remote: AccountSettingsRemoteInterface) {
        self.userID = userID
        self.remote = remote
        loadSettings()
    }

    func getSettingsAttempt(count count: Int = 0) {
        self.remote.getSettings(
            success: { settings in
                self.updateSettings(settings)
                self.status = .Idle
            },
            failure: { error in
                let error = error as NSError
                if error.domain == NSURLErrorDomain {
                    DDLogSwift.logError("Error refreshing settings (attempt \(count)): \(error)")
                } else {
                    DDLogSwift.logError("Error refreshing settings (unrecoverable): \(error)")
                }

                if error.domain == NSURLErrorDomain && count < Defaults.maxRetries {
                    self.getSettingsAttempt(count: count + 1)
                } else {
                    self.status = .Failed
                }
            }
        )
    }

    func refreshSettings() {
        guard status == .Idle || status == .Failed else {
            return
        }
        status = .Refreshing
        getSettingsAttempt()
        stallTimer = NSTimer.scheduledTimerWithTimeInterval(Defaults.stallTimeout,
                                                       target: self,
                                                       selector: #selector(AccountSettingsService.stallTimerFired),
                                                       userInfo: nil,
                                                       repeats: false)
    }

    @objc func stallTimerFired() {
        guard status == .Refreshing else {
            return
        }
        status = .Stalled
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

    func primarySiteNameForSettings(settings: AccountSettings) -> String? {
        let service = BlogService(managedObjectContext: context)
        let blog = service.blogByBlogId(settings.primarySiteID)

        return blog?.settings?.name
    }

    private func loadSettings() {
        settings = accountSettingsWithID(self.userID)
    }

    private func applyChange(change: AccountSettingsChange) throws -> AccountSettingsChange {
        guard let settings = managedAccountSettingsWithID(userID) else {
            DDLogSwift.logError("Tried to apply a change to nonexistent settings (ID: \(userID)")
            throw Errors.NotFound
        }

        let reverse = settings.applyChange(change)
        settings.account.applyChange(change)

        ContextManager.sharedInstance().saveContext(context)
        loadSettings()

        return reverse
    }

    private func updateSettings(settings: AccountSettings) {
        if let managedSettings = managedAccountSettingsWithID(userID) {
            managedSettings.updateWith(settings)
        } else {
            createAccountSettings(userID, settings: settings)
        }

        ContextManager.sharedInstance().saveContext(context)
        loadSettings()
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

        var errorMessage: String? {
            switch self {
            case Stalled:
                return NSLocalizedString("We are having trouble loading data", comment: "Error message displayed when a refresh is taking longer than usual. The refresh hasn't failed and it might still succeed")
            case Failed:
                return NSLocalizedString("We had trouble loading data", comment: "Error message displayed when a refresh failed")
            case Idle, Refreshing:
                return nil
            }
        }
    }
}
