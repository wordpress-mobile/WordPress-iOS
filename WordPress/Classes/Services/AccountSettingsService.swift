import Foundation
import Reachability
import WordPressKit

let AccountSettingsServiceChangeSaveFailedNotification = "AccountSettingsServiceChangeSaveFailed"

protocol AccountSettingsRemoteInterface {
    func getSettings(success: @escaping (AccountSettings) -> Void, failure: @escaping (Error) -> Void)
    func updateSetting(_ change: AccountSettingsChange, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
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

    var status: RefreshStatus = .idle {
        didSet {
            stallTimer?.invalidate()
            stallTimer = nil
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: Notifications.refreshStatusChanged), object: nil)
        }
    }
    var settings: AccountSettings? = nil {
        didSet {
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: Notifications.accountSettingsChanged), object: nil)
        }
    }

    var stallTimer: Timer?

    fileprivate let context = ContextManager.sharedInstance().mainContext

    convenience init(userID: Int, api: WordPressComRestApi) {
        let remote = AccountSettingsRemote.remoteWithApi(api)
        self.init(userID: userID, remote: remote)
    }

    init(userID: Int, remote: AccountSettingsRemoteInterface) {
        self.userID = userID
        self.remote = remote
        loadSettings()
    }

    func getSettingsAttempt(count: Int = 0) {
        self.remote.getSettings(
            success: { settings in
                self.updateSettings(settings)
                self.status = .idle
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
                    self.status = .failed
                }
            }
        )
    }

    func refreshSettings() {
        guard status == .idle || status == .failed else {
            return
        }
        status = .refreshing
        getSettingsAttempt()
        stallTimer = Timer.scheduledTimer(timeInterval: Defaults.stallTimeout,
                                                       target: self,
                                                       selector: #selector(AccountSettingsService.stallTimerFired),
                                                       userInfo: nil,
                                                       repeats: false)
    }

    @objc func stallTimerFired() {
        guard status == .refreshing else {
            return
        }
        status = .stalled
    }

    func saveChange(_ change: AccountSettingsChange) {
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
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: AccountSettingsServiceChangeSaveFailedNotification), object: error as NSError)
        }
    }

    func primarySiteNameForSettings(_ settings: AccountSettings) -> String? {
        let service = BlogService(managedObjectContext: context)
        let blog = service.blog(byBlogId: NSNumber(value: settings.primarySiteID))

        return blog?.settings?.name
    }

    fileprivate func loadSettings() {
        settings = accountSettingsWithID(self.userID)
    }

    @discardableResult fileprivate func applyChange(_ change: AccountSettingsChange) throws -> AccountSettingsChange {
        guard let settings = managedAccountSettingsWithID(userID) else {
            DDLogSwift.logError("Tried to apply a change to nonexistent settings (ID: \(userID)")
            throw Errors.notFound
        }

        let reverse = settings.applyChange(change)
        settings.account.applyChange(change)

        ContextManager.sharedInstance().save(context)
        loadSettings()

        return reverse
    }

    fileprivate func updateSettings(_ settings: AccountSettings) {
        if let managedSettings = managedAccountSettingsWithID(userID) {
            managedSettings.updateWith(settings)
        } else {
            createAccountSettings(userID, settings: settings)
        }

        ContextManager.sharedInstance().save(context)
        loadSettings()
    }

    fileprivate func accountSettingsWithID(_ userID: Int) -> AccountSettings? {
        return managedAccountSettingsWithID(userID).map(AccountSettings.init)
    }

    fileprivate func managedAccountSettingsWithID(_ userID: Int) -> ManagedAccountSettings? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedAccountSettings.entityName)
        request.predicate = NSPredicate(format: "account.userID = %d", userID)
        request.fetchLimit = 1
        guard let results = (try? context.fetch(request)) as? [ManagedAccountSettings] else {
            return nil
        }
        return results.first
    }

    fileprivate func createAccountSettings(_ userID: Int, settings: AccountSettings) {
        let accountService = AccountService(managedObjectContext: context)
        guard let account = accountService.findAccount(withUserID: NSNumber(value: userID)) else {
            DDLogSwift.logError("Tried to create settings for a missing account (ID: \(userID)): \(settings)")
            return
        }

        if let managedSettings = NSEntityDescription.insertNewObject(forEntityName: ManagedAccountSettings.entityName, into: context) as? ManagedAccountSettings {
            managedSettings.updateWith(settings)
            managedSettings.account = account
        }
    }

    enum Errors: Error {
        case notFound
    }

    enum RefreshStatus {
        case idle
        case refreshing
        case stalled
        case failed

        var errorMessage: String? {
            switch self {
            case .stalled:
                return NSLocalizedString("We are having trouble loading data", comment: "Error message displayed when a refresh is taking longer than usual. The refresh hasn't failed and it might still succeed")
            case .failed:
                return NSLocalizedString("We had trouble loading data", comment: "Error message displayed when a refresh failed")
            case .idle, .refreshing:
                return nil
            }
        }
    }
}
