import Foundation


/// SigninWordPressComService encapsulates all of the logic related to Logging into a WordPress.com account, and sync'ing the
/// User's blogs.
///
class SigninWordPressComService {

    /// Syncs account and blog information for the authenticated wpcom user.
    ///
    /// - Parameters:
    ///     - username: The username.
    ///     - authToken: The authentication token.
    ///     - isJetpackLogin: Indicates if this is a Jetpack Site.
    ///     - onSuccess: Closure to be executed upon success.
    ///     - onFailure: Closure to be executed upon failure.
    ///
    func syncWPCom(username: String, authToken: String, isJetpackLogin: Bool, onSuccess: @escaping (_ account: WPAccount) -> (), onFailure: @escaping (Error) -> ()) {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        let newAccount = accountService.createOrUpdateAccount(withUsername: username, authToken: authToken)

        // Reusable success closure to share between service calls.
        let onSuccessInternal = {
            accountService.updateUserDetails(for: newAccount, success: {
                onSuccess(newAccount)
            }, failure: onFailure)
        }

        if isJetpackLogin && !accountService.isDefaultWordPressComAccount(newAccount) {
            let blogService = BlogService(managedObjectContext: context)
            blogService.associateSyncedBlogs(toJetpackAccount: newAccount, success: onSuccessInternal, failure: onFailure)

        } else {
            if accountService.defaultWordPressComAccount()?.isEqual(newAccount) == false {
                accountService.removeDefaultWordPressComAccount()
            }

            accountService.setDefaultWordPressComAccount(newAccount)

            BlogSyncFacade().syncBlogs(for: newAccount, success: onSuccessInternal, failure: onFailure)
        }
    }
}
