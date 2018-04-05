import Foundation


// MARK: - WordPressAuthenticationManager
//
class WordPressAuthenticationManager {

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Helpshift is only available to the WordPress iOS App. Our Authentication Framework doesn't have direct access.
    /// We'll setup a mechanism to relay the `helpshiftUnreadCountWasUpdated` event back to the Authenticator.
    ///
    func startRelayingHelpshiftNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(helpshiftUnreadCountWasUpdated), name: .HelpshiftUnreadCountUpdated, object: nil)
    }
}


// MARK: - Notification Handlers
//
extension WordPressAuthenticationManager {

    @objc
    func helpshiftUnreadCountWasUpdated(_ notification: Foundation.Notification) {
        WordPressAuthenticator.shared.supportBadgeCountWasUpdated()
    }
}


// MARK: - WordPressAuthenticator Delegate
//
extension WordPressAuthenticationManager: WordPressAuthenticatorDelegate {

    /// Indicates if the active Authenticator can be dismissed, or not. Authentication is Dismissable when there is a
    /// default wpcom account, or at least one self-hosted blog.
    ///
    var dismissActionEnabled: Bool {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        return AccountHelper.isDotcomAvailable() || blogService.blogCountForAllAccounts() > 0
    }

    /// Indicates whether if the Support Action should be enabled, or not.
    ///
    var supportActionEnabled: Bool {
        return true
    }

    /// Indicates if Helpshift is Enabled.
    ///
    var livechatActionEnabled: Bool {
        return HelpshiftUtils.isHelpshiftEnabled()
    }

    /// Returns Helpshift's Unread Messages Count.
    ///
    var supportBadgeCount: Int {
        return HelpshiftUtils.unreadNotificationCount()
    }

    /// Refreshes Helpshift's Unread Count.
    ///
    func refreshSupportBadgeCount() {
        HelpshiftUtils.refreshUnreadNotificationCount()
    }

    /// Returns an instance of SupportViewController, configured to be displayed from a specified Support Source.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, options: [String: Any] = [:]) {
        let supportViewController = SupportViewController()
        supportViewController.sourceTag = sourceTag.toSupportSourceTag()
        supportViewController.helpshiftOptions = options

        let navController = UINavigationController(rootViewController: supportViewController)
        navController.navigationBar.isTranslucent = false
        navController.modalPresentationStyle = .formSheet

        sourceViewController.present(navController, animated: true, completion: nil)
    }

    /// Presents Helpshift, with the specified ViewController as a source. Additional metadata is supplied, such as the sourceTag and Login details.
    ///
    func presentLivechat(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, options: [String: Any]) {
        let presenter = HelpshiftPresenter()
        presenter.sourceTag = sourceTag.toSupportSourceTag()
        presenter.optionsDictionary = options
        presenter.presentHelpshiftConversationWindowFromViewController(sourceViewController,
                                                                       refreshUserDetails: true,
                                                                       completion: nil)
    }

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: WordPressCredentials, onDismiss: @escaping () -> Void) {
        let storyboard = UIStoryboard(name: "LoginEpilogue", bundle: .main)
        guard let epilogueViewController = storyboard.instantiateInitialViewController() as? LoginEpilogueViewController else {
            fatalError()
        }

        epilogueViewController.credentials = credentials
        epilogueViewController.onDismiss = onDismiss

        navigationController.pushViewController(epilogueViewController, animated: true)
    }

    /// Indicates if the Login Epilogue should be presented. This is true whenever:
    ///
    ///     A. We're logging into a Dotcom Account
    ///     B. We're connecting a Self Hosted Site to WPcom (Jetpack Login)
    ///
    /// Note: Whenever it's a Jetpack Login, but the actual blog cannot be found (or the account is already there), we will not present
    /// the epilogue!.
    ///
    func shouldPresentLoginEpilogue(jetpackBlogXMLRPC: String?, jetpackBlogUsername: String?) -> Bool {
        guard let xmlrpc = jetpackBlogXMLRPC, let username = jetpackBlogUsername else {
            return true
        }

        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        guard let blog = blogService.findBlog(withXmlrpc: xmlrpc, andUsername: username), let account = blog.account else {
            return false
        }

        let accountService = AccountService(managedObjectContext: context)
        return accountService.isDefaultWordPressComAccount(account)
    }

    /// Synchronizes the specified WordPress Account.
    ///
    func sync(credentials: WordPressCredentials, onCompletion: @escaping (Error?) -> ()) {
        switch credentials {
        case .wpcom(let username, let authToken, let isJetpackLogin, _):
            syncWPCom(username: username, authToken: authToken, isJetpackLogin: isJetpackLogin, onCompletion: onCompletion)
        case .wporg(let username, let password, let xmlrpc, let options):
            syncWPOrg(username: username, password: password, xmlrpc: xmlrpc, options: options, onCompletion: onCompletion)
        }
    }
}


// MARK: - WordPressAuthenticatorManager
//
private extension WordPressAuthenticationManager {

    /// Synchronizes a WordPress.com account with the specified credentials.
    ///
    private func syncWPCom(username: String, authToken: String, isJetpackLogin: Bool, onCompletion: @escaping (Error?) -> ()) {
        let service = WordPressComSyncService()

        service.syncWPCom(username: username, authToken: authToken, isJetpackLogin: isJetpackLogin, onSuccess: { account in

            /// HACK: An alternative notification to LoginFinished. Observe this instead of `WPSigninDidFinishNotification` for Jetpack logins.
            /// When WPTabViewController no longer destroy's and rebuilds the view hierarchy this alternate notification can be removed.
            ///
            let notification = isJetpackLogin == true ? .wordpressLoginFinishedJetpackLogin : Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification)
            NotificationCenter.default.post(name: notification, object: account)

            onCompletion(nil)

        }, onFailure: { error in
            onCompletion(error)
        })
    }

    /// Synchronizes a WordPress.org account with the specified credentials.
    ///
    private func syncWPOrg(username: String, password: String, xmlrpc: String, options: [AnyHashable: Any], onCompletion: @escaping (Error?) -> ()) {
        let service = BlogSyncFacade()

        service.syncBlog(withUsername: username, password: password, xmlrpc: xmlrpc, options: options) { blog in
            RecentSitesService().touch(blog: blog)
            onCompletion(nil)
        }
    }
}
