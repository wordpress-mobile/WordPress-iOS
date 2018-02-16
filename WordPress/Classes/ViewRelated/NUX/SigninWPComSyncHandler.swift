import UIKit
import CocoaLumberjack
import WordPressShared

/// A protocol and extension encapsulating syncing behavior common to WPCom
/// signin controllers.  Responsible for syncing account information and blog
/// details of the user.
///
protocol SigninWPComSyncHandler: class {
    func configureViewLoading(_ loading: Bool)
    func configureStatusLabel(_ message: String)
    func dismiss()
    func displayError(_ error: NSError, sourceTag: WordPressSupportSourceTag)
    func updateSafariCredentialsIfNeeded()
    func isJetpackLogin() -> Bool

    func syncWPCom(_ username: String, authToken: String, requiredMultifactor: Bool)
    func handleSyncSuccess(for account: WPAccount, requiredMultifactor: Bool)
    func handleSyncFailure(_ error: NSError?)
}


extension SigninWPComSyncHandler {

    /// Syncs account and blog information for the authenticated wpcom user.
    ///
    /// - Parameters:
    ///     - username: The username.
    ///     - authToken: The authentication token.
    ///     - requiredMultifactor: Whether a multifactor code was required while authenticating.
    ///
    func syncWPCom(_ username: String, authToken: String, requiredMultifactor: Bool) {
        updateSafariCredentialsIfNeeded()

        configureStatusLabel(NSLocalizedString("Getting account information", comment: "Alerts the user that wpcom account information is being retrieved."))
        let accountFacade = AccountServiceFacade()
        let account = accountFacade.createOrUpdateWordPressComAccount(withUsername: username, authToken: authToken)

        // Create reusable success and failure blocks to share between service calls.
        let successBlock = { [weak self] in
            accountFacade.updateUserDetails(for: account, success: { [weak self] in
                self?.handleSyncSuccess(for: account, requiredMultifactor: requiredMultifactor)

                }, failure: { [weak self] (error: Error?) in
                    self?.handleSyncFailure(error as NSError?)
            })
        }

        let failureBlock: (Error?) -> Void = { [weak self] (error: Error?) in
            self?.handleSyncFailure(error as NSError?)
        }

        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if isJetpackLogin() && !accountService.isDefaultWordPressComAccount(account) {
            let blogService = BlogService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            blogService.associateSyncedBlogs(toJetpackAccount: account, success: successBlock, failure: failureBlock)

        } else {
            accountFacade.setDefaultWordPressComAccount(account)
            BlogSyncFacade().syncBlogs(for: account, success: successBlock, failure: failureBlock)
        }
    }


    /// Cleans up the view after a successful sync and dismisses the NUX controller.
    /// - Parameter requiredMultifactor: Whether a multifactor code was required while authenticating.
    ///
    /// - Parameters:
    ///
    func handleSyncSuccess(for account: WPAccount, requiredMultifactor: Bool) {
        configureStatusLabel("")
        configureViewLoading(false)

        // HACK: An alternative notification to LoginFinished.
        // Observe this instead of `WPSigninDidFinishNotification`
        // for Jetpack logins.  When WPTabViewController no longer destroy's
        // and rebuilds the view hierarchy this alternate notification can be
        // removed.
        let notification = isJetpackLogin() ? .wordpressLoginFinishedJetpackLogin : Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification)
        NotificationCenter.default.post(name: notification, object: account)

        dismiss()

        let properties = [
            "multifactor": requiredMultifactor ? true.description : false.description,
            "dotcom_user": true.description
        ]

        WordPressAuthenticator.post(event: .signedIn(properties: properties))
    }


    /// Handles an error while syncing account and blog information for the
    /// authenticated user.
    ///
    func handleSyncFailure(_ error: NSError?) {
        configureStatusLabel("")
        configureViewLoading(false)

        // At this point the user is authed and there is a valid account in core data.
        // Make a note of the error and just dismiss the vc. There might be some
        // wonkiness due to missing data (blogs, account info) but this will eventually
        // resync.
        DDLogError("Error while syncing wpcom account and/or blog details after authentiating. \(String(describing: error))")
        dismiss()
    }
}
