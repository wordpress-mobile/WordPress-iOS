import Foundation
import WordPressAuthenticator



// MARK: - WordPressAuthenticationManager
//
@objc
class WordPressAuthenticationManager: NSObject {

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Support is only available to the WordPress iOS App. Our Authentication Framework doesn't have direct access.
    /// We'll setup a mechanism to relay the Support event back to the Authenticator.
    ///
    func startRelayingSupportNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(supportPushNotificationReceived), name: .ZendeskPushNotificationReceivedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(supportPushNotificationCleared), name: .ZendeskPushNotificationClearedNotification, object: nil)
    }

    /// Initializes WordPressAuthenticator with all of the paramteres that will be needed during the login flow.
    ///
    func initializeWordPressAuthenticator() {
        let configuration = WordPressAuthenticatorConfiguration(wpcomClientId: ApiCredentials.client(),
                                                                wpcomSecret: ApiCredentials.secret(),
                                                                wpcomScheme: WPComScheme,
                                                                wpcomTermsOfServiceURL: WPAutomatticTermsOfServiceURL,
                                                                googleLoginClientId: ApiCredentials.googleLoginClientId(),
                                                                googleLoginServerClientId: ApiCredentials.googleLoginServerClientId(),
                                                                googleLoginScheme: ApiCredentials.googleLoginClientId(),
                                                                userAgent: WPUserAgent.wordPress())

        WordPressAuthenticator.initialize(configuration: configuration)
    }
}


// MARK: - Static Methods
//
extension WordPressAuthenticationManager {

    /// Returns an Authentication ViewController (configured to allow only WordPress.com). This method pre-populates the Email + Username
    /// with the values returned by the default WordPress.com account (if any).
    ///
    /// - Parameter onDismissed: Closure to be executed whenever the returned ViewController is dismissed.
    ///
    @objc
    class func signinForWPComFixingAuthToken(_ onDismissed: ((_ cancelled: Bool) -> Void)? = nil) -> UIViewController {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        let account = service.defaultWordPressComAccount()

        return WordPressAuthenticator.signinForWPCom(dotcomEmailAddress: account?.email, dotcomUsername: account?.username, onDismissed: onDismissed)
    }

    /// Presents the WordPress Authentication UI from the rootViewController (configured to allow only WordPress.com).
    /// This method pre-populates the Email + Username with the values returned by the default WordPress.com account (if any).
    ///
    @objc
    class func showSigninForWPComFixingAuthToken() {
        guard let presenter = UIApplication.shared.keyWindow?.rootViewController else {
            assertionFailure()
            return
        }

        let controller = signinForWPComFixingAuthToken()
        presenter.present(controller, animated: true, completion: nil)
    }
}


// MARK: - Notification Handlers
//
extension WordPressAuthenticationManager {

    @objc func supportPushNotificationReceived(_ notification: Foundation.Notification) {
        WordPressAuthenticator.shared.supportPushNotificationReceived()
    }

    @objc func supportPushNotificationCleared(_ notification: Foundation.Notification) {
        WordPressAuthenticator.shared.supportPushNotificationCleared()
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

    /// Indicates if Support is Enabled.
    ///
    var supportEnabled: Bool {
        return ZendeskUtils.zendeskEnabled
    }

    /// Indicates if the Support notification indicator should be displayed.
    ///
    var showSupportNotificationIndicator: Bool {
        return ZendeskUtils.showSupportNotificationIndicator
    }

    /// Returns an instance of a SupportView, configured to be displayed from a specified Support Source.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        let controller = SupportTableViewController()
        controller.sourceTag = sourceTag

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet

        sourceViewController.present(navController, animated: true, completion: nil)
    }

    /// Presents Support new request, with the specified ViewController as a source.
    /// Additional metadata is supplied, such as the sourceTag and Login details.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        ZendeskUtils.sharedInstance.showNewRequestIfPossible(from: sourceViewController, with: sourceTag)
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

    /// Presents the Signup Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: WordPressCredentials, service: SocialService?) {
        let storyboard = UIStoryboard(name: "SignupEpilogue", bundle: .main)
        guard let epilogueViewController = storyboard.instantiateInitialViewController() as? SignupEpilogueViewController else {
            fatalError()
        }

        epilogueViewController.credentials = credentials
        epilogueViewController.socialService = service

        navigationController.pushViewController(epilogueViewController, animated: true)
    }

    /// Indicates if the Login Epilogue should be presented. This is false only when we're doing a Jetpack Connect, and the new
    /// WordPress.com account has no sites. Capicci?
    ///
    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool {
        guard isJetpackLogin else {
            return true
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        let numberOfBlogs = service.defaultWordPressComAccount()?.blogs?.count ?? 0

        return numberOfBlogs > 0
    }

    /// Indicates if the Signup Epilogue should be displayed.
    ///
    func shouldPresentSignupEpilogue() -> Bool {
        return true
    }

    /// Whenever a WordPress.com acocunt has been created during the Auth flow, we'll add a new local WPCOM Account, and set it as
    /// the new DefaultWordPressComAccount.
    ///
    func createdWordPressComAccount(username: String, authToken: String) {
        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)

        let account = service.createOrUpdateAccount(withUsername: username, authToken: authToken)
        if service.defaultWordPressComAccount() == nil {
            service.setDefaultWordPressComAccount(account)
        }
    }

    /// Synchronizes the specified WordPress Account.
    ///
    func sync(credentials: WordPressCredentials, onCompletion: @escaping (Error?) -> Void) {
        switch credentials {
        case .wpcom(let username, let authToken, let isJetpackLogin, _):
            syncWPCom(username: username, authToken: authToken, isJetpackLogin: isJetpackLogin, onCompletion: onCompletion)
        case .wporg(let username, let password, let xmlrpc, let options):
            syncWPOrg(username: username, password: password, xmlrpc: xmlrpc, options: options, onCompletion: onCompletion)
        }
    }

    /// Tracks a given Analytics Event.
    ///
    func track(event: WPAnalyticsStat) {
        WPAppAnalytics.track(event)
    }

    /// Tracks a given Analytics Event, with the specified properties.
    ///
    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        WPAppAnalytics.track(event, withProperties: properties)
    }

    /// Tracks a given Analytics Event, with the specified error.
    ///
    func track(event: WPAnalyticsStat, error: Error) {
        WPAppAnalytics.track(event, error: error)
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
