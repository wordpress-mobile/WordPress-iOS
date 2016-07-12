import UIKit
import NSURL_IDN
import WordPressComAnalytics
import Mixpanel


/// A collection of helper methods for NUX.
///
@objc class SigninHelpers: NSObject
{
    private static let AuthenticationEmailKey = "AuthenticationEmailKey"
    private static let JoinABTestTimeoutInSeconds: NSTimeInterval = 2

    // MARK: - AB test related methods


    /// Loads the mixpanel experiments (if necessary) and shows a variant of the sign in flow.
    /// A call is made to join mixpanel experiements, passing a callback to show
    /// the relevant sign in variant. To compensate for latency, a brief timer is
    /// scheduled to do the same task.  Regardless of whether the timer or the
    /// callback is performed first the second call will be ignored by design.
    ///
    class func loadABTestThenShowSigninController() {
        guard let rootController = WordPressAppDelegate.sharedInstance().window.rootViewController else {
            assertionFailure("Missing a rootViewController.")
            return
        }

        if useNewSigninFlow() {
            // We know we're using a varient so proceeed without wait.
            SigninHelpers.showSigninFromPresenter(rootController, animated: false, thenEditor: false)
            return
        }

        // Keep showing the launch screen until we know which signin varient we want.
        let storyboard = UIStoryboard(name: "Launch Screen", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateInitialViewController()!
        let navController = NUXNavigationController(rootViewController: controller)
        navController.toolbarHidden = true

        rootController.presentViewController(navController, animated: false, completion: nil)

        // Load A/B tests.
        Mixpanel.sharedInstance().joinExperimentsWithCallback {
            SigninHelpers.showSigninControllerForABTest()
        }

        NSTimer.scheduledTimerWithTimeInterval(JoinABTestTimeoutInSeconds, target: SigninHelpers.self, selector: #selector(SigninHelpers.showSigninControllerForABTest), userInfo: nil, repeats: false)
    }


    /// Displays a variant of the sign in flow.
    /// Also checks if the visible view controller is already one of our test
    /// variants and if so returns early.
    ///
    class func showSigninControllerForABTest() {
        guard let rootController = WordPressAppDelegate.sharedInstance().window.rootViewController else {
            assertionFailure("Missing a rootViewController.")
            return
        }

        // If the presented controller is nil, or not a nux nav controller something isn't right so just bail.
        guard let navController = rootController.presentedViewController as? NUXNavigationController  else {
            assertionFailure("It would be very strange for the presented controller to *not* be our desired nav controller.")
            return
        }

        // If we're already showing one of the signin screens just bail.
        if let topViewController = navController.topViewController {
            if topViewController.isKindOfClass(NUXAbstractViewController.self) {
                return
            }
            if topViewController.isKindOfClass(LoginViewController.self) {
                return
            }
        }

        // Repurpose the already presented nav controller to show our nux varient.

        var controller: UIViewController
        if useNewSigninFlow() {
            controller = createControllerForNewSigninFlow(showsEditor: false)
        } else {
            controller = createControllerForOldSigninFlow(showsEditor: false)
        }

        navController.setViewControllers([controller], animated: false)
    }


    // Allows for A/B testing between the old and new signin flows.
    class func useNewSigninFlow() -> Bool {
        return MixpanelTweaks.NUXMagicLinksEnabled()
    }


    //MARK: - Helpers for presenting the signin flow


    // Convenience factory for the old LoginViewController
    class func createControllerForOldSigninFlow(showsEditor thenEditor: Bool) -> UIViewController {
        let context = ContextManager.sharedInstance().mainContext
        let accountService = AccountService(managedObjectContext: context)
        let blogService = BlogService(managedObjectContext: context)

        let hasWPcomAcctButNoSelfHostedBLogs = (accountService.defaultWordPressComAccount() != nil) && blogService.blogCountSelfHosted() == 0

        let controller = LoginViewController()
        controller.showEditorAfterAddingSites = thenEditor
        controller.cancellable = hasWPcomAcctButNoSelfHostedBLogs
        controller.dismissBlock = { [weak controller] (_) in
            controller?.dismissViewControllerAnimated(true, completion: nil)
        }
        return controller
    }


    // Convenience factory for the new signin flow's first vc
    class func createControllerForNewSigninFlow(showsEditor thenEditor: Bool) -> UIViewController {
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


    // Helper used by the app delegate
    class func showSigninFromPresenter(presenter: UIViewController, animated: Bool, thenEditor: Bool) {
        if useNewSigninFlow() {
            let controller = createControllerForNewSigninFlow(showsEditor: thenEditor)
            let navController = NUXNavigationController(rootViewController: controller)
            presenter.presentViewController(navController, animated: animated, completion: nil)

        } else {
            let controller = createControllerForOldSigninFlow(showsEditor: thenEditor)
            let navController = RotationAwareNavigationViewController(rootViewController: controller)
            navController.navigationBar.translucent = false
            presenter.presentViewController(navController, animated: animated, completion: nil)
        }
    }


    // Helper used by the MeViewController
    class func showSigninForJustWPComFromPresenter(presenter: UIViewController) {
        if useNewSigninFlow() {
            let controller = SigninEmailViewController.controller()
            controller.restrictSigninToWPCom = true

            let navController = NUXNavigationController(rootViewController: controller)
            presenter.presentViewController(navController, animated: true, completion: nil)
        } else {

            let controller = LoginViewController()
            controller.onlyDotComAllowed = true
            controller.cancellable = true
            controller.dismissBlock = { (_)in
                presenter.dismissViewControllerAnimated(true, completion: nil)
            }

            let navigation = RotationAwareNavigationViewController(rootViewController: controller)
            presenter.presentViewController(navigation, animated: true, completion: nil)
        }
    }


    // Helper used by the BlogListViewController
    class func showSigninForSelfHostedSite(presenter: UIViewController) {
        if useNewSigninFlow() {
            let controller = SigninSelfHostedViewController.controller(LoginFields())
            let navController = NUXNavigationController(rootViewController: controller)
            presenter.presentViewController(navController, animated: true, completion: nil)

        } else {
            let controller = LoginViewController()
            controller.cancellable = true
            controller.prefersSelfHosted = true
            controller.dismissBlock = {(_) in
                presenter.dismissViewControllerAnimated(true, completion: nil)
            }

            let navController = RotationAwareNavigationViewController(rootViewController: controller)
            presenter.presentViewController(navController, animated: true, completion: nil)
        }
    }


    // Helper used by WPAuthTokenIssueSolver
    class func signinForWPComFixingAuthToken(onDismissed: ((cancelled: Bool) -> Void)?) -> UIViewController {
        let context = ContextManager.sharedInstance().mainContext
        if useNewSigninFlow() {
            let loginFields = LoginFields()
            if let account = AccountService(managedObjectContext: context).defaultWordPressComAccount() {
                loginFields.username = account.username
            }

            let controller = SigninWPComViewController.controller(loginFields)
            controller.restrictSigninToWPCom = true
            controller.dismissBlock = onDismissed

            let navController = NUXNavigationController(rootViewController: controller)
            return navController

        } else {
            let blogService = BlogService(managedObjectContext: context)
            let cancellable = blogService.blogCountSelfHosted() > 0

            let controller = LoginViewController()
            controller.onlyDotComAllowed = true
            controller.shouldReauthenticateDefaultAccount = true
            controller.cancellable = cancellable
            controller.dismissBlock = {(cancelled) in
                onDismissed?(cancelled: cancelled)
            }

            return controller
        }
    }


    // Helper used by WPError
    class func showSigninForWPComFixingAuthToken() {
        let controller = signinForWPComFixingAuthToken(nil)
        if useNewSigninFlow() {
            let presenter = UIApplication.sharedApplication().keyWindow?.rootViewController
            let navController = NUXNavigationController(rootViewController: controller)
            presenter?.presentViewController(navController, animated: true, completion: nil)

        } else {
            LoginViewController.presentModalReauthScreen()
        }
    }


    // MARK: - Authentication Link Helpers


    /// Present a signin view controller to handle an authentication link.
    ///
    /// - Parameters:
    ///     - url: The authentication URL
    ///     - rootViewController: The view controller to act as the presenter for
    ///     the signin view controller. By convention this is the app's root vc.
    ///
    class func openAuthenticationURL(url: NSURL, fromRootViewController rootViewController: UIViewController) -> Bool {
        guard let token = url.query?.dictionaryFromQueryString().stringForKey("token") else {
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
            WPAppAnalytics.track(.LoginMagicLinkOpened)
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
        if let presenter = rootViewController.presentedViewController where presenter.isKindOfClass(NUXNavigationController.self) {
            rootViewController.dismissViewControllerAnimated(false, completion: {
                rootViewController.presentViewController(navController, animated: false, completion: nil)
            })
        } else {
            let presenter = controllerForAuthControllerPresenter(rootViewController)
            presenter.presentViewController(navController, animated: false, completion: nil)
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
    class func controllerForAuthControllerPresenter(controller: UIViewController) -> UIViewController {
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
    class func controllerWasPresentedFromRootViewController(controller: UIViewController) -> Bool {
        guard let presentingViewController = controller.presentingViewController else {
            return false
        }
        return presentingViewController == UIApplication.sharedApplication().keyWindow?.rootViewController
    }


    // MARK: - Site URL helper


    /// The base site URL path derived from `loginFields.siteUrl`
    ///
    /// - Parameter string: The source URL as a string.
    ///
    /// - Returns: The base URL or an empty string.
    ///
    class func baseSiteURL(string: String) -> String {
        guard let siteURL = NSURL(string: NSURL.IDNDecodedURL(string)) else {
            return ""
        }

        var path = siteURL.absoluteString.lowercaseString

        if path.isWordPressComPath() {
            if siteURL.scheme.characters.count == 0 {
                path = "https://\(path)"
            } else if path.rangeOfString("http://") != nil {
                path = path.stringByReplacingOccurrencesOfString("http://", withString: "https://")
            }
        } else if siteURL.scheme.characters.count == 0 {
            path = "http://\(path)"
        }

        path = path
            .trimSuffix(regexp: "/wp-login.php")
            .trimSuffix(regexp: "/wp-admin/?")
            .trimSuffix(regexp: "/?")

        return path
    }


    // MARK: - Validation Helpers


    /// Checks if the passed string matches a reserved username.
    ///
    /// - Parameter username: The username to test.
    ///
    class func isUsernameReserved(username: String) -> Bool {
        let name = username.lowercaseString.trim()
        return ["admin", "administrator", "root"].contains(name)
    }


    /// Checks whether credentials have been populated.
    /// Note: that loginFields.emailAddress is not checked. Use loginFields.username instead.
    ///
    /// - Parameter loginFields: An instance of LoginFields to check
    ///
    /// - Returns: True if credentails have been provided. False otherwise.
    ///
    class func validateFieldsPopulatedForSignin(loginFields: LoginFields) -> Bool {
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
    class func validateSiteForSignin(loginFields: LoginFields) -> Bool {
        guard let url = NSURL(string: NSURL.IDNEncodedURL(loginFields.siteUrl)) else {
            return false
        }

        if url.absoluteString.isEmpty {
            return false
        }

        return true
    }


    class func promptForWPComReservedUsername(username: String, callback: () -> Void) {
        let title = NSLocalizedString("Reserved Username", comment: "The title of a prompt")
        let format = NSLocalizedString("'%@' is a reserved username on WordPress.com.",
                                        comment: "Error message letting the user know the username they entered is reserved. The %@ is a placeholder for the username.")
        let message = NSString(format: format, username) as String
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("OK", comment: "OK Button Title"), handler: {(action) in
            callback()
        })
    }


    /// Checks whether necessary info for account creation has been provided.
    ///
    /// - Parameters:
    ///     - loginFields: An instance of LoginFields to check
    ///
    /// - Returns: True if credentails have been provided. False otherwise.
    ///
    class func validateFieldsPopulatedForCreateAccount(loginFields: LoginFields) -> Bool {
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
    class func validateFieldsForSigninContainNoSpaces(loginFields: LoginFields) -> Bool {
        let space = " "
        return !loginFields.emailAddress.containsString(space) &&
            !loginFields.username.containsString(space) &&
            !loginFields.siteUrl.containsString(space)
    }


    /// Verify a username is 50 characters or less.
    ///
    /// - Parameters:
    ///     - username: The username to check
    ///
    /// - Returns: True if the username is 50 characters or less.
    ///
    class func validateUsernameMaxLength(username: String) -> Bool {
        return username.characters.count <= 50
    }


    // MARK: - Helpers for Saved Magic Link Email


    /// Saves the specified email address in NSUserDefaults
    ///
    /// - Parameter email: The email address to save.
    ///
    class func saveEmailAddressForTokenAuth(email: String) {
        NSUserDefaults.standardUserDefaults().setObject(email, forKey: AuthenticationEmailKey)
    }


    /// Removes the saved email address from NSUserDefaults
    ///
    class func deleteEmailAddressForTokenAuth() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(AuthenticationEmailKey)
    }


    /// Fetches a saved email address if one exists.
    ///
    /// - Returns: The email address as a string or nil.
    ///
    class func getEmailAddressForTokenAuth() -> String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(AuthenticationEmailKey)
    }


    // MARK: - Other Helpers


    /// Opens Safari to display the forgot password page for a wpcom or self-hosted
    /// based on the passed LoginFields instance.
    ///
    /// - Parameter loginFields: A LoginFields instance.
    ///
    class func openForgotPasswordURL(loginFields: LoginFields) {
        let baseURL = loginFields.userIsDotCom ? "https://wordpress.com" : SigninHelpers.baseSiteURL(loginFields.siteUrl)
        let forgotPasswordURL = NSURL(string: baseURL + "/wp-login.php?action=lostpassword&redirect_to=wordpress%3A%2F%2F")!
        UIApplication.sharedApplication().openURL(forgotPasswordURL)
    }



    // MARK: - 1Password Helper


    /// Request credentails from 1Password (if supported)
    ///
    /// - Parameter sender: A UIView. Typically the button the user tapped on.
    ///
    class func fetchOnePasswordCredentials(controller: UIViewController, sourceView: UIView, loginFields: LoginFields, success: ((loginFields: LoginFields) -> Void)) {

        let loginURL = loginFields.userIsDotCom ? "wordpress.com" : loginFields.siteUrl

        let onePasswordFacade = OnePasswordFacade()
        onePasswordFacade.findLoginForURLString(loginURL, viewController: controller, sender: sourceView, completion: { (username: String?, password: String?, oneTimePassword: String?, error: NSError?) in
            if let error = error {
                DDLogSwift.logError("OnePassword Error: \(error.localizedDescription)")
                WPAppAnalytics.track(.OnePasswordFailed)
                return
            }

            guard let username = username, password = password else {
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

            WPAppAnalytics.track(.OnePasswordLogin)

            success(loginFields: loginFields)
        })

    }


    // MARK: - Safari Stored Credentials Helpers


    static let LoginSharedWebCredentialFQDN: CFString = "wordpress.com"
    typealias SharedWebCredentialsCallback = ((credentialsFound: Bool, username: String?, password: String?) -> Void)


    /// Update safari stored credentials.
    ///
    /// - Parameter loginFields: An instance of LoginFields
    ///
    class func updateSafariCredentialsIfNeeded(loginFields: LoginFields) {
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
        let username: CFString = loginFields.username
        let password: CFString = loginFields.password

        SecAddSharedWebCredential(LoginSharedWebCredentialFQDN, username, password, { (error: CFError?) in
            guard error == nil else {
                let err = error! as NSError
                DDLogSwift.logError("Error occurred updating shared web credential: \(err.localizedDescription)")
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                WPAppAnalytics.track(.LoginAutoFillCredentialsUpdated)
            })
        })
    }


    /// Request shared safari credentials if they exist.
    ///
    /// - Parameter completion: A completion block.
    ///
    class func requestSharedWebCredentials(completion: SharedWebCredentialsCallback) {
        SecRequestSharedWebCredential(LoginSharedWebCredentialFQDN, nil, { (credentials: CFArray?, error: CFError?) in
            DDLogSwift.logInfo("Completed requesting shared web credentials")
            guard error == nil else {
                let err = error! as NSError
                if err.code == -25300 {
                    // An OSStatus of -25300 is expected when no saved credentails are found.
                    DDLogSwift.logInfo("No shared web credenitals found.")
                } else {
                    DDLogSwift.logError("Error requesting shared web credentials: \(err.localizedDescription)")
                }
                dispatch_async(dispatch_get_main_queue(), {
                    completion(credentialsFound: false, username: nil, password: nil)
                })
                return
            }

            guard let credentials = credentials where CFArrayGetCount(credentials) > 0 else {
                // Saved credentials exist but were not selected.
                dispatch_async(dispatch_get_main_queue(), {
                    completion(credentialsFound: true, username: nil, password: nil)
                })
                return
            }

            // What a chore!
            let unsafeCredentials = CFArrayGetValueAtIndex(credentials, 0)
            let credentialsDict = unsafeBitCast(unsafeCredentials, CFDictionaryRef.self)

            let unsafeUsername = CFDictionaryGetValue(credentialsDict, unsafeAddressOf(kSecAttrAccount))
            let usernameStr = unsafeBitCast(unsafeUsername, CFString.self) as String

            let unsafePassword = CFDictionaryGetValue(credentialsDict, unsafeAddressOf(kSecSharedPassword))
            let passwordStr = unsafeBitCast(unsafePassword, CFString.self) as String

            dispatch_async(dispatch_get_main_queue(), {
                completion(credentialsFound: true, username: usernameStr, password: passwordStr)
            })
        })
    }
}
