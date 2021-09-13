import Foundation
import CocoaLumberjack
import Reachability
import WordPressKit

extension NSNotification.Name {
    static let AccountSettingsServiceChangeSaveFailed = NSNotification.Name(rawValue: "AccountSettingsServiceChangeSaveFailed")
    static let AccountSettingsChanged = NSNotification.Name(rawValue: "AccountSettingsServiceSettingsChanged")
    static let AccountSettingsServiceRefreshStatusChanged = NSNotification.Name(rawValue: "AccountSettingsServiceRefreshStatusChanged")
}

@objc
extension NSNotification {
    public static let AccountSettingsChanged = NSNotification.Name.AccountSettingsChanged
}

protocol AccountSettingsRemoteInterface {
    func getSettings(success: @escaping (AccountSettings) -> Void, failure: @escaping (Error) -> Void)
    func updateSetting(_ change: AccountSettingsChange, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func changeUsername(to username: String, success: @escaping () -> Void, failure: @escaping () -> Void)
    func suggestUsernames(base: String, finished: @escaping ([String]) -> Void)
    func updatePassword(_ password: String, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func closeAccount(success: @escaping () -> Void, failure: @escaping (Error) -> Void)
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

    var status: RefreshStatus = .idle {
        didSet {
            stallTimer?.invalidate()
            stallTimer = nil
            NotificationCenter.default.post(name: NSNotification.Name.AccountSettingsServiceRefreshStatusChanged, object: nil)
        }
    }
    var settings: AccountSettings? = nil {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name.AccountSettingsChanged, object: nil)
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
                    DDLogError("Error refreshing settings (attempt \(count)): \(error)")
                } else {
                    DDLogError("Error refreshing settings (unrecoverable): \(error)")
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

    func saveChange(_ change: AccountSettingsChange, finished: ((Bool) -> ())? = nil) {
        guard let reverse = try? applyChange(change) else {
            return
        }
        remote.updateSetting(change, success: {
            finished?(true)
        }) { (error) -> Void in
            do {
                // revert change
                try self.applyChange(reverse)
            } catch {
                DDLogError("Error reverting change \(error)")
            }
            DDLogError("Error saving account settings change \(error)")

            NotificationCenter.default.post(name: NSNotification.Name.AccountSettingsServiceChangeSaveFailed, object: self, userInfo: [NSUnderlyingErrorKey: error])

            finished?(false)
        }
    }

    func updateDisplayName(_ displayName: String, finished: ((Bool, Error?) -> ())? = nil) {
        remote.updateSetting(.displayName(displayName), success: {
            finished?(true, nil)
        }) { error in
            DDLogError("Error saving account settings change \(error)")
            NotificationCenter.default.post(name: NSNotification.Name.AccountSettingsServiceChangeSaveFailed, object: self, userInfo: [NSUnderlyingErrorKey: error])

            finished?(false, error)
        }
    }

    func updatePassword(_ password: String, finished: ((Bool, Error?) -> ())? = nil) {
        remote.updatePassword(password, success: {
            finished?(true, nil)
        }) { (error) -> Void in
            DDLogError("Error saving account settings change \(error)")
            NotificationCenter.default.post(name: NSNotification.Name.AccountSettingsServiceChangeSaveFailed, object: error as NSError)

            finished?(false, error)
        }
    }

    func closeAccount(result: @escaping (Result<Void, Error>) -> Void) {
        remote.closeAccount {
            result(.success(()))
        } failure: { error in
            result(.failure(error))
        }
    }

    func primarySiteNameForSettings(_ settings: AccountSettings) -> String? {
        return try? Blog.lookup(withID: settings.primarySiteID, in: context)?.settings?.name
    }

    /// Change the current user's username
    ///
    /// - Parameters:
    ///   - username: the new username
    ///   - success: block for success
    ///   - failure: block for failure
    public func changeUsername(to username: String, success: @escaping () -> Void, failure: @escaping () -> Void) {
        remote.changeUsername(to: username, success: success, failure: success)
    }

    public func suggestUsernames(base: String, finished: @escaping ([String]) -> Void) {
        remote.suggestUsernames(base: base, finished: finished)
    }

    fileprivate func loadSettings() {
        settings = accountSettingsWithID(self.userID)
    }

    @discardableResult fileprivate func applyChange(_ change: AccountSettingsChange) throws -> AccountSettingsChange {
        guard let settings = managedAccountSettingsWithID(userID) else {
            DDLogError("Tried to apply a change to nonexistent settings (ID: \(userID)")
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

        guard let managedAccount = managedAccountSettingsWithID(userID) else {
            return nil
        }

        return AccountSettings.init(managed: managedAccount)
    }

    fileprivate func managedAccountSettingsWithID(_ userID: Int) -> ManagedAccountSettings? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedAccountSettings.entityName())
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
            DDLogError("Tried to create settings for a missing account (ID: \(userID)): \(settings)")
            return
        }

        if let managedSettings = NSEntityDescription.insertNewObject(forEntityName: ManagedAccountSettings.entityName(), into: context) as? ManagedAccountSettings {
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

struct AccountSettingsHelper {
    let accountService: AccountService

    init(accountService: AccountService) {
        self.accountService = accountService
    }

    func updateTracksOptOutSetting(_ optOut: Bool) {
        guard let account = accountService.defaultWordPressComAccount() else {
            return
        }

        let change = AccountSettingsChange.tracksOptOut(optOut)
        AccountSettingsService(userID: account.userID.intValue, api: account.wordPressComRestApi).saveChange(change)
    }
}
