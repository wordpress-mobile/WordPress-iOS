import UIKit
import CocoaLumberjack
import NSURL_IDN
import WordPressShared



// MARK: - WordPressAuthenticator Delegate Protocol
//
public protocol WordPressAuthenticatorDelegate: class {

    /// Indicates if the active Authenticator can be dismissed, or not.
    ///
    var dismissActionEnabled: Bool { get }

    /// Indicates if the Support button action should be enabled, or not.
    ///
    var supportActionEnabled: Bool { get }

    /// Indicates if the Livechat Action should be enabled, or not.
    ///
    var livechatActionEnabled: Bool { get }

    /// Returns the Support's Badge Count.
    ///
    var supportBadgeCount: Int { get }

    /// Refreshes Support's Badge Count.
    ///
    func refreshSupportBadgeCount()

    /// Presents the Support Interface from a given ViewController, with a specified SourceTag.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, options: [String: Any])

    /// Presents the Livechat Interface, from a given ViewController, with a specified SourceTag, and additional metadata,
    /// such as all of the User's Login details.
    ///
    func presentLivechat(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, options: [String: Any])
}


// MARK: - A collection of helper methods for NUX.
//
@objc public class WordPressAuthenticator: NSObject {

    /// Authenticator's Delegate.
    ///
    public weak var delegate: WordPressAuthenticatorDelegate?

    /// Shared Instance.
    ///
    public static let shared = WordPressAuthenticator()

    /// Notification to be posted whenever the signing flow completes.
    ///
    @objc static let WPSigninDidFinishNotification = "WPSigninDidFinishNotification"

    /// Internal Constants.
    ///
    fileprivate enum Constants {
        static let authenticationInfoKey = "authenticationInfoKey"
        static let jetpackBlogIDURL = "jetpackBlogIDURL"
        static let username = "username"
        static let emailMagicLinkSource = "emailMagicLinkSource"
    }


    // MARK: - Public MethodsauthenticationInfoKey

    func supportBadgeCountWasUpdated() {
        NotificationCenter.default.post(name: .wordpressSupportBadgeUpdated, object: nil)
    }

    // MARK: - Helpers for presenting the login flow

    /// Used to present the new login flow from the app delegate
    @objc class func showLoginFromPresenter(_ presenter: UIViewController, animated: Bool, thenEditor: Bool) {
        showLoginFromPresenter(presenter, animated: animated, thenEditor: thenEditor, showCancel: false)
    }

