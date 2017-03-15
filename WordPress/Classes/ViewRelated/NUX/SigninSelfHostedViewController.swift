import UIKit
import WordPressShared

/// Provides a form and functionality to sign-in and add an existing self-hosted
/// site to the app.
///
@objc class SigninSelfHostedViewController: NUXAbstractViewController, SigninKeyboardResponder, SigninWPComSyncHandler {
    @IBOutlet weak var usernameField: WPWalkthroughTextField!
    @IBOutlet weak var passwordField: WPWalkthroughTextField!
    @IBOutlet weak var siteURLField: WPWalkthroughTextField!
    @IBOutlet weak var submitButton: NUXSubmitButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var forgotPasswordButton: WPNUXSecondaryButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint!
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint!
    var onePasswordButton: UIButton!

    lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()

    override var sourceTag: SupportSourceTag {
        get {
            return .wpOrgLogin
        }
    }

    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    /// - Parameter loginFields: A LoginFields instance containing any prefilled credentials.
    ///
    class func controller(_ loginFields: LoginFields) -> SigninSelfHostedViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "SigninSelfHostedViewController") as! SigninSelfHostedViewController
        controller.loginFields = loginFields
        return controller
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        setupOnePasswordButtonIfNeeded()
        displayLoginMessage("")
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.userIsDotCom = false

        configureTextFields()
        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(SigninEmailViewController.handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(SigninEmailViewController.handleKeyboardWillHide(_:)))

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    // MARK: Setup and Configuration


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        usernameField.placeholder = NSLocalizedString("Username / Email", comment: "Username placeholder")
        passwordField.placeholder = NSLocalizedString("Password", comment: "Password placeholder")
        siteURLField.placeholder = NSLocalizedString("Site Address (URL)", comment: "Site Address placeholder")

        let submitButtonTitle = NSLocalizedString("Add Site", comment: "Title of a button. The text should be uppercase.").localizedUppercase
        submitButton.setTitle(submitButtonTitle, for: UIControlState())
        submitButton.setTitle(submitButtonTitle, for: .highlighted)

        let forgotPasswordTitle = NSLocalizedString("Lost your password?", comment: "Title of a button. ")
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: UIControlState())
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: .highlighted)
    }


    /// Sets up a 1Password button if 1Password is available.
    ///
    func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(usernameField,
                                                            target: self,
                                                            selector: #selector(SigninSelfHostedViewController.handleOnePasswordButtonTapped(_:)))
    }


    /// Configures the content of the text fields based on what is saved in `loginFields`.
    ///
    func configureTextFields() {
        usernameField.text = loginFields.username
        passwordField.text = loginFields.password
        siteURLField.text = loginFields.siteUrl
    }


    /// Displays the specified text in the status label.
    ///
    /// - Parameters:
    ///     - message: The text to display in the label.
    ///
    func configureStatusLabel(_ message: String) {
        statusLabel.text = message
    }


    /// Configures the appearance and state of the forgot password button.
    ///
    func configureForgotPasswordButton() {
        forgotPasswordButton.isHidden = loginFields.siteUrl.isEmpty || submitButton.isAnimating
    }


    /// Configures the appearance and state of the submit button.
    ///
    func configureSubmitButton(animating: Bool) {
        submitButton.showActivityIndicator(animating)

        submitButton.isEnabled = (
            !animating &&
            !loginFields.username.isEmpty &&
            !loginFields.password.isEmpty &&
            !loginFields.siteUrl.isEmpty
        )
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    func configureViewLoading(_ loading: Bool) {
        usernameField.isEnabled = !loading
        passwordField.isEnabled = !loading
        siteURLField.isEnabled = !loading

        configureSubmitButton(animating: loading)
        configureForgotPasswordButton()
        navigationItem.hidesBackButton = loading
    }


    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            usernameField.becomeFirstResponder()
        }
    }


    // MARK: - Instance Methods


    ///
    ///
    func updateSafariCredentialsIfNeeded() {
        // Noop.  Required by the SigninWPComSyncHandler protocol but the self-hosted
        // controller's implementation does not use safari saved credentials.
    }


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    func validateForm() {
        view.endEditing(true)

        // Is everything filled out?
        if !SigninHelpers.validateFieldsPopulatedForSignin(loginFields) {
            WPError.showAlert(withTitle: NSLocalizedString("Error", comment: "Title of an error message"),
                                       message: NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields."),
                                       withSupportButton: false)

            return
        }

        // Was a valid site URL entered.
        if !SigninHelpers.validateSiteForSignin(loginFields) {
            WPError.showAlert(withTitle: NSLocalizedString("Error", comment: "Title of an error message"),
                                       message: NSLocalizedString("The site's URL appears to be mistyped", comment: "A short prompt alerting to a misformatted URL"),
                                       withSupportButton: false)

            return
        }

        configureViewLoading(true)

        loginFacade.signIn(with: loginFields)
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


    // MARK: - Actions


    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        loginFields.username = usernameField.nonNilTrimmedText()
        loginFields.password = passwordField.nonNilTrimmedText()
        loginFields.siteUrl = SigninHelpers.baseSiteURL(string: siteURLField.nonNilTrimmedText())

        configureForgotPasswordButton()
        configureSubmitButton(animating: false)
    }


    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }


    func handleOnePasswordButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        if loginFields.userIsDotCom == false && loginFields.siteUrl.isEmpty {
            displayOnePasswordEmptySiteAlert()
            return
        }

        SigninHelpers.fetchOnePasswordCredentials(self, sourceView: sender, loginFields: loginFields) { [unowned self] (loginFields) in
            self.usernameField.text = loginFields.username
            self.passwordField.text = loginFields.password
            self.validateForm()
        }
    }


    @IBAction func handleForgotPasswordButtonTapped(_ sender: UIButton) {
        SigninHelpers.openForgotPasswordURL(loginFields)
    }


    // MARK: - Keyboard Notifications


    func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}


