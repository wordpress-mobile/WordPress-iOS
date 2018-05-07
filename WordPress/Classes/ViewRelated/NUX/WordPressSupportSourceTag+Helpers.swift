import Foundation
import WordPressAuthenticator


// MARK: - WordPressSupportSourceTag ClientApp Helper Methods
//
extension WordPressSupportSourceTag {

    /// Returns the sourceTag description
    ///
    var description: String {
        switch self {
        case .generalLogin:
            return "origin:login-screen"
        case .jetpackLogin:
            return  "origin:jetpack-login-screen"
        case .loginEmail:
            return "origin:login-email"
        case .login2FA:
            return "origin:login-2fa"
        case .loginMagicLink:
            return "origin:login-magic-link"
        case .loginSiteAddress:
            return "origin:login-site-address"
        case .loginUsernamePassword:
            return "origin:login-username-password"
        case .loginWPComPassword:
            return "origin:login-wpcom-password"
        case .wpComCreateSiteCreation:
            return "origin:wpcom-create-site-creation"
        case .wpComCreateSiteCategory:
            return "origin:wpcom-create-site-category"
        case .wpComCreateSiteTheme:
            return "origin:wpcom-create-site-theme"
        case .wpComCreateSiteDomain:
            return "origin:wpcom-create-site-domain"
        case .wpComCreateSiteDetails:
            return "origin:wpcom-create-site-details"
        case .wpComCreateSiteUsername:
            return "origin:wpcom-create-site-username"
        case .wpComSignupEmail:
            return "origin:wpcom-signup-email-entry"
        case .wpComSignup:
            return "origin:signup-screen"
        case .wpComSignupWaitingForGoogle:
            return "origin:signup-waiting-for-google"
        case .wpComSignupMagicLink:
            return "origin:signup-magic-link"
        case .wpComLogin:
            return "origin:wpcom-login-screen"
        case .wpOrgLogin:
            return "origin:wporg-login-screen"
        case .inAppFeedback:
            return "origin:in-app-feedback"
        }
    }

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
        case .wpComCreateSiteCategory:
            return .wpComCreateSiteCategory
        case .wpComCreateSiteTheme:
            return .wpComCreateSiteTheme
        case .wpComCreateSiteDomain:
            return .wpComCreateSiteDomain
        case .wpComCreateSiteDetails:
            return .wpComCreateSiteDetails
        case .wpComCreateSiteUsername:
            return .wpComCreateSiteUsername
        case .wpComSignupEmail:
            return .wpComSignupEmail
        case .wpComSignup:
            return .wpComSignup
        case .wpComSignupWaitingForGoogle:
            return .signupWaitingForGoogle
        case .wpComSignupMagicLink:
            return .signupMagicLink
        case .wpComLogin:
            return .wpComLogin
        case .wpOrgLogin:
            return .wpOrgLogin
        case .inAppFeedback:
            return .inAppFeedback
        }
    }
}