    class func showLoginFromPresenter(_ presenter: UIViewController, animated: Bool, thenEditor: Bool, showCancel: Bool) {
        defer {
            trackOpenedLogin()
        }

        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            if let childController = controller.childViewControllers.first as? LoginPrologueViewController {
                childController.showCancel = showCancel
            }
            presenter.present(controller, animated: animated, completion: nil)
        }
    }

    /// Used to present the new wpcom-only login flow from the app delegate
    @objc class func showLoginForJustWPComFromPresenter(_ presenter: UIViewController, forJetpackBlog blog: Blog? = nil) {
        defer {
            trackOpenedLogin()
        }

        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "emailEntry") as? LoginEmailViewController else {
            return
        }
        controller.restrictToWPCom = true
        if let blog = blog {
            controller.loginFields.meta.jetpackBlogID = blog.objectID
            if let email = blog.jetpack?.connectedEmail {
                controller.loginFields.username = email
            }
        }

        let navController = LoginNavigationController(rootViewController: controller)
        presenter.present(navController, animated: true, completion: nil)
    }

    /// Used to present the new self-hosted login flow from BlogListViewController
    @objc class func showLoginForSelfHostedSite(_ presenter: UIViewController) {
        defer {
            trackOpenedLogin()
        }

        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "siteAddress") as? LoginSiteAddressViewController else {
            return
        }

        let navController = LoginNavigationController(rootViewController: controller)
        presenter.present(navController, animated: true, completion: nil)
    }


    // Helper used by WPAuthTokenIssueSolver
    @objc class func signinForWPComFixingAuthToken(_ onDismissed: ((_ cancelled: Bool) -> Void)?) -> UIViewController {
        let context = ContextManager.sharedInstance().mainContext
        let loginFields = LoginFields()
        if let account = AccountService(managedObjectContext: context).defaultWordPressComAccount() {
            loginFields.emailAddress = account.email
            loginFields.username = account.username
        }

        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "LoginWPcomPassword") as? LoginWPComViewController else {
            fatalError("unable to create wpcom password screen")
        }

        controller.loginFields = loginFields
        controller.dismissBlock = onDismissed
        return NUXNavigationController(rootViewController: controller)
    }


    // Helper used by WPError
    @objc class func showSigninForWPComFixingAuthToken() {
        let controller = signinForWPComFixingAuthToken(nil)
        let presenter = UIApplication.shared.keyWindow?.rootViewController
        presenter?.present(controller, animated: true, completion: nil)

        trackOpenedLogin()
    }

    private class func trackOpenedLogin() {
        WordPressAuthenticator.post(event: .openedLogin)
    }


    // MARK: - Authentication Link Helpers


    /// Present a signin view controller to handle an authentication link.
    ///
    /// - Parameters:
    ///     - url: The authentication URL
    ///     - rootViewController: The view controller to act as the presenter for
    ///     the signin view controller. By convention this is the app's root vc.
    ///
    @objc class func openAuthenticationURL(_ url: URL, fromRootViewController rootViewController: UIViewController) -> Bool {
        guard let token = url.query?.dictionaryFromQueryString().string(forKey: "token") else {
            DDLogError("Signin Error: The authentication URL did not have the expected path.")
            return false
        }

        guard let loginFields = retrieveLoginInfoForTokenAuth() else {
            DDLogInfo("App opened with authentication link but info wasn't found for token.")
            return false
        }

        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if let account = accountService.defaultWordPressComAccount() {
            // The only time we should expect a magic link login when there is already a default wpcom account
            // is when a user is logging into Jetpack.
            if !loginFields.meta.jetpackLogin {
                DDLogInfo("App opened with authentication link but there is already an existing wpcom account. \(account)")
                return false
            }
        }

        let storyboard = UIStoryboard(name: "EmailMagicLink", bundle: nil)
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
                WordPressAuthenticator.post(event: .signupMagicLinkOpened)
            case .login:
                WordPressAuthenticator.post(event: .loginMagicLinkOpened)
            }
        }

        let navController = UINavigationController(rootViewController: controller)

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
        let presenter = controllerForAuthControllerPresenter(rootViewController)
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


    /// Determine the proper UIViewController to use as a presenter for the auth controller.
    ///
    /// - Parameter controller: A UIViewController. By convention this should be the app's rootViewController
    ///
    /// - Return: The view controller to use as the presenter.
    ///
    @objc class func controllerForAuthControllerPresenter(_ controller: UIViewController) -> UIViewController {
        var presenter = controller
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        return presenter
    }


    // MARK: - Site URL helper


    /// The base site URL path derived from `loginFields.siteUrl`
    ///
    /// - Parameter string: The source URL as a string.
    ///
    /// - Returns: The base URL or an empty string.
    ///
    @objc class func baseSiteURL(string: String) -> String {
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
            path = "http://\(path)"
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
        if let url = loginFields.meta.jetpackBlogID?.uriRepresentation().absoluteString {
            dict[Constants.jetpackBlogIDURL] = url
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

        let store = ContextManager.sharedInstance().persistentStoreCoordinator
        if  let path = dict[Constants.jetpackBlogIDURL] as? String,
            let url = URL(string: path),
            let objectID = store.managedObjectID(forURIRepresentation: url) {
            loginFields.meta.jetpackBlogID = objectID
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

            WordPressAuthenticator.post(event: .onePasswordLogin)
            success(loginFields)

        }, failure: { error in
            guard error != .cancelledByUser else {
                return
            }

            DDLogError("OnePassword Error: \(error.localizedDescription)")
            WordPressAuthenticator.post(event: .onePasswordFailed)
        })
    }
}