extension SigninSelfHostedViewController: LoginFacadeDelegate {

    func finishedLogin(withUsername username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        syncWPCom(username, authToken: authToken, requiredMultifactor: requiredMultifactorCode)
    }


    func finishedLogin(withUsername username: String!, password: String!, xmlrpc: String!, options: [AnyHashable: Any]!) {
        displayLoginMessage("")

        BlogSyncFacade().syncBlog(withUsername: username, password: password, xmlrpc: xmlrpc, options: options) { [weak self] in
            self?.configureViewLoading(false)

            let context = ContextManager.sharedInstance().mainContext
            let service = BlogService(managedObjectContext: context)
            if let blog = service.findBlog(withXmlrpc: xmlrpc, andUsername: username) {
                RecentSitesService().touch(blog: blog)
            }

            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: SigninHelpers.WPSigninDidFinishNotification), object: nil)

            self?.dismiss()
        }
    }


    func displayLoginMessage(_ message: String!) {
        configureStatusLabel(message)
        configureForgotPasswordButton()
    }


    func displayRemoteError(_ error: Error!) {
        displayLoginMessage("")
        configureViewLoading(false)
        displayError(error as NSError, sourceTag: sourceTag)
    }


    func needsMultifactorCode() {
        configureStatusLabel("")
        configureViewLoading(false)

        WPAppAnalytics.track(.twoFactorCodeRequested)
        // Credentials were good but a 2fa code is needed.
        loginFields.shouldDisplayMultifactor = true // technically not needed
        let controller = Signin2FAViewController.controller(loginFields)
        navigationController?.pushViewController(controller, animated: true)
    }
}


extension SigninSelfHostedViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            siteURLField.becomeFirstResponder()
        } else if submitButton.isEnabled {
            validateForm()
        }
        return true
    }
}
