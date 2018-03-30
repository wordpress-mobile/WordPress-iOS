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
    func presentLoginEpilogue(in navigationController: UINavigationController, epilogueInfo: LoginEpilogueUserInfo? = nil, isJetpackLogin: Bool, onDismiss: @escaping () -> Void) {
        let storyboard = UIStoryboard(name: "LoginEpilogue", bundle: .main)
        guard let epilogueViewController = storyboard.instantiateInitialViewController() as? LoginEpilogueViewController else {
            fatalError()
        }

        epilogueViewController.epilogueUserInfo = epilogueInfo
        epilogueViewController.jetpackLogin = isJetpackLogin
        epilogueViewController.onDismiss = onDismiss

        navigationController.pushViewController(epilogueViewController, animated: true)
    }
}
