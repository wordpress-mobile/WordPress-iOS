import Foundation


// MARK: - WordPressAuthenticationManager
//
@objc
class WordPressAuthenticationManager: NSObject {

}


// MARK: - WordPressAuthenticator Delegate
//
extension WordPressAuthenticationManager: WordPressAuthenticatorDelegate {

    /// Indicates whether if the Support Action should be enabled, or not.
    ///
    var supportActionEnabled: Bool {
        return true
    }

    /// Returns an instance of SupportViewController, configured to be displayed from a specified Support Source.
    ///
    func supportViewController(from source: WordPressSupportSourceTag) -> UIViewController {
        let supportViewController = SupportViewController()
        supportViewController.sourceTag = source.toSupportSourceTag()

        let navController = UINavigationController(rootViewController: supportViewController)
        navController.navigationBar.isTranslucent = false
        navController.modalPresentationStyle = .formSheet

        return supportViewController
    }

    /// Indicates if Helpshift is Enabled.
    ///
    var helpshiftEnabled: Bool {
        return HelpshiftUtils.isHelpshiftEnabled()
    }

    /// Returns Helpshift's Unread Messages Count.
    ///
    var helpshiftUnreadCount: Int {
        return HelpshiftUtils.unreadNotificationCount()
    }

    /// Presents Helpshift, with the specified ViewController as a source. Additional metadata is supplied, such as the sourceTag and Login details.
    ///
    func presentHelpshift(from viewController: UIViewController, sourceTag: WordPressSupportSourceTag, options: [String: Any]) {
        let presenter = HelpshiftPresenter()
        presenter.sourceTag = sourceTag.toSupportSourceTag()
        presenter.optionsDictionary = options
        presenter.presentHelpshiftConversationWindowFromViewController(viewController,
                                                                       refreshUserDetails: true,
                                                                       completion: nil)
    }

    /// Refreshes Helpshift's Unread Count.
    ///
    func refreshHelpshiftUnreadCount() {
        HelpshiftUtils.refreshUnreadNotificationCount()
    }
}


// MARK: - WordPressSupportSourceTag ClientApp Helper Methods
//
extension WordPressSupportSourceTag {

    /// Returns the matching SupportSourceTag enum case, matching for the current WordPressSupportSourceTag (Auth Framework) enum case.
    ///
    func toSupportSourceTag() -> SupportSourceTag {
        switch self {
        case .generalLogin:
            return .generalLogin
        case .jetpackLogin:
            return  .jetpackLogin
        case .loginEmail:
            return .loginEmail
        case .login2FA:
            return .login2FA
        case .loginMagicLink:
            return .loginMagicLink
        case .loginSiteAddress:
            return .loginSiteAddress
        case .loginUsernamePassword:
            return .loginUsernamePassword
        case .loginWPComPassword:
            return .loginWPComPassword
        case .wpComCreateSiteCreation:
            return .wpComCreateSiteCreation
        case .wpComCreateSiteDomain:
            return .wpComCreateSiteDomain
        case .wpComCreateSiteDetails:
            return .wpComCreateSiteDetails
        case .wpComSignupEmail:
            return .wpComSignupEmail
        case .wpComSignup:
            return .wpComSignup
        }
    }
}
