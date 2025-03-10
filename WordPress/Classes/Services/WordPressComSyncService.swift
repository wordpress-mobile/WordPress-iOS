import Foundation
import WordPressData
import WordPressKit

/// WordPressComSyncService encapsulates all of the logic related to Logging into a WordPress.com account, and syncing the
/// User's blogs.
///
class WordPressComSyncService {

    private let coreDataStack: CoreDataStackSwift

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.coreDataStack = coreDataStack
    }

    /// Syncs account and blog information for the authenticated wpcom user.
    ///
    /// - Parameters:
    ///     - authToken: The authentication token.
    ///     - isJetpackLogin: Indicates if this is a Jetpack Site.
    ///     - onSuccess: Closure to be executed upon success.
    ///     - onFailure: Closure to be executed upon failure.
    ///
    func syncWPCom(authToken: String, isJetpackLogin: Bool, onSuccess: @escaping (WPAccount) -> Void, onFailure: @escaping (Error) -> Void) {
        let accountService = AccountService(coreDataStack: coreDataStack)
        accountService.createOrUpdateAccount(withAuthToken: authToken, success: { account in
            self.syncOrAssociateBlogs(account: account, isJetpackLogin: isJetpackLogin, onSuccess: onSuccess, onFailure: onFailure)
        }, failure: { error in
            onFailure(error)
        })
    }

    @MainActor
    func syncWPCom(remoteUser: RemoteUser, authToken: String, isJetpackLogin: Bool) async throws -> TaggedManagedObjectID<WPAccount> {
        let accountService = AccountService(coreDataStack: coreDataStack)
        let accountID = accountService.createOrUpdateAccount(withUserDetails: remoteUser, authToken: authToken)

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let account: WPAccount
                do {
                    let object = try self.coreDataStack.mainContext.existingObject(with: accountID)
                    account = object as! WPAccount
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                self.syncOrAssociateBlogs(
                    account: account,
                    isJetpackLogin: isJetpackLogin,
                    onSuccess: { continuation.resume(returning: .init($0)) },
                    onFailure: { continuation.resume(throwing: $0) }
                )
            }
        }
    }

    /// Syncs or associates blogs for the specified account.
    ///
    /// - Parameters:
    ///   - account: The WPAccount for which to sync/associate blogs.
    ///   - isJetpackLogin: Whether a Jetpack connected account is being logged into.
    ///   - onSuccess: Success block
    ///   - onFailure: Failure block
    ///
    func syncOrAssociateBlogs(account: WPAccount, isJetpackLogin: Bool, onSuccess: @escaping (WPAccount) -> Void, onFailure: @escaping (Error) -> Void) {
        let accountService = AccountService(coreDataStack: ContextManager.sharedInstance())

        let onFailureInternal = { (error: Error) in
            /// At this point the user is authed and there is a valid account in core data. Make a note of the error and just dismiss
            /// the vc. There might be some wonkiness due to missing data (blogs, account info) but this will eventually resync.
            ///
            DDLogError("Error while syncing wpcom account and/or blog details after authenticating. \(String(describing: error))")
            onFailure(error)
        }

        let onSuccessInternal = {
            onSuccess(account)
        }

        if isJetpackLogin && !account.isDefaultWordPressComAccount {
            let blogService = BlogService(coreDataStack: coreDataStack)
            blogService.associateSyncedBlogs(toJetpackAccount: account, success: onSuccessInternal, failure: onFailureInternal)

        } else {
            if !account.isDefaultWordPressComAccount {
                accountService.removeDefaultWordPressComAccount()
            }

            accountService.setDefaultWordPressComAccount(account)

            BlogSyncFacade().syncBlogs(for: account, success: onSuccessInternal, failure: onFailureInternal)
        }
    }
}
