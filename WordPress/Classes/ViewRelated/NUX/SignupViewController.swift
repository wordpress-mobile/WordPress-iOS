import UIKit
import WordPressComAnalytics
import WordPressShared


/// Create a new WordPress.com account and blog.
///
@objc class SignupViewController: NUXAbstractViewController, SigninKeyboardResponder {
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailField: WPWalkthroughTextField!
    @IBOutlet weak var usernameField: WPWalkthroughTextField!
    @IBOutlet weak var passwordField: WPWalkthroughTextField!
    @IBOutlet weak var siteURLField: WPWalkthroughTextField!
    @IBOutlet weak var submitButton: NUXSubmitButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint!
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet var topLayoutGuideAdjustmentConstraint: NSLayoutConstraint!
    @IBOutlet var formTopMarginConstraint: NSLayoutConstraint!
    var onePasswordButton: UIButton!
    var didCorrectEmailOnce: Bool = false
    var userDefinedSiteAddress: Bool = false
    let operationQueue = OperationQueue()
    var account: WPAccount?

    let LanguageIDKey = "lang_id"
    let BlogDetailsKey = "blog_details"
    let BlogNameLowerCaseNKey = "blogname"
    let BlogNameUpperCaseNKey = "blogName"
    let XMLRPCKey = "xmlrpc"
    let BlogIDKey = "blogid"
    let URLKey = "url"
    let nonAlphanumericCharacterSet = NSCharacterSet.alphanumerics.inverted

    override var sourceTag: SupportSourceTag {
        get {
            return .wpComSignup
        }
    }

    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    class func controller() -> SignupViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        return controller
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        configureTermsButtonText()
        setupOnePasswordButtonIfNeeded()
        displayLoginMessage("")
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.userIsDotCom = true

        configureLayoutForSmallScreensIfNeeded()
        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(SignupViewController.handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(SignupViewController.handleKeyboardWillHide(_:)))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    // MARK: Setup and Configuration


    /// Adjust the layout for smaller screens, specifically the iPhone 4s
    ///
    func configureLayoutForSmallScreensIfNeeded() {
        if !shouldAdjustLayoutForSmallScreen() {
            return
        }

        // Remove the negative layout adjustment
        topLayoutGuideAdjustmentConstraint.constant = 0
        // Hide the logo
        logoImageView.isHidden = true
        // Remove the title label to also remove unwanted constraints.
        if titleLabel.superview != nil {
            titleLabel.removeFromSuperview()
        }
    }


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        titleLabel.text = NSLocalizedString("Create an account on WordPress.com", comment: "Title of a screen")
        emailField.placeholder = NSLocalizedString("Email Address", comment: "Email address placeholder")
        usernameField.placeholder = NSLocalizedString("Username", comment: "Username placeholder")
        passwordField.placeholder = NSLocalizedString("Password", comment: "Password placeholder")
        siteURLField.placeholder = NSLocalizedString("Site Address (URL)", comment: "Site Address placeholder")

