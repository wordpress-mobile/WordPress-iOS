import UIKit
import CocoaLumberjack
import NSURL_IDN
import GoogleSignIn
import WordPressShared
import WordPressUI



// MARK: - WordPress Credentials
//
public enum WordPressCredentials {

    /// WordPress.org Site Credentials.
    ///
    case wporg(username: String, password: String, xmlrpc: String, options: [AnyHashable: Any])

    /// WordPress.com Site Credentials.
    ///
    case wpcom(username: String, authToken: String, isJetpackLogin: Bool, multifactor: Bool)
}

// MARK: - Social Services Metadata
//
public enum SocialService {

    /// Google's Signup Linked Account
    ///
    case google(user: GIDGoogleUser)
}

// MARK: - WordPressAuthenticator Delegate Protocol
//
public protocol WordPressAuthenticatorDelegate: class {

    /// Indicates if the active Authenticator can be dismissed, or not.
    ///
    var dismissActionEnabled: Bool { get }

    /// Indicates if the Support button action should be enabled, or not.
    ///
    var supportActionEnabled: Bool { get }

    /// Indicates if the Support notification indicator should be displayed.
    ///
    var showSupportNotificationIndicator: Bool { get }
    
    /// Indicates if Support is available or not.
    ///
    var supportEnabled: Bool { get }

    /// Returns the Support's Badge Count.
    ///
    var supportBadgeCount: Int { get }

    /// Signals the Host App that a new WordPress.com account has just been created.
    ///
    /// - Parameters:
    ///     - username: WordPress.com Username.
    ///     - authToken: WordPress.com Bearer Token.
    ///     - onCompletion: Closure to be executed on completion.
    ///
    func createdWordPressComAccount(username: String, authToken: String)

    /// Presents the Support new request, from a given ViewController, with a specified SourceTag, and additional metadata,
    /// such as all of the User's Login details.
    ///
    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, options: [String: Any])

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: WordPressCredentials, onDismiss: @escaping () -> Void)

    /// Presents the Login Epilogue, in the specified NavigationController.
    ///
    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: WordPressCredentials, service: SocialService?)

    /// Presents the Support Interface from a given ViewController, with a specified SourceTag.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, options: [String: Any])

    /// Refreshes Support's Badge Count.
    ///
    func refreshSupportBadgeCount()

    /// Indicates if the Login Epilogue should be displayed.
    ///
    /// - Parameter isJetpackLogin: Indicates if we've just logged into a WordPress.com account for Jetpack purposes!.
    ///
    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool

    /// Indicates if the Signup Epilogue should be displayed.
    ///
    func shouldPresentSignupEpilogue() -> Bool

    /// Signals the Host App that a WordPress Site (wpcom or wporg) is available with the specified credentials.
    ///
    /// - Parameters:
    ///     - credentials: WordPress Site Credentials.
    ///     - onCompletion: Closure to be executed on completion.
    ///
    func sync(credentials: WordPressCredentials, onCompletion: @escaping (Error?) -> Void)

    /// Signals the Host App that a given Analytics Event has occurred.
    ///
    func track(event: WPAnalyticsStat)

    /// Signals the Host App that a given Analytics Event (with the specified properties) has occurred.
    ///
    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any])

    /// Signals the Host App that a given Analytics Event (with an associated Error) has occurred.
    ///
    func track(event: WPAnalyticsStat, error: Error)
}


// MARK: - WordPressAuthenticator Configuration
//
public struct WordPressAuthenticatorConfiguration {

    /// WordPress.com Client ID
    ///
    let wpcomClientId: String

    /// WordPress.com Secret
    ///
    let wpcomSecret: String

    /// Client App: Used for Magic Link purposes.
    ///
    let wpcomScheme: String

    /// WordPress.com Terms of Service URL
    ///
    let wpcomTermsOfServiceURL: String

    /// GoogleLogin Client ID
    ///
    let googleLoginClientId: String

    /// GoogleLogin ServerClient ID
    ///
    let googleLoginServerClientId: String

    /// UserAgent
    ///
    let userAgent: String

    /// Used to determine which view to use for new Support notifications.
    ///
    let supportNotificationIndicatorFeatureFlag: Bool
    
    /// Designated Initializer
    ///
    public init (wpcomClientId: String,
                 wpcomSecret: String,
                 wpcomScheme: String,
                 wpcomTermsOfServiceURL: String,
                 googleLoginClientId: String,
                 googleLoginServerClientId: String,
                 userAgent: String,
                 supportNotificationIndicatorFeatureFlag: Bool) {
        self.wpcomClientId = wpcomClientId
        self.wpcomSecret = wpcomSecret
        self.wpcomScheme = wpcomScheme
        self.wpcomTermsOfServiceURL = wpcomTermsOfServiceURL
        self.googleLoginClientId =  googleLoginClientId
        self.googleLoginServerClientId = googleLoginServerClientId
        self.userAgent = userAgent
        self.supportNotificationIndicatorFeatureFlag = supportNotificationIndicatorFeatureFlag
    }
}


