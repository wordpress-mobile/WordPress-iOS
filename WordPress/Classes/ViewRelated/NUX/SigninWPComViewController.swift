import UIKit
import WordPressComAnalytics
import WordPressShared

/// Provides a form and functionality for signing a user in to WordPress.com
///
@objc class SigninWPComViewController: NUXAbstractViewController, SigninWPComSyncHandler, SigninKeyboardResponder {

    @IBOutlet weak var usernameField: WPWalkthroughTextField!
    @IBOutlet weak var passwordField: WPWalkthroughTextField!
    @IBOutlet weak var submitButton: NUXSubmitButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var selfHostedButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet weak var verticalCenterConstraint: NSLayoutConstraint?
    var onePasswordButton: UIButton!

    override var sourceTag: SupportSourceTag {
        get {
            return .wpComLogin
        }
    }

    var immediateSignin = false

    override var restrictToWPCom: Bool {
        didSet {
            if isViewLoaded {
                configureForWPComOnlyIfNeeded()
            }
        }
    }

    lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()


    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    /// - Parameters:
    ///     - loginFields: A LoginFields instance containing any prefilled credentials.
    ///     - immediateSignin: Whether the controller should attempt to signin immediately.
    ///
    class func controller(_ loginFields: LoginFields, immediateSignin: Bool = false) -> SigninWPComViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "SigninWPComViewController") as! SigninWPComViewController
        controller.loginFields = loginFields
        controller.immediateSignin = immediateSignin
        return controller
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        setupOnePasswordButtonIfNeeded()
        configureStatusLabel("")
        configureForWPComOnlyIfNeeded()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.userIsDotCom = true

        configureTextFields()
        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(SigninEmailViewController.handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(SigninEmailViewController.handleKeyboardWillHide(_:)))

        if immediateSignin {
            validateForm()
            immediateSignin = false
        }
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    // MARK: Setup and Configuration


    ///
    ///
    func configureForWPComOnlyIfNeeded() {
        selfHostedButton.isHidden = restrictToWPCom
    }


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        usernameField.placeholder = NSLocalizedString("Email or username", comment: "Username placeholder")
        usernameField.accessibilityIdentifier = "Email or username"
        passwordField.placeholder = NSLocalizedString("Password", comment: "Password placeholder")
        passwordField.accessibilityIdentifier = "Password"

        let submitButtonTitle = NSLocalizedString("Log In", comment: "Title of a button. The text should be uppercase.").localizedUppercase
        submitButton.setTitle(submitButtonTitle, for: UIControlState())
        submitButton.setTitle(submitButtonTitle, for: .highlighted)
        submitButton.accessibilityIdentifier = "Log In Button"

        let forgotPasswordTitle = NSLocalizedString("Lost your password?", comment: "Title of a button. ")
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: UIControlState())
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: .highlighted)

        let selfHostedTitle = NSLocalizedString("Add a self-hosted WordPress site", comment: "Title of a button. ")
        selfHostedButton.setTitle(selfHostedTitle, for: UIControlState())
        selfHostedButton.setTitle(selfHostedTitle, for: .highlighted)
    }


    /// Sets up a 1Password button if 1Password is available.
    ///
    func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(usernameField,
                                                            target: self,
                                                            selector: #selector(SigninWPComViewController.handleOnePasswordButtonTapped(_:)))
    }


    /// Configures the content of the text fields based on what is saved in `loginFields`.
    ///
    func configureTextFields() {
        usernameField.text = loginFields.username
        passwordField.text = loginFields.password
    }


    /// Displays the specified text in the status label.
    ///
    /// - Parameter message: The text to display in the label.
    ///
    ///
    func configureStatusLabel(_ message: String) {
        statusLabel.text = message
    }


    /// Configures the appearance and state of the submit button.
    ///
    func configureSubmitButton(animating: Bool) {
        submitButton.showActivityIndicator(animating)

        submitButton.isEnabled = (
            !animating &&
                !loginFields.username.isEmpty &&
                !loginFields.password.isEmpty
        )
    }


    /// Configure the view's loading state.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    func configureViewLoading(_ loading: Bool) {
        usernameField.isEnabled = !loading
        passwordField.isEnabled = !loading

        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }


    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            passwordField.becomeFirstResponder()
        }
    }


    // MARK: - Instance Methods


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

        // If the username is not reserved proceed with the signin
        if SigninHelpers.isUsernameReserved(loginFields.username) {
            handleReservedUsername(loginFields.username)
            return
        }

        configureViewLoading(true)

        loginFacade.signIn(with: loginFields)
    }


    /// Shows a prompt to the user regarding a reserved username.
    ///
    /// - Parameters:
    ///     - username: The username that was entered.
    ///
    func handleReservedUsername(_ username: String) {
        // If we're restricted to wpcom, just prmopt that the name is reserved.
        if restrictToWPCom {
            SigninHelpers.promptForWPComReservedUsername(username, callback: {
                self.loginFields.username = ""
                self.usernameField.text = ""
                self.usernameField.becomeFirstResponder()
            })
            return
        }

        // When not restricted to wpcom, prompt then switch to the self-hsoted flow.
        let alert = UIAlertController(title: NSLocalizedString("Self-hosted Site?", comment: "Title of a notice to the user."),
                                      message: NSLocalizedString("It looks like you're signing in to a self-hosted site.  Enter your site's URL on the next screen.", comment: "A brief notice to the user. Explaining the next step when signing in."),
                                      preferredStyle: .alert)
        alert.addDefaultActionWithTitle(NSLocalizedString("OK", comment: "A button label. Tapping dismisses a prompt."), handler: { (action: UIAlertAction) in
            self.signinToSelfHostedSite()
        })
        present(alert, animated: true, completion: nil)
    }


    /// Update safari stored credentials. Call after a successful sign in.
    ///
    func updateSafariCredentialsIfNeeded() {
        SigninHelpers.updateSafariCredentialsIfNeeded(loginFields)
    }


    func signinToSelfHostedSite() {
        let controller = SigninSelfHostedViewController.controller(loginFields)
        controller.dismissBlock = dismissBlock
        navigationController?.pushViewController(controller, animated: true)
    }


    // MARK: - Actions


    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        loginFields.username = usernameField.nonNilTrimmedText()
        loginFields.password = passwordField.nonNilTrimmedText()

        configureSubmitButton(animating: false)
    }


    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }


    @IBAction func handleForgotPasswordButtonTapped(_ sender: UIButton) {
        SigninHelpers.openForgotPasswordURL(loginFields)
    }


    func handleOnePasswordButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        SigninHelpers.fetchOnePasswordCredentials(self, sourceView: sender, loginFields: loginFields) { [unowned self] (loginFields) in
            self.usernameField.text = loginFields.username
            self.passwordField.text = loginFields.password
            self.validateForm()
        }
    }


    @IBAction func handleSelfHostedButtonTapped(_ sender: UIButton) {
        signinToSelfHostedSite()
    }


    // MARK: - Keyboard Notifications


    func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}


extension SigninWPComViewController: LoginFacadeDelegate {

    func finishedLogin(withUsername username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        syncWPCom(username, authToken: authToken, requiredMultifactor: requiredMultifactorCode)
    }


    func displayLoginMessage(_ message: String!) {
        configureStatusLabel(message)
    }


    func displayRemoteError(_ error: Error!) {
        configureStatusLabel("")
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
        controller.dismissBlock = dismissBlock
        navigationController?.pushViewController(controller, animated: true)
    }
}


extension SigninWPComViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else if submitButton.isEnabled {
            validateForm()
        }
        return true
    }
}
