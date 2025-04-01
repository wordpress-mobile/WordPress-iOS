import UIKit
import WordPressShared
import WordPressKit

/// Provides a form and functionality for signing a user in to WordPress.com
///
class LoginWPComViewController: LoginViewController, NUXKeyboardResponder {
    @IBOutlet weak var passwordField: WPWalkthroughTextField?
    @IBOutlet weak var forgotPasswordButton: UIButton?
    @IBOutlet weak var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet weak var verticalCenterConstraint: NSLayoutConstraint?
    @IBOutlet var emailIcon: UIImageView?
    @IBOutlet var emailLabel: UITextField?
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.meta.userIsDotCom = true

        configureTextFields()
        configureEmailIcon()
        configureForgotPasswordButton()
        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

        passwordField?.becomeFirstResponder()
        WordPressAuthenticator.track(.loginPasswordFormViewed)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()

        if isMovingFromParent {
            // There was a bug that was causing iOS's update password prompt to come up
            // when this VC was being dismissed pressing the "< Back" button.  The following
            // line ensures that such prompt doesn't come up anymore.
            //
            // More information can be found in the PR where this workaround is introduced:
            //  https://git.io/JUkak
            //
            passwordField?.text = ""
        }
    }

    // MARK: Setup and Configuration

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
        emailLabel?.textColor = WordPressAuthenticator.shared.style.subheadlineColor
    }

    func configureEmailIcon() {
        guard let image = emailIcon?.image else {
            return
        }
        emailIcon?.image = image.imageWithTintColor(WordPressAuthenticator.shared.style.subheadlineColor)
    }

    private func configureForgotPasswordButton() {
        guard let forgotPasswordButton else {
            return
        }
        WPStyleGuide.configureTextButton(forgotPasswordButton)
    }

    @objc func localizeControls() {

        instructionLabel?.text = {
            guard let service = loginFields.meta.socialService else {
                return NSLocalizedString("Enter the password for your WordPress.com account.", comment: "Instructional text shown when requesting the user's password for login.")
            }

            if service == SocialServiceName.google {
                return NSLocalizedString("To proceed with this Google account, please first log in with your WordPress.com password. This will only be asked once.", comment: "")
            }

            return NSLocalizedString(
                "Please enter the password for your WordPress.com account to log in with your Apple ID.",
                comment: "Instructional text shown when requesting the user's password for a login initiated via Sign In with Apple"
            )
        }()

        passwordField?.placeholder = NSLocalizedString("Password", comment: "Password placeholder")
        passwordField?.accessibilityIdentifier = "Password"

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: .normal)
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)
        submitButton?.accessibilityIdentifier = "Password Next Button"

        let forgotPasswordTitle = NSLocalizedString("Lost your password?", comment: "Title of a button. ")
        forgotPasswordButton?.setTitle(forgotPasswordTitle, for: .normal)
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
        switch sender {
        case passwordField:
            loginFields.password = sender.nonNilTrimmedText()
        case emailLabel:
            // The email can only be changed via a password manager.
            // In this case, don't update username for social accounts.
            // This prevents inadvertent account linking.
            // Ref: https://git.io/JJSUM
            if loginFields.meta.socialService != nil {
                emailLabel?.text = loginFields.username
            } else {
                loginFields.username = sender.nonNilTrimmedText()
            }
        default:
            break
        }

        configureSubmitButton(animating: false)
    }

    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }

    @IBAction func handleForgotPasswordButtonTapped(_ sender: UIButton) {
        WordPressAuthenticator.openForgotPasswordURL(loginFields)
        WordPressAuthenticator.track(.loginForgotPasswordClicked)
    }

    override func displayRemoteError(_ error: Error) {
        configureViewLoading(false)

        if (error as? WordPressComOAuthError)?.authenticationFailureKind == .invalidRequest {
            let message = NSLocalizedString("It seems like you've entered an incorrect password. Want to give it another try?", comment: "An error message shown when a wpcom user provides the wrong password.")
            displayError(message: message)
        } else {
            super.displayRemoteError(error)
        }
    }

    // MARK: - Dynamic type

    override func didChangePreferredContentSize() {
        super.didChangePreferredContentSize()
        emailLabel?.font = WPStyleGuide.fontForTextStyle(.body)
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

extension LoginWPComViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            didChangePreferredContentSize()
        }
    }
}
