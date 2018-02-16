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