        let submitButtonTitle = NSLocalizedString("Create Account", comment: "Title of a button. The text should be uppercase.").localizedUppercase
        submitButton.setTitle(submitButtonTitle, for: UIControlState())
        submitButton.setTitle(submitButtonTitle, for: .highlighted)
    }


    /// Sets up a 1Password button if 1Password is available.
    ///
    func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(usernameField,
                                                            target: self,
                                                            selector: #selector(SignupViewController.handleOnePasswordButtonTapped(_:)))
    }


    /// Configures the appearance of the Terms button.
    ///
    func configureTermsButtonText() {
        let string = NSLocalizedString("By creating an account you agree to the fascinating <u>Terms of Service</u>.",
                                       comment: "Message displayed when a verification code is needed")
        let options: [String: Any] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue
        ]

        let styledString = "<style>body {font-family: -apple-system, sans-serif; font-size:13px; color: #ffffff; text-align:center;}</style>" + string

        guard let data = styledString.data(using: String.Encoding.utf8),
            let attributedCode = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil),
            let attributedCodeHighlighted = attributedCode.mutableCopy() as? NSMutableAttributedString
            else {
                return
        }

        attributedCodeHighlighted.applyForegroundColor(WPNUXUtility.confirmationLabelColor())

        if let titleLabel = termsButton.titleLabel {
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 3
        }

        termsButton.setAttributedTitle(attributedCode, for: UIControlState())
        termsButton.setAttributedTitle(attributedCodeHighlighted, for: .highlighted)
    }


    /// Configures the appearance and state of the submit button.
    ///
    func configureSubmitButton(animating: Bool) {
        submitButton.showActivityIndicator(animating)

        submitButton.isEnabled = (
            !animating &&
                !loginFields.emailAddress.isEmpty &&
                !loginFields.username.isEmpty &&
                !loginFields.password.isEmpty &&
                !loginFields.siteUrl.isEmpty
        )
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameters:
    ///     - loading: True if the form should be configured to a "loading" state.
    ///
    func configureLoading(_ loading: Bool) {
        emailField.isEnabled = !loading
        usernameField.isEnabled = !loading
        passwordField.isEnabled = !loading
        siteURLField.isEnabled = !loading

        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }


    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            emailField.becomeFirstResponder()
        }
    }


    // MARK: - Instance Methods


    /// Whether the view layout should be adjusted for smaller screens
    ///
    /// - Returns true if the window height matches the height of the iPhone 4s (480px).
    /// NOTE: NUX layout assumes a portrait orientation only.
    ///
    func shouldAdjustLayoutForSmallScreen() -> Bool {
        guard let window = UIApplication.shared.keyWindow else {
            return false
        }

        return window.frame.height <= 480
    }


    /// Displays an alert prompting that a site address is needed before 1Password can be used.
    ///
    func displayOnePasswordEmptySiteAlert() {
        let message = NSLocalizedString("A site address is required before 1Password can be used.",
                                        comment: "Error message displayed when the user is Signing into a self hosted site and tapped the 1Password Button before typing his siteURL")

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addCancelActionWithTitle(NSLocalizedString("OK", comment: "OK Button Title"), handler: nil)

        present(alertController, animated: true, completion: nil)
    }


    /// Display an authentication status message
    ///
    /// - Parameters:
    ///     - message: The message to display
    ///
    func displayLoginMessage(_ message: String!) {
        statusLabel.text = message
    }


    /// Display an authentication status message
    ///
    /// - Parameters:
    ///     - message: The message to display
    ///
    /// - Returns: the generated username
    ///
    func generateSiteTitleFromUsername(_ username: String) -> String {
        // Currently, we set the title of a new site to the username of the account.
        // Another possibility would be to name the site "username's blog", which is
        // why this has been placed in a separate method.
        return username
    }

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    func validateForm() {
        view.endEditing(true)

        // Is everything filled out?
        if !SigninHelpers.validateFieldsPopulatedForCreateAccount(loginFields) {
            displayErrorMessage(NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields."))
            return
        }

        if !SigninHelpers.validateFieldsForSigninContainNoSpaces(loginFields) {
            displayErrorMessage(NSLocalizedString("Email, Username, and Site Address cannot contain spaces.", comment: "No spaces error message."))
            return
        }

        if !SigninHelpers.validateUsernameMaxLength(loginFields.username) {
            displayErrorMessage(NSLocalizedString("Username must be less than fifty characters.", comment: "Prompts that the username entered was too long."))
            usernameField.becomeFirstResponder()
            return
        }

        if !loginFields.emailAddress.isValidEmail() {
            displayErrorMessage(NSLocalizedString("Please enter a valid email address", comment: "A short prompt asking the user to properly fill out all login fields."))
            emailField.becomeFirstResponder()
            return
        }

        // Remove ".wordpress.com" if it was entered.
        loginFields.siteUrl = loginFields.siteUrl.components(separatedBy: ".")[0]

        configureLoading(true)

        createAccountAndSite()
    }


    /// Because the signup form is larger than the average sign in form and has
    /// a header, we want to tweak the vertical offset a bit rather than use
    /// the default.
    /// However, on a small screen we remove some UI elements so return the default size.
    ///
    /// - Returns: The offset to apply to the form
    ///
    func signinFormVerticalOffset() -> CGFloat {
        if shouldAdjustLayoutForSmallScreen() {
            return DefaultSigninFormVerticalOffset
        }
        return -24.0
    }


    /// Create the account and the site. Call this after everything passes validation.
    ///
    func createAccountAndSite() {
        let statusBlock = { (status: SignupStatus) in
            self.displayLoginMessageForStatus(status)
        }

        let successBlock = {
            self.displayLoginMessage("")
            self.configureLoading(false)
            self.dismiss()
        }

        let failureBlock = { (error: Error?) in
            self.displayLoginMessage("")
            self.configureLoading(false)
            if let error = error as NSError? {
                self.displayError(error, sourceTag: self.sourceTag)
            }
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = SignupService(managedObjectContext: context)
        service.createBlogAndSigninToWPCom(blogURL: loginFields.siteUrl,
                                           blogTitle: loginFields.username,
                                           emailAddress: loginFields.emailAddress,
                                           username: loginFields.username,
                                           password: loginFields.password,
                                           status: statusBlock,
                                           success: successBlock,
                                           failure: failureBlock)
    }


    /// Display a status message for the specified SignupStatus
    ///
    /// - Paramaters:
    ///     - status: SignupStatus
    ///
    func displayLoginMessageForStatus(_ status: SignupStatus) {
        switch status {
        case .validating :
            displayLoginMessage(NSLocalizedString("Validating", comment: "Short status message shown to the user when validating a new blog's name."))
            break

        case .creatingUser :
            displayLoginMessage(NSLocalizedString("Creating account", comment: "Brief status message shown to the user when creating a new wpcom account."))
            break

        case .authenticating :
            displayLoginMessage(NSLocalizedString("Authenticating", comment: "Brief status message shown when signing into a newly created blog and account."))
            break

        case .creatingBlog :
            displayLoginMessage(NSLocalizedString("Creating site", comment: "Short status message shown while a new site is being created for a new user."))
            break

        case .syncing :
            displayLoginMessage(NSLocalizedString("Syncing account information", comment: "Short status message shown while blog and account information is being synced."))
            break

        }
    }


    // MARK: - Actions


    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        // Ensure that username and site fields are lower cased.
        if sender == usernameField || sender == siteURLField {
            sender.text = sender.text?.lowercased()
        }

        loginFields.emailAddress = emailField.nonNilTrimmedText()
        loginFields.username = usernameField.nonNilTrimmedText()
        loginFields.password = passwordField.nonNilTrimmedText()
        loginFields.siteUrl = siteURLField.nonNilTrimmedText()

        configureSubmitButton(animating: false)
    }


    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }


    func handleOnePasswordButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        OnePasswordFacade().createLogin(forURLString: WPOnePasswordWordPressComURL,
                                                    username: loginFields.username,
                                                    password: loginFields.password,
                                                    for: self,
                                                    sender: sender,
                                                    completion: { (username, password, error: Error?) in
                                                        if let error = error as NSError? {
                                                            if error.code != WPOnePasswordErrorCodeCancelledByUser {
                                                                DDLogSwift.logError("Failed to use 1Password App Extension to save a new Login: \(error)")
                                                                WPAnalytics.track(.onePasswordFailed)
                                                            }
                                                            return
                                                        }
                                                        if let username = username {
                                                            self.loginFields.username = username
                                                            self.usernameField.text = username
                                                        }
                                                        if let password = password {
                                                            self.loginFields.password = password
                                                            self.passwordField.text = password
                                                        }

                                                        WPAnalytics.track(.onePasswordSignup)

                                                        // Note: Since the Site field is right below the 1Password field, let's continue with the edition flow
                                                        // and make the SiteAddress Field the first responder.
                                                        self.siteURLField.becomeFirstResponder()

        })
    }


    @IBAction func handleTermsOfServiceButtonTapped(_ sender: UIButton) {
        let url = URL(string: WPAutomatticTermsOfServiceURL)
        let controller = WPWebViewController(url: url)
        let navController = RotationAwareNavigationViewController(rootViewController: controller!)
        present(navController, animated: true, completion: nil)
    }


    // MARK: - Keyboard Notifications


    func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}


