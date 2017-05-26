import UIKit
import NSURL_IDN
import WordPressComAnalytics

/// A collection of helper methods for NUX.
///
@objc class SigninHelpers: NSObject {
    fileprivate static let AuthenticationEmailKey = "AuthenticationEmailKey"
    fileprivate static let WPComSuffix = ".wordpress.com"
    @objc static let WPSigninDidFinishNotification = "WPSigninDidFinishNotification"


    // MARK: - Helpers for presenting the signin flow

    // Convenience factory for the signin flow's first vc
    class func createControllerForSigninFlow(showsEditor thenEditor: Bool) -> UIViewController {
        let controller = SigninEmailViewController.controller()
        controller.dismissBlock = {(cancelled) in
            // Show the editor if requested, and we weren't cancelled.
            if !cancelled && thenEditor {
                WPTabBarController.sharedInstance().showPostTab()
                return
            }
        }
        return controller
    }

    /// Used to present the signin flow from the app delegate
    class func showSigninFromPresenter(_ presenter: UIViewController, animated: Bool, thenEditor: Bool) {
        if Feature.enabled(.newLogin) {
            showLoginFromPresenter(presenter, animated: animated, thenEditor: thenEditor)
            return
        }
        let controller = createControllerForSigninFlow(showsEditor: thenEditor)
        let navController = NUXNavigationController(rootViewController: controller)
        presenter.present(navController, animated: animated, completion: nil)

        trackOpenedLogin()
    }

    /// Used to present the new login flow from the app delegate
    fileprivate class func showLoginFromPresenter(_ presenter: UIViewController, animated: Bool, thenEditor: Bool) {
        defer {
            trackOpenedLogin()
        }

        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() as? NUXNavigationController {
            presenter.present(controller, animated: animated, completion: nil)
        }
    }


    /// Used to present the wpcom-only signin flow from the app delegate
    class func showSigninForJustWPComFromPresenter(_ presenter: UIViewController) {
        if Feature.enabled(.newLogin) {
            showLoginForJustWPComFromPresenter(presenter)
            return
        }

        let controller = SigninEmailViewController.controller()
        controller.restrictToWPCom = true

        let navController = NUXNavigationController(rootViewController: controller)
        presenter.present(navController, animated: true, completion: nil)

        trackOpenedLogin()
    }

    /// Used to present the new wpcom-only login flow from the app delegate
    fileprivate class func showLoginForJustWPComFromPresenter(_ presenter: UIViewController) {
        defer {
            trackOpenedLogin()
        }

        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "emailEntry") as? NUXAbstractViewController else {
            return
        }
        controller.restrictToWPCom = true

