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

extension AccountSettingsRemoteInterface {
    func updateSetting(_ change: AccountSettingsChange) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.updateSetting(change, success: continuation.resume, failure: continuation.resume(throwing:))
        }
    }
}

extension AccountSettingsRemote: AccountSettingsRemoteInterface {}


class AccountSettingsService {
    struct Defaults {
        static let stallTimeout = 4.0
        static let maxRetries = 3
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

    private let coreDataStack: CoreDataStackSwift

    convenience init(userID: Int, api: WordPressComRestApi) {
        let remote = AccountSettingsRemote.remoteWithApi(api)
        self.init(userID: userID, remote: remote)
    }

    init(userID: Int, remote: AccountSettingsRemoteInterface, coreDataStack: CoreDataStackSwift = ContextManager.sharedInstance()) {
        self.userID = userID
        self.remote = remote
        self.coreDataStack = coreDataStack
        loadSettings()
    }

    func getSettingsAttempt(count: Int = 0, completion: ((Result<AccountSettings, Error>) -> Void)? = nil) {
        remote.getSettings(
            success: { settings in
                self.coreDataStack.performAndSave({ context in
                    if let managedSettings = self.managedAccountSettingsWithID(self.userID, in: context) {
                        managedSettings.updateWith(settings)
                    } else {
                        self.createAccountSettings(self.userID, settings: settings, in: context)
                    }
                }, completion: {
                    self.loadSettings()
                    self.status = .idle
                    completion?(.success(settings))
                }, on: .main)
            },
            failure: { error in
                let error = error as NSError
                if error.domain == NSURLErrorDomain {
                    DDLogError("Error refreshing settings (attempt \(count)): \(error)")
                } else {
                    DDLogError("Error refreshing settings (unrecoverable): \(error)")
                }

                if error.domain == NSURLErrorDomain && error.code != URLError.cancelled.rawValue && count < Defaults.maxRetries {
                    self.getSettingsAttempt(count: count + 1, completion: completion)
                } else {
                    self.status = .failed
                    completion?(.failure(error))
                }
            }
        )
    }

    func refreshSettings(completion: ((Result<AccountSettings, Error>) -> Void)? = nil) {
        guard status == .idle || status == .failed else {
            return
        }
        status = .refreshing
        getSettingsAttempt(completion: completion)
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
        Task { @MainActor in
            do {
                try await saveChange(change)
                finished?(true)
            } catch {
                NotificationCenter.default.post(name: NSNotification.Name.AccountSettingsServiceChangeSaveFailed, object: self, userInfo: [NSUnderlyingErrorKey: error])
                finished?(false)
            }
        }
    }

    func saveChange(_ change: AccountSettingsChange) async throws {
        guard let reverse = try? await applyChange(change) else {
            return
        }
        do {
            try await remote.updateSetting(change)
        } catch {
            do {
                // revert change
                try await self.applyChange(reverse)
            } catch {
                DDLogError("Error reverting change \(error)")
            }
            DDLogError("Error saving account settings change \(error)")

            throw error
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
        coreDataStack.performQuery { context in
            try? Blog.lookup(withID: settings.primarySiteID, in: context)?.settings?.name
        }
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

    @discardableResult fileprivate func applyChange(_ change: AccountSettingsChange) async throws -> AccountSettingsChange {
        let reverse = try await coreDataStack.performAndSave({ context in
            guard let settings = self.managedAccountSettingsWithID(self.userID, in: context) else {
                DDLogError("Tried to apply a change to nonexistent settings (ID: \(self.userID)")
                throw Errors.notFound
            }

            let reverse = settings.applyChange(change)
            settings.account.applyChange(change)
            return reverse
        })

        await MainActor.run {
            self.loadSettings()
        }

        return reverse
    }

    fileprivate func accountSettingsWithID(_ userID: Int) -> AccountSettings? {
        coreDataStack.performQuery { context in
            guard let managedAccount = self.managedAccountSettingsWithID(userID, in: context) else {
                return nil
            }

            return AccountSettings.init(managed: managedAccount)
        }
    }

    fileprivate func managedAccountSettingsWithID(_ userID: Int, in context: NSManagedObjectContext) -> ManagedAccountSettings? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedAccountSettings.entityName())
        request.predicate = NSPredicate(format: "account.userID = %d", userID)
        request.fetchLimit = 1
        guard let results = (try? context.fetch(request)) as? [ManagedAccountSettings] else {
            return nil
        }
        return results.first
    }

    fileprivate func createAccountSettings(_ userID: Int, settings: AccountSettings, in context: NSManagedObjectContext) {

        guard let account = try? WPAccount.lookup(withUserID: Int64(userID), in: context) else {
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
