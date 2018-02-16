import UIKit
import WordPressShared

/// Provides a form and functionality for signing a user in to WordPress.com
///
class LoginWPComViewController: LoginViewController, NUXKeyboardResponder {
    @IBOutlet weak var passwordField: WPWalkthroughTextField?
    @IBOutlet weak var forgotPasswordButton: UIButton?
    @IBOutlet weak var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet weak var verticalCenterConstraint: NSLayoutConstraint?
    @objc var onePasswordButton: UIButton!
    @IBOutlet var emailLabel: UILabel?
    @IBOutlet var emailStackView: UIStackView?
    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginWPComPassword
        }
    }

    override var loginFields: LoginFields {
        didSet {
            // Clear the password (if any) from LoginFields.
            loginFields.password = ""
        }
    }


    // MARK: - Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        setupOnePasswordButtonIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.meta.userIsDotCom = true

        configureTextFields()
        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

        passwordField?.becomeFirstResponder()
        WordPressAuthenticator.post(event: .loginPasswordFormViewed)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    // MARK: Setup and Configuration

    /// Sets up a 1Password button if 1Password is available.
    @objc func setupOnePasswordButtonIfNeeded() {
        guard let emailStackView = emailStackView else { return }
        WPStyleGuide.configureOnePasswordButtonForStackView(emailStackView,
                                                            target: self,
                                                            selector: #selector(LoginWPComViewController.handleOnePasswordButtonTapped(_:)))
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
        passwordField?.isEnabled = !loading

        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }


    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    @objc func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            passwordField?.becomeFirstResponder()
        }
    }

    @objc func configureTextFields() {
        passwordField?.text = loginFields.password
        passwordField?.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        emailLabel?.text = loginFields.username
    }

    @objc func localizeControls() {
        if let service = loginFields.meta.socialService, service == SocialServiceName.google {
            instructionLabel?.text = NSLocalizedString("To proceed with this Google account, please first log in with your WordPress.com password. This will only be asked once.", comment: "")
        } else {
            instructionLabel?.text = NSLocalizedString("Enter the password for your WordPress.com account.", comment: "Instructional text shown when requesting the user's password for login.")
        }

        passwordField?.placeholder = NSLocalizedString("Password", comment: "Password placeholder")
        passwordField?.accessibilityIdentifier = "Password"

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: UIControlState())
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)
        submitButton?.accessibilityIdentifier = "Log In Button"

        let forgotPasswordTitle = NSLocalizedString("Lost your password?", comment: "Title of a button. ")
        forgotPasswordButton?.setTitle(forgotPasswordTitle, for: UIControlState())
        forgotPasswordButton?.setTitle(forgotPasswordTitle, for: .highlighted)
        forgotPasswordButton?.titleLabel?.numberOfLines = 0
    }


    // MARK: - Instance Methods

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    @objc func validateForm() {
        validateFormAndLogin()
    }

    // MARK: - Actions

    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        guard let passwordField = passwordField else {
                return
        }

        loginFields.password = passwordField.nonNilTrimmedText()

        configureSubmitButton(animating: false)
    }

    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }

    @IBAction func handleForgotPasswordButtonTapped(_ sender: UIButton) {
        WordPressAuthenticator.openForgotPasswordURL(loginFields)
        WordPressAuthenticator.post(event: .loginForgotPasswordClicked)
    }

    @objc func handleOnePasswordButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        WordPressAuthenticator.fetchOnePasswordCredentials(self, sourceView: sender, loginFields: loginFields) { [weak self] (loginFields) in
            self?.emailLabel?.text = loginFields.username
            self?.passwordField?.text = loginFields.password
            self?.validateForm()
        }
    }

    override func displayRemoteError(_ error: Error!) {
        configureViewLoading(false)

        let errorCode = (error as NSError).code
        let errorDomain = (error as NSError).domain
        if errorDomain == WordPressComOAuthClient.WordPressComOAuthErrorDomain, errorCode == WordPressComOAuthError.invalidRequest.rawValue {
            let message = NSLocalizedString("It seems like you've entered an incorrect password. Want to give it another try?", comment: "An error message shown when a wpcom user provides the wrong password.")
            displayError(message: message)
        } else {
            super.displayRemoteError(error)
        }
    }


    // MARK: - Keyboard Notifications

    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }


    // MARK: Keyboard Events

    @objc func signinFormVerticalOffset() -> CGFloat {
        // the stackview-based layout shifts fine with this adjustment
        return 0
    }
}

extension LoginWPComViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if enableSubmit(animating: false) {
            validateForm()
        }
        return true
    }
}