        let navController = NUXNavigationController(rootViewController: controller)
        presenter.present(navController, animated: true, completion: nil)
    }


    /// Used to present the self-hosted signin flow from BlogListViewController
    class func showSigninForSelfHostedSite(_ presenter: UIViewController) {
        if Feature.enabled(.newLogin) {
            showLoginForSelfHostedSite(presenter)
            return
        }

        let controller = SigninSelfHostedViewController.controller(LoginFields())
        let navController = NUXNavigationController(rootViewController: controller)
        presenter.present(navController, animated: true, completion: nil)

        trackOpenedLogin()
    }

    /// Used to present the new self-hosted login flow from BlogListViewController
    fileprivate class func showLoginForSelfHostedSite(_ presenter: UIViewController) {
        defer {
            trackOpenedLogin()
        }

        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "selfHosted") as? NUXAbstractViewController else {
            return
        }

        let navController = NUXNavigationController(rootViewController: controller)
        presenter.present(navController, animated: true, completion: nil)
    }


    // Helper used by WPAuthTokenIssueSolver
    class func signinForWPComFixingAuthToken(_ onDismissed: ((_ cancelled: Bool) -> Void)?) -> UIViewController {
        let context = ContextManager.sharedInstance().mainContext
        let loginFields = LoginFields()
        if let account = AccountService(managedObjectContext: context).defaultWordPressComAccount() {
            loginFields.username = account.username
        }

        let controller = SigninWPComViewController.controller(loginFields)
        controller.restrictToWPCom = true
        controller.dismissBlock = onDismissed
        return NUXNavigationController(rootViewController: controller)
    }


    // Helper used by WPError
    class func showSigninForWPComFixingAuthToken() {
        let controller = signinForWPComFixingAuthToken(nil)
        let presenter = UIApplication.shared.keyWindow?.rootViewController
        presenter?.present(controller, animated: true, completion: nil)

        trackOpenedLogin()
    }

    private class func trackOpenedLogin() {
        WPAppAnalytics.track(.openedLogin)
    }


    // MARK: - Authentication Link Helpers


    /// Present a signin view controller to handle an authentication link.
    ///
    /// - Parameters:
    ///     - url: The authentication URL
    ///     - rootViewController: The view controller to act as the presenter for
    ///     the signin view controller. By convention this is the app's root vc.
    ///
    class func openAuthenticationURL(_ url: URL, fromRootViewController rootViewController: UIViewController) -> Bool {
        guard let token = url.query?.dictionaryFromQueryString().string(forKey: "token") else {
            DDLogSwift.logError("Signin Error: The authentication URL did not have the expected path.")
            return false
        }

        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        if let account = accountService.defaultWordPressComAccount() {
            DDLogSwift.logInfo("App opened with authentication link but there is already an existing wpcom account. \(account)")
            return false
        }

        var controller: UIViewController
        if let email = getEmailAddressForTokenAuth() {
            controller = SigninLinkAuthViewController.controller(email, token: token)
            WPAppAnalytics.track(.loginMagicLinkOpened)
        } else {
            controller = SigninEmailViewController.controller()
        }
        let navController = UINavigationController(rootViewController: controller)

        // The way the magic link flow works the `SigninLinkMailViewController`,
        // or some other view controller, might still be presented when the app
        // is resumed by tapping on the auth link.
        // We need to do a little work to present the SigninLinkAuth controller
        // from the right place.
        // - If the rootViewController is not presenting another vc then just
        // present the auth controller.
        // - If the rootViewController is presenting another NUX vc, dismiss the
        // NUX vc then present the auth controller.
        // - If the rootViewController is presenting *any* other vc, present the
        // auth controller from the presented vc.
        if let presenter = rootViewController.presentedViewController, presenter.isKind(of: NUXNavigationController.self) {
            rootViewController.dismiss(animated: false, completion: {
                rootViewController.present(navController, animated: false, completion: nil)
            })
        } else {
            let presenter = controllerForAuthControllerPresenter(rootViewController)
            presenter.present(navController, animated: false, completion: nil)
        }

        deleteEmailAddressForTokenAuth()
        return true
    }


    /// Determine the proper UIViewController to use as a presenter for the auth controller.
    ///
    /// - Parameter controller: A UIViewController. By convention this should be the app's rootViewController
    ///
    /// - Return: The view controller to use as the presenter.
    ///
    class func controllerForAuthControllerPresenter(_ controller: UIViewController) -> UIViewController {
        var presenter = controller
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        return presenter
    }


    /// Check if the specified controller was presented from the application's root vc.
    ///
    /// - Parameter controller: A UIViewController
    ///
    /// - Return: True if presented from the root vc.
    ///
    class func controllerWasPresentedFromRootViewController(_ controller: UIViewController) -> Bool {
        guard let presentingViewController = controller.presentingViewController else {
            return false
        }
        return presentingViewController == UIApplication.shared.keyWindow?.rootViewController
    }


    // MARK: - Site URL helper


    /// The base site URL path derived from `loginFields.siteUrl`
    ///
    /// - Parameter string: The source URL as a string.
    ///
    /// - Returns: The base URL or an empty string.
    ///
    class func baseSiteURL(string: String) -> String {
        guard let siteURL = NSURL(string: NSURL.idnEncodedURL(string)), string.characters.count > 0 else {
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


    // MARK: - Validation Helpers


    /// Checks if the passed string matches a reserved username.
    ///
    /// - Parameter username: The username to test.
    ///
    class func isUsernameReserved(_ username: String) -> Bool {
        let name = username.lowercased().trim()
        return ["admin", "administrator", "invite", "main", "root", "web", "www"].contains(name) || name.contains("wordpress")
    }

    /// Checks if the provided username is a wordpress.com domain
    ///
    /// - Parameter username: the username to test
    /// - Returns: true if the username is a wordpress.com domain
    class func isWPComDomain(_ username: String) -> Bool {
        return username.contains(WPComSuffix)
    }

    /// Extracts the username from a wordpress.com domain
    class func extractUsername(from hostname: String) -> String {
        var host = hostname
        if let hostParsed = URL(string: hostname)?.host {
            host = hostParsed
        }
        return host.components(separatedBy: WPComSuffix).first ?? host
    }

    /// Checks whether credentials have been populated.
    /// Note: that loginFields.emailAddress is not checked. Use loginFields.username instead.
    ///
    /// - Parameter loginFields: An instance of LoginFields to check
    ///
    /// - Returns: True if credentails have been provided. False otherwise.
    ///
    class func validateFieldsPopulatedForSignin(_ loginFields: LoginFields) -> Bool {
        return !loginFields.username.isEmpty &&
            !loginFields.password.isEmpty &&
            ( loginFields.userIsDotCom || !loginFields.siteUrl.isEmpty )
    }


    /// Simple validation check to confirm LoginFields has a valid site URL.
    ///
    /// - Parameter loginFields: An instance of LoginFields to check
    ///
    /// - Returns: True if the siteUrl contains a valid URL. False otherwise.
    ///
    class func validateSiteForSignin(_ loginFields: LoginFields) -> Bool {
        guard let url = URL(string: NSURL.idnEncodedURL(loginFields.siteUrl)) else {
            return false
        }

        if url.absoluteString.isEmpty {
            return false
        }

        return true
    }


    class func promptForWPComReservedUsername(_ username: String, callback: @escaping () -> Void) {
        let title = NSLocalizedString("Reserved Username", comment: "The title of a prompt")
        let format = NSLocalizedString("'%@' is a reserved username on WordPress.com.",
                                        comment: "Error message letting the user know the username they entered is reserved. The %@ is a placeholder for the username.")
        let message = NSString(format: format as NSString, username) as String
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("OK", comment: "OK Button Title"), handler: {(action) in
            callback()
        })
        alertController.presentFromRootViewController()
    }


    /// Checks whether necessary info for account creation has been provided.
    ///
    /// - Parameters:
    ///     - loginFields: An instance of LoginFields to check
    ///
    /// - Returns: True if credentails have been provided. False otherwise.
    ///
    class func validateFieldsPopulatedForCreateAccount(_ loginFields: LoginFields) -> Bool {
        return !loginFields.emailAddress.isEmpty &&
            !loginFields.username.isEmpty &&
            !loginFields.password.isEmpty &&
            !loginFields.siteUrl.isEmpty
    }


    /// Ensures there are no spaces in fields used for signin, (except the password field).
    ///
    /// - Parameters:
    ///     - loginFields: An instance of LoginFields to check
    ///
    /// - Returns: True if no spaces were found. False if spaces were found.
    ///
    class func validateFieldsForSigninContainNoSpaces(_ loginFields: LoginFields) -> Bool {
        let space = " "
        return !loginFields.emailAddress.contains(space) &&
            !loginFields.username.contains(space) &&
            !loginFields.siteUrl.contains(space)
    }


    /// Verify a username is 50 characters or less.
    ///
    /// - Parameters:
    ///     - username: The username to check
    ///
    /// - Returns: True if the username is 50 characters or less.
    ///
    class func validateUsernameMaxLength(_ username: String) -> Bool {
        return username.characters.count <= 50
    }


    // MARK: - Helpers for Saved Magic Link Email


    /// Saves the specified email address in NSUserDefaults
    ///
    /// - Parameter email: The email address to save.
    ///
    class func saveEmailAddressForTokenAuth(_ email: String) {
        UserDefaults.standard.set(email, forKey: AuthenticationEmailKey)
    }


    /// Removes the saved email address from NSUserDefaults
    ///
    class func deleteEmailAddressForTokenAuth() {
        UserDefaults.standard.removeObject(forKey: AuthenticationEmailKey)
    }


    /// Fetches a saved email address if one exists.
    ///
    /// - Returns: The email address as a string or nil.
    ///
    class func getEmailAddressForTokenAuth() -> String? {
        return UserDefaults.standard.string(forKey: AuthenticationEmailKey)
    }


    // MARK: - Other Helpers


    /// Opens Safari to display the forgot password page for a wpcom or self-hosted
    /// based on the passed LoginFields instance.
    ///
    /// - Parameter loginFields: A LoginFields instance.
    ///
    class func openForgotPasswordURL(_ loginFields: LoginFields) {
        let baseURL = loginFields.userIsDotCom ? "https://wordpress.com" : SigninHelpers.baseSiteURL(string: loginFields.siteUrl)
        let forgotPasswordURL = URL(string: baseURL + "/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F")!
        UIApplication.shared.open(forgotPasswordURL)
    }



    // MARK: - 1Password Helper


    /// Request credentails from 1Password (if supported)
    ///
    /// - Parameter sender: A UIView. Typically the button the user tapped on.
    ///
    class func fetchOnePasswordCredentials(_ controller: UIViewController, sourceView: UIView, loginFields: LoginFields, success: @escaping ((_ loginFields: LoginFields) -> Void)) {

        let loginURL = loginFields.userIsDotCom ? "wordpress.com" : loginFields.siteUrl


        let completion: OnePasswordFacadeCallback = { (username, password, oneTimePassword, error) in
            if let error = error {
                DDLogSwift.logError("OnePassword Error: \(error.localizedDescription)")
                WPAppAnalytics.track(.onePasswordFailed)
                return
            }

            guard let username = username, let password = password else {
                return
            }

            if username.isEmpty || password.isEmpty {
                return
            }

            loginFields.username = username
            loginFields.password = password

            if let oneTimePassword = oneTimePassword {
                loginFields.multifactorCode = oneTimePassword
            }

            WPAppAnalytics.track(.onePasswordLogin)

            success(loginFields)
        }

        let onePasswordFacade = OnePasswordFacade()
        onePasswordFacade.findLogin(forURLString: loginURL, viewController: controller, sender: sourceView, completion: completion)
    }


    // MARK: - Safari Stored Credentials Helpers


    static let LoginSharedWebCredentialFQDN: CFString = "wordpress.com" as CFString
    typealias SharedWebCredentialsCallback = ((_ credentialsFound: Bool, _ username: String?, _ password: String?) -> Void)


    /// Update safari stored credentials.
    ///
    /// - Parameter loginFields: An instance of LoginFields
    ///
    class func updateSafariCredentialsIfNeeded(_ loginFields: LoginFields) {
        // Paranioa. Don't try and update credentials for self-hosted.
        if !loginFields.userIsDotCom {
            return
        }

        // If the user changed screen names, don't try and update/create a new shared web credential.
        // We'll let Safari handle creating newly saved usernames/passwords.
        if loginFields.safariStoredUsernameHash != loginFields.username.hash {
            return
        }

        // If the user didn't change the password from previousl filled password no update is needed.
        if loginFields.safariStoredPasswordHash == loginFields.password.hash {
            return
        }

        // Update the shared credential
        let username: CFString = loginFields.username as CFString
        let password: CFString = loginFields.password as CFString

        SecAddSharedWebCredential(LoginSharedWebCredentialFQDN, username, password, { (error: CFError?) in
            guard error == nil else {
                let err = error
                DDLogSwift.logError("Error occurred updating shared web credential: \(String(describing: err?.localizedDescription))")
                return
            }
            DispatchQueue.main.async(execute: {
                WPAppAnalytics.track(.loginAutoFillCredentialsUpdated)
            })
        })
    }


    /// Request shared safari credentials if they exist.
    ///
    /// - Parameter completion: A completion block.
    ///
    class func requestSharedWebCredentials(_ completion: @escaping SharedWebCredentialsCallback) {
        SecRequestSharedWebCredential(LoginSharedWebCredentialFQDN, nil, { (credentials: CFArray?, error: CFError?) in
            DDLogSwift.logInfo("Completed requesting shared web credentials")
            guard error == nil else {
                let err = error as Error?
                if let error = err as NSError?, error.code == -25300 {
                    // An OSStatus of -25300 is expected when no saved credentails are found.
                    DDLogSwift.logInfo("No shared web credenitals found.")
                } else {
                    DDLogSwift.logError("Error requesting shared web credentials: \(String(describing: err?.localizedDescription))")
                }
                DispatchQueue.main.async(execute: {
                    completion(false, nil, nil)
                })
                return
            }

            guard let credentials = credentials, CFArrayGetCount(credentials) > 0 else {
                // Saved credentials exist but were not selected.
                DispatchQueue.main.async(execute: {
                    completion(true, nil, nil)
                })
                return
            }

            // What a chore!
            let unsafeCredentials = CFArrayGetValueAtIndex(credentials, 0)
            let credentialsDict = unsafeBitCast(unsafeCredentials, to: CFDictionary.self)

            let unsafeUsername = CFDictionaryGetValue(credentialsDict, Unmanaged.passUnretained(kSecAttrAccount).toOpaque())
            let usernameStr = unsafeBitCast(unsafeUsername, to: CFString.self) as String

            let unsafePassword = CFDictionaryGetValue(credentialsDict, Unmanaged.passUnretained(kSecSharedPassword).toOpaque())
            let passwordStr = unsafeBitCast(unsafePassword, to: CFString.self) as String

            DispatchQueue.main.async(execute: {
                completion(true, usernameStr, passwordStr)
            })
        })
    }
}