extension SignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            usernameField.becomeFirstResponder()
        } else if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            siteURLField.becomeFirstResponder()
        } else if submitButton.isEnabled {
            validateForm()
        }
        return true
    }


    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField != emailField || didCorrectEmailOnce {
            return true
        }

        guard let email = textField.text else {
            return true
        }

        let suggestedEmail = EmailTypoChecker.guessCorrection(email: email)
        if suggestedEmail != textField.text {
            textField.text = suggestedEmail
            didCorrectEmailOnce = true
            loginFields.emailAddress = textField.nonNilTrimmedText()
        }
        return true
    }


    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField != usernameField || userDefinedSiteAddress {
            return
        }
        // If the user has not customized the site name, then let it match the
        // username they chose.
        loginFields.siteUrl = loginFields.username
        siteURLField.text = loginFields.username
    }


    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Disallow spaces except for the password field
        if string == " " && (textField == emailField || textField == usernameField || textField == siteURLField) {
            return false
        }

        // Disallow punctuation in username and site names
        if (textField == usernameField || textField == siteURLField) {
            if (string as NSString).rangeOfCharacter(from: nonAlphanumericCharacterSet).location != NSNotFound {
                return false
            }
        }

        if textField == siteURLField {
            userDefinedSiteAddress = true
        }

        return true
    }
}
