import Foundation
import WordPressKit

/// LoginFields is a state container for user textfield input on the login screens
/// as well as other meta data regarding the nature of a login attempt.
///
@objc
public class LoginFields: NSObject {
    // These fields store user input from text fields.

    /// Stores the user's account identifier (either email address or username) that is
    /// entered in the login flow. By convention, even if the user is logging in
    /// via an email address this field should store that value.
    @objc public var username = ""

    /// The user's password.
    @objc public var password = ""

    /// The site address if logging in via the self-hosted flow.
    @objc public var siteAddress = ""

    /// The two factor code entered by a user.
    @objc public var multifactorCode = "" // 2fa code

    /// Nonce info in the event of a social login with 2fa
    @objc public var nonceInfo: SocialLogin2FANonceInfo?

    /// User ID for use with the nonce for social login
    @objc public var nonceUserID: Int = 0

    /// Used to restrict login to WordPress.com
    public var restrictToWPCom = false

    /// Used on the webauthn/security key flow.
    public var webauthnChallengeInfo: WebauthnChallengeInfo?

    /// Used by the SignupViewController. Signup currently asks for both a
    /// username and an email address.  This can be factored away when we revamp
    /// the signup flow.
    @objc public var emailAddress = ""

    var meta = LoginFieldsMeta()

    @objc public var userIsDotCom: Bool {
        get { meta.userIsDotCom }
        set { meta.userIsDotCom = newValue }
    }

    @objc public var requiredMultifactor: Bool {
        meta.requiredMultifactor
    }

    @objc public var xmlrpcURL: NSURL? {
        get { meta.xmlrpcURL }
        set { meta.xmlrpcURL = newValue }
    }

    var storedCredentials: SafariStoredCredentials?

    /// Convenience method for persisting stored credentials.
    ///
    @objc func setStoredCredentials(usernameHash: Int, passwordHash: Int) {
        storedCredentials = SafariStoredCredentials()
        storedCredentials?.storedUserameHash = usernameHash
        storedCredentials?.storedPasswordHash = passwordHash
    }

    class func makeForWPCom(username: String, password: String) -> LoginFields {
        let loginFields = LoginFields()

        loginFields.username = username
        loginFields.password = password

        return loginFields
    }

    /// Using a convenience initializer for its Objective-C usage in unit tests.
    convenience init(username: String,
                     password: String,
                     siteAddress: String,
                     multifactorCode: String,
                     nonceInfo: SocialLogin2FANonceInfo?,
                     nonceUserID: Int,
                     restrictToWPCom: Bool,
                     emailAddress: String,
                     meta: LoginFieldsMeta,
                     storedCredentials: SafariStoredCredentials?) {
        self.init()
        self.username = username
        self.password = password
        self.siteAddress = siteAddress
        self.multifactorCode = multifactorCode
        self.nonceInfo = nonceInfo
        self.nonceUserID = nonceUserID
        self.restrictToWPCom = restrictToWPCom
        self.emailAddress = emailAddress
        self.meta = meta
        self.storedCredentials = storedCredentials
    }
}

extension LoginFields {
    func copy() -> LoginFields {
        .init(username: username,
              password: password,
              siteAddress: siteAddress,
              multifactorCode: multifactorCode,
              nonceInfo: nonceInfo,
              nonceUserID: nonceUserID,
              restrictToWPCom: restrictToWPCom,
              emailAddress: emailAddress,
              meta: meta.copy(),
              storedCredentials: storedCredentials)
    }
}

extension LoginFields {

    var parametersForSignInWithApple: [String: AnyObject]? {
        guard let user = meta.socialUser, case .apple = user.service else {
            return nil
        }

        return AccountServiceRemoteREST.appleSignInParameters(
            email: user.email,
            fullName: user.fullName
        )
    }
}

/// A helper class for storing safari saved password information.
///
class SafariStoredCredentials {
    var storedUserameHash = 0
    var storedPasswordHash = 0
}

/// An enum to indicate where the Magic Link Email was sent from.
///
enum EmailMagicLinkSource: Int {
    case login = 1
    case signup = 2
}
