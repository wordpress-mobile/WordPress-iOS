import UIKit
import WordPressComAnalytics
import WordPressShared

/// Provides a form and functionality for signing a user in to WordPress.com
///
class LoginWPComViewController: LoginViewController, SigninKeyboardResponder {
    @IBOutlet weak var usernameField: WPWalkthroughTextField?
    @IBOutlet weak var passwordField: WPWalkthroughTextField?
    @IBOutlet weak var forgotPasswordButton: UIButton?
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet weak var verticalCenterConstraint: NSLayoutConstraint?
    var onePasswordButton: UIButton!
    @IBOutlet var emailLabel: UILabel?

    override var sourceTag: SupportSourceTag {
        get {
            return .wpComLogin
        }
    }

    // let the storyboard's style stay
    override func setupStyles() {}

    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        setupOnePasswordButtonIfNeeded()
        configureStatusLabel("")
        setupNavBarIcon()
        usernameField?.isHidden = true
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

        passwordField?.becomeFirstResponder()
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }

    // MARK: Setup and Configuration

    /// Sets up a 1Password button if 1Password is available.
    /// - note: this could move into NUXAbstractViewController or LoginViewController for better reuse
    func setupOnePasswordButtonIfNeeded() {
        guard let usernameField = usernameField else { return }
        WPStyleGuide.configureOnePasswordButtonForTextfield(usernameField,
                                                            target: self,
                                                            selector: #selector(SigninWPComViewController.handleOnePasswordButtonTapped(_:)))
    }

    /// Displays the specified text in the status label.
    ///
    /// - Parameter message: The text to display in the label.
    ///
    override func configureStatusLabel(_ message: String) {
        statusLabel?.text = message
    }

    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)
        submitButton?.isEnabled = enableSubmit(animating: animating)
    }

    override func enableSubmit(animating: Bool) -> Bool {
        return !animating &&
            !loginFields.username.isEmpty &&
            !loginFields.password.isEmpty
    }

    /// Configure the view's loading state.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override func configureViewLoading(_ loading: Bool) {
        usernameField?.isEnabled = !loading
        passwordField?.isEnabled = !loading

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
            passwordField?.becomeFirstResponder()
        }
    }

    // MARK: - Instance Methods

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    func validateForm() {
        view.endEditing(true)
        displayError(message: "")

        // Is everything filled out?
        if !SigninHelpers.validateFieldsPopulatedForSignin(loginFields) {
            let errorMsg = NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields.")
            displayError(message: errorMsg)

            return
        }

        configureViewLoading(true)

        loginFacade.signIn(with: loginFields)
    }

    // MARK: - Actions

    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        guard let usernameField = usernameField,
            let passwordField = passwordField else {
                return
        }

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

        SigninHelpers.fetchOnePasswordCredentials(self, sourceView: sender, loginFields: loginFields) { [weak self] (loginFields) in
            self?.usernameField?.text = loginFields.username
            self?.passwordField?.text = loginFields.password
            self?.validateForm()
        }
    }

    // MARK: - Keyboard Notifications

    func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }

    override func dismiss() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }

    func configureTextFields() {
        usernameField?.text = loginFields.username
        passwordField?.text = loginFields.password
        passwordField?.textInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        emailLabel?.text = usernameField?.text
    }

    func localizeControls() {
        passwordField?.placeholder = NSLocalizedString("Password", comment: "Password placeholder")
        passwordField?.accessibilityIdentifier = "Password"

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: UIControlState())
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)
        submitButton?.accessibilityIdentifier = "Log In Button"

        let forgotPasswordTitle = NSLocalizedString("Lost your password?", comment: "Title of a button. ")
        forgotPasswordButton?.setTitle(forgotPasswordTitle, for: UIControlState())
        forgotPasswordButton?.setTitle(forgotPasswordTitle, for: .highlighted)
    }
}

extension LoginWPComViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField?.becomeFirstResponder()
        } else if enableSubmit(animating: false) {
            validateForm()
        }
        return true
    }
}
