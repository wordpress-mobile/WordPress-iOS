import Foundation

/// LoginFields is a state container for user textfield input on the login screens
/// as well as other meta data regarding the nature of a login attempt.
///
@objc
class LoginFields: NSObject {
    // These fields store user input from text fields.

    /// Stores the user's account identifier (either email address or username) that is
    /// entered in the login flow. By convention, even if the user is logging in
    /// via an email address this field should store that value.
    @objc var username = ""

    /// The user's password.
    @objc var password = ""

    /// The site address if logging in via the self-hosted flow.
    @objc var siteAddress = ""

    /// The two factor code entered by a user.
    @objc var multifactorCode = "" // 2fa code

    /// Nonce info in the event of a social login with 2fa
    @objc var nonceInfo: SocialLogin2FANonceInfo?

    /// User ID for use with the nonce for social login
    @objc var nonceUserID: Int = 0

    /// Used by the SignupViewController. Signup currently asks for both a
    /// username and an email address.  This can be factored away when we revamp
    /// the signup flow.
    @objc var emailAddress = ""

    @objc var meta = LoginFieldsMeta()
    var storedCredentials: SafariStoredCredentials?


    /// Returns a dictionary of login related data to include with a Helpshift session.
    /// Used to help diagnose trouble reports via helpshift.
    ///
    @objc func helpshiftLoginOptions() -> [String: Any] {
        return [
            "Source": "Login",
            "Username": username,
            "SiteURL": siteAddress,
        ]
    }

    /// Convenience method for persisting stored credentials.
    ///
    @objc func setStoredCredentials(usernameHash: Int, passwordHash: Int) {
        storedCredentials = SafariStoredCredentials()
        storedCredentials?.storedUserameHash = usernameHash
        storedCredentials?.storedPasswordHash = passwordHash
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
    case login
    case signup
}

@objc
class LoginFieldsMeta: NSObject {

    /// Indicates where the Magic Link Email was sent from. 
    var emailMagicLinkSource: EmailMagicLinkSource?

    /// Indicates whether a self-hosted user is attempting to log in to Jetpack
    @objc var jetpackLogin: Bool {
        if let _ = self.jetpackBlogID {
            return true
        }
        return false
    }
    @objc var jetpackBlogID: NSManagedObjectID?

    /// Indicates whether a user is logging in via the wpcom flow or a self-hosted flow.  Used by the
    /// the LoginFacade in its branching logic.
    /// This is a good candidate to refactor out and call the proper login method directly.
    @objc var userIsDotCom = true

    /// Indicates a wpcom account created via social sign up that requires either a magic link, or a social log in option.
    /// If a user signed up via social sign up and subsequently reset their password this field will be false.
    @objc var passwordless = false

    /// Should point to the site's xmlrpc.php for a self-hosted log in.  Should be the value returned via XML-RPC discovery.
    @objc var xmlrpcURL: NSURL?

    /// Meta data about a site. This information is fetched and then displayed on the login epilogue.
    @objc var siteInfo: SiteInfo?

    /// Flags whether a 2fa challenge had to be satisfied before a log in could be complete.
    /// Included in analytics after a successful login.
    @objc var requiredMultifactor = false // A 2fa prompt was needed.

    /// Identifies a social login and the service used.
    var socialService: SocialServiceName?

    @objc var socialServiceIDToken: String?
}
