import Foundation


/// WordPressComSyncService encapsulates all of the logic related to Logging into a WordPress.com account, and sync'ing the
/// User's blogs.
///
class WordPressComSyncService {

    /// Syncs account and blog information for the authenticated wpcom user.
    ///
    /// - Parameters:
    ///     - username: The username.
    ///     - authToken: The authentication token.
    ///     - isJetpackLogin: Indicates if this is a Jetpack Site.
    ///     - onSuccess: Closure to be executed upon success.
    ///     - onFailure: Closure to be executed upon failure.
    ///
    func syncWPCom(username: String, authToken: String, isJetpackLogin: Bool, onCompletion: @escaping (Error?) -> ()) {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        let newAccount = accountService.createOrUpdateAccount(withUsername: username, authToken: authToken)

        let onFailureInternal = { (error: Error) in
            /// At this point the user is authed and there is a valid account in core data. Make a note of the error and just dismiss
            /// the vc. There might be some wonkiness due to missing data (blogs, account info) but this will eventually resync.
            ///
            DDLogError("Error while syncing wpcom account and/or blog details after authenticating. \(String(describing: error))")
            onCompletion(error)
        }

        let onSuccessInternal = {
            accountService.updateUserDetails(for: newAccount, success: {
                onCompletion(nil)
            }, failure: onFailureInternal)
        }

        if isJetpackLogin && !accountService.isDefaultWordPressComAccount(newAccount) {
            let blogService = BlogService(managedObjectContext: context)
            blogService.associateSyncedBlogs(toJetpackAccount: newAccount, success: onSuccessInternal, failure: onFailureInternal)

        } else {
            if accountService.defaultWordPressComAccount()?.isEqual(newAccount) == false {
                accountService.removeDefaultWordPressComAccount()
            }

            accountService.setDefaultWordPressComAccount(newAccount)

            BlogSyncFacade().syncBlogs(for: newAccount, success: onSuccessInternal, failure: onFailureInternal)
        }
    }
}
