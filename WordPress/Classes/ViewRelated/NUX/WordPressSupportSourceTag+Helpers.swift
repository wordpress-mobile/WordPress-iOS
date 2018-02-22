import Foundation


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
