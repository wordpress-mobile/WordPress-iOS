import UIKit

// MARK: - Storyboard enum
enum Storyboard: String {
    case login = "Login"
    case signup = "Signup"
    case getStarted = "GetStarted"
    case unifiedSignup = "UnifiedSignup"
    case unifiedLoginMagicLink = "LoginMagicLink"
    case emailMagicLink = "EmailMagicLink"
    case siteAddress = "SiteAddress"
    case googleAuth = "GoogleAuth"
    case googleSignupConfirmation = "GoogleSignupConfirmation"
    case twoFA = "TwoFA"
    case password = "Password"
    case verifyEmail = "VerifyEmail"
    case nuxButtonView = "NUXButtonView"

    var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: WordPressAuthenticator.bundle)
    }

    /// Returns a view controller from a Storyboard
    /// assuming the identifier is the same as the class name.
    ///
    func instantiateViewController<T: NSObject>(ofClass classType: T.Type, creator: ((NSCoder) -> UIViewController?)? = nil) -> T? {
        let identifier = classType.classNameWithoutNamespaces
        return instance.instantiateViewController(identifier: identifier, creator: creator) as? T
    }
}
