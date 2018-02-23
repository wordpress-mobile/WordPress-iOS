import Foundation


// MARK: - Authentication Flow Event. Useful to relay internal Auth events over to activity trackers.
//
public enum WordPressSupportSourceTag {
    case generalLogin
    case jetpackLogin
    case loginEmail
    case login2FA
    case loginMagicLink
    case loginSiteAddress
    case loginUsernamePassword
    case loginWPComPassword
    case wpComCreateSiteCreation
    case wpComCreateSiteDomain
    case wpComCreateSiteDetails
    case wpComSignupEmail
    case wpComSignup
}