// MARK: - WordPressAuthenticator: Public API to deal with WordPress.com and WordPress.org authentication.
//
@objc public class WordPressAuthenticator: NSObject {

    /// (Private) Shared Instance.
    ///
    private static var privateInstance: WordPressAuthenticator?

    /// Shared Instance.
    ///
    @objc public static var shared: WordPressAuthenticator {
        guard let privateInstance = privateInstance else {
            fatalError("WordPressAuthenticator wasn't initialized")
        }

        return privateInstance
    }

    /// Authenticator's Delegate.
    ///
    public weak var delegate: WordPressAuthenticatorDelegate?

    /// Authenticator's Configuration.
    ///
    public let configuration: WordPressAuthenticatorConfiguration

    /// Notification to be posted whenever the signing flow completes.
    ///
    @objc public static let WPSigninDidFinishNotification = "WPSigninDidFinishNotification"

    /// Internal Constants.
    ///
    private enum Constants {
        static let authenticationInfoKey    = "authenticationInfoKey"
        static let jetpackBlogXMLRPC        = "jetpackBlogXMLRPC"
        static let jetpackBlogUsername      = "jetpackBlogUsername"
        static let username                 = "username"
        static let emailMagicLinkSource     = "emailMagicLinkSource"
    }

    // MARK: - Initialization

    /// Designated Initializer
    ///
    private init(configuration: WordPressAuthenticatorConfiguration) {
        self.configuration = configuration
    }

    /// Initializes the WordPressAuthenticator with the specified Configuration.
    ///
    public static func initialize(configuration: WordPressAuthenticatorConfiguration) {
        guard privateInstance == nil else {
            fatalError("WordPressAuthenticator is already initialized")
        }

        privateInstance = WordPressAuthenticator(configuration: configuration)
    }

    // MARK: - Public Methods

    public func supportBadgeCountWasUpdated() {
        NotificationCenter.default.post(name: .wordpressSupportBadgeUpdated, object: nil)
    }
    
    public func supportPushNotificationReceived() {
        NotificationCenter.default.post(name: .wordpressSupportNotificationReceived, object: nil)
    }

    public func supportPushNotificationCleared() {
        NotificationCenter.default.post(name: .wordpressSupportNotificationCleared, object: nil)
    }
    
    /// Indicates if the specified ViewController belongs to the Authentication Flow, or not.
    ///
    public class func isAuthenticationViewController(_ viewController: UIViewController) ->  Bool {
        return viewController is LoginPrologueViewController || viewController is NUXViewControllerBase
    }

    /// Indicates if the specified URL is a Google Authentication Link.
    ///
    @objc public class func isGoogleAuthURL(url: URL, sourceApplication: String?, annotation: Any?) -> Bool {
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }


    // MARK: - Helpers for presenting the login flow

    /// Used to present the new login flow from the app delegate
    @objc public class func showLoginFromPresenter(_ presenter: UIViewController, animated: Bool) {
        showLogin(from: presenter, animated: animated)
    }

    public class func showLogin(from presenter: UIViewController, animated: Bool, showCancel: Bool = false, restrictToWPCom: Bool = false) {
        defer {
            trackOpenedLogin()
        }

        let storyboard = UIStoryboard(name: "Login", bundle: bundle)
        if let controller = storyboard.instantiateInitialViewController() {
            if let childController = controller.childViewControllers.first as? LoginPrologueViewController {
                childController.restrictToWPCom = restrictToWPCom
                childController.showCancel = showCancel
            }
            presenter.present(controller, animated: animated, completion: nil)
        }
    }

    /// Used to present the new wpcom-only login flow from the app delegate
    @objc public class func showLoginForJustWPCom(from presenter: UIViewController, xmlrpc: String? = nil, username: String? = nil, connectedEmail: String? = nil) {
        defer {
            trackOpenedLogin()
        }

        let storyboard = UIStoryboard(name: "Login", bundle: bundle)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "emailEntry") as? LoginEmailViewController else {
            return
        }

        controller.restrictToWPCom = true
        controller.loginFields.meta.jetpackBlogXMLRPC = xmlrpc
        controller.loginFields.meta.jetpackBlogUsername = username

        if let email = connectedEmail {
            controller.loginFields.username = email
        } else {
            controller.offerSignupOption = true
        }

