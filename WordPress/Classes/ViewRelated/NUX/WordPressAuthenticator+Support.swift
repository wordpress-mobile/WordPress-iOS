import Foundation


// MARK: - Authentication Flow Event. Useful to relay internal Auth events over to activity trackers.
//
public extension WordPressAuthenticator {
    public enum SupportOrigin {
        case generalLogin
        case jetpackLogin
        case loginEmail
        case login2FA
        case loginMagicLink
        case loginSiteAddress
        case loginUsernamePassword
        case loginWPComPassword
        case wpComSignupEmail
        case wpComSignup
    }
}