        let navController = LoginNavigationController(rootViewController: controller)
        presenter.present(navController, animated: true, completion: nil)
    }


    /// Used to present the new self-hosted login flow from BlogListViewController
    @objc public class func showLoginForSelfHostedSite(_ presenter: UIViewController) {
        defer {
            trackOpenedLogin()
        }

        let controller = signinForWPOrg()
        let navController = LoginNavigationController(rootViewController: controller)

        presenter.present(navController, animated: true, completion: nil)
    }

    /// Returns an instance of LoginSiteAddressViewController: allows the user to log into a WordPress.org website.
    ///
    @objc public class func signinForWPOrg() -> UIViewController {
        let storyboard = UIStoryboard(name: "Login", bundle: bundle)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "siteAddress") as? LoginSiteAddressViewController else {
            fatalError("unable to create wpcom password screen")
        }

        return controller
    }


    // Helper used by WPAuthTokenIssueSolver
    @objc
    public class func signinForWPCom(dotcomEmailAddress: String?, dotcomUsername: String?, onDismissed: ((_ cancelled: Bool) -> Void)? = nil) -> UIViewController {
        let loginFields = LoginFields()
        loginFields.emailAddress = dotcomEmailAddress ?? String()
        loginFields.username = dotcomUsername ?? String()

        let storyboard = UIStoryboard(name: "Login", bundle: bundle)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "LoginWPcomPassword") as? LoginWPComViewController else {
            fatalError("unable to create wpcom password screen")
        }

        controller.loginFields = loginFields
        controller.dismissBlock = onDismissed

        return NUXNavigationController(rootViewController: controller)
    }

    private class func trackOpenedLogin() {
        WordPressAuthenticator.track(.openedLogin)
    }


    // MARK: - Authentication Link Helpers


    /// Present a signin view controller to handle an authentication link.
    ///
    /// - Parameters:
    ///     - url: The authentication URL
    ///     - allowWordPressComAuth: Indicates if WordPress.com Authentication Links should be handled, or not.
    ///     - rootViewController: The view controller to act as the presenter for the signin view controller.
    ///                           By convention this is the app's root vc.
    ///
    @objc public class func openAuthenticationURL(_ url: URL, allowWordPressComAuth: Bool, fromRootViewController rootViewController: UIViewController) -> Bool {
        guard let token = url.query?.dictionaryFromQueryString().string(forKey: "token") else {
            DDLogError("Signin Error: The authentication URL did not have the expected path.")
            return false
        }

        guard let loginFields = retrieveLoginInfoForTokenAuth() else {
            DDLogInfo("App opened with authentication link but info wasn't found for token.")
            return false
        }

        // The only time we should expect a magic link login when there is already a default wpcom account
        // is when a user is logging into Jetpack.
        if allowWordPressComAuth == false && loginFields.meta.jetpackLogin == false {
            DDLogInfo("App opened with authentication link but there is already an existing wpcom account.")
            return false
        }

        let storyboard = UIStoryboard(name: "EmailMagicLink", bundle: bundle)
        guard let loginController = storyboard.instantiateViewController(withIdentifier: "LinkAuthView") as? NUXLinkAuthViewController else {
            DDLogInfo("App opened with authentication link but couldn't create login screen.")
            return false
        }
        loginController.loginFields = loginFields
        loginController.email = loginFields.username
        loginController.token = token
        let controller = loginController

        if let linkSource = loginFields.meta.emailMagicLinkSource {
            switch linkSource {
            case .signup:
                WordPressAuthenticator.track(.signupMagicLinkOpened)
            case .login:
                WordPressAuthenticator.track(.loginMagicLinkOpened)
            }
        }

        let navController = LoginNavigationController(rootViewController: controller)

        // The way the magic link flow works some view controller might
        // still be presented when the app is resumed by tapping on the auth link.
        // We need to do a little work to present the SigninLinkAuth controller
        // from the right place.
        // - If the rootViewController is not presenting another vc then just
        // present the auth controller.
        // - If the rootViewController is presenting another NUX vc, dismiss the
        // NUX vc then present the auth controller.
        // - If the rootViewController is presenting *any* other vc, present the
        // auth controller from the presented vc.
        let presenter = rootViewController.topmostPresentedViewController
        if presenter.isKind(of: NUXNavigationController.self) || presenter.isKind(of: LoginNavigationController.self),
            let parent = presenter.presentingViewController {
            parent.dismiss(animated: false, completion: {
                parent.present(navController, animated: false, completion: nil)
            })
        } else {
            presenter.present(navController, animated: false, completion: nil)
        }

        deleteLoginInfoForTokenAuth()
        return true
    }


    // MARK: - Site URL helper


    /// The base site URL path derived from `loginFields.siteUrl`
    ///
    /// - Parameter string: The source URL as a string.
    ///
    /// - Returns: The base URL or an empty string.
    ///
    class func baseSiteURL(string: String) -> String {
        guard let siteURL = NSURL(string: NSURL.idnEncodedURL(string)), string.count > 0 else {
            return ""
        }

        var path = siteURL.absoluteString!
        let isSiteURLSchemeEmpty = siteURL.scheme == nil || siteURL.scheme!.isEmpty

        if path.isWordPressComPath() {
            if isSiteURLSchemeEmpty {
                path = "https://\(path)"
            } else if path.range(of: "http://") != nil {
                path = path.replacingOccurrences(of: "http://", with: "https://")
            }
        } else if isSiteURLSchemeEmpty {
            path = "https://\(path)"
        }

        path.removeSuffix("/wp-login.php")
        try? path.removeSuffix(pattern: "/wp-admin/?")
        path.removeSuffix("/")

        return NSURL.idnDecodedURL(path)
    }


    // MARK: - Helpers for Saved Magic Link Info

    /// Saves certain login information in NSUserDefaults
    ///
    /// - Parameter loginFields: The loginFields instance from which to save.
    ///
    class func storeLoginInfoForTokenAuth(_ loginFields: LoginFields) {
        var dict: [String: String] = [
            Constants.username: loginFields.username
        ]
        if let xmlrpc = loginFields.meta.jetpackBlogXMLRPC {
            dict[Constants.jetpackBlogXMLRPC] = xmlrpc
        }

        if let username = loginFields.meta.jetpackBlogUsername {
            dict[Constants.jetpackBlogUsername] = username
        }

        if let linkSource = loginFields.meta.emailMagicLinkSource {
            dict[Constants.emailMagicLinkSource] = String(linkSource.rawValue)
        }

        UserDefaults.standard.set(dict, forKey: Constants.authenticationInfoKey)
    }


    /// Retrieves stored login information if any.
    ///
    /// - Returns: A loginFields instance or nil.
    ///
    class func retrieveLoginInfoForTokenAuth() -> LoginFields? {

        guard let dict = UserDefaults.standard.dictionary(forKey: Constants.authenticationInfoKey) else {
            return nil
        }

        let loginFields = LoginFields()
        if let username = dict[Constants.username] as? String {
            loginFields.username = username
        }

        if let linkSource = dict[Constants.emailMagicLinkSource] as? String,
            let linkSourceRawValue = Int(linkSource) {
            loginFields.meta.emailMagicLinkSource = EmailMagicLinkSource(rawValue: linkSourceRawValue)
        }

        if let xmlrpc = dict[Constants.jetpackBlogXMLRPC] as? String {
            loginFields.meta.jetpackBlogXMLRPC = xmlrpc
        }

        if let username = dict[Constants.jetpackBlogUsername] as? String {
            loginFields.meta.jetpackBlogUsername = username
        }

        return loginFields
    }


    /// Removes stored login information from NSUserDefaults
    ///
    class func deleteLoginInfoForTokenAuth() {
        UserDefaults.standard.removeObject(forKey: Constants.authenticationInfoKey)
    }


    // MARK: - Other Helpers


    /// Opens Safari to display the forgot password page for a wpcom or self-hosted
    /// based on the passed LoginFields instance.
    ///
    /// - Parameter loginFields: A LoginFields instance.
    ///
    class func openForgotPasswordURL(_ loginFields: LoginFields) {
        let baseURL = loginFields.meta.userIsDotCom ? "https://wordpress.com" : WordPressAuthenticator.baseSiteURL(string: loginFields.siteAddress)
        let forgotPasswordURL = URL(string: baseURL + "/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F")!
        UIApplication.shared.open(forgotPasswordURL)
    }

    /// Returns the WordPressAuthenticator Bundle
    ///
    class var bundle: Bundle {
        return Bundle(for: WordPressAuthenticator.self)
    }


    // MARK: - 1Password Helper


    /// Request credentails from 1Password (if supported)
    ///
    /// - Parameter sender: A UIView. Typically the button the user tapped on.
    ///
    class func fetchOnePasswordCredentials(_ controller: UIViewController, sourceView: UIView, loginFields: LoginFields, success: @escaping ((_ loginFields: LoginFields) -> Void)) {

        let loginURL = loginFields.meta.userIsDotCom ? OnePasswordDefaults.dotcomURL : loginFields.siteAddress

        OnePasswordFacade().findLogin(for: loginURL, viewController: controller, sender: sourceView, success: { (username, password, otp) in
            loginFields.username = username
            loginFields.password = password
            loginFields.multifactorCode = otp ?? String()

            WordPressAuthenticator.track(.onePasswordLogin)
            success(loginFields)

        }, failure: { error in
            guard error != .cancelledByUser else {
                return
            }

            DDLogError("OnePassword Error: \(error.localizedDescription)")
            WordPressAuthenticator.track(.onePasswordFailed)
        })
    }
}
