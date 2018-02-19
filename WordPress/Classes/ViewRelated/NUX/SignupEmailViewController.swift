import UIKit

class SignupEmailViewController: LoginViewController, NUXKeyboardResponder {

    // MARK: - SigninKeyboardResponder Properties

    @IBOutlet weak var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet weak var verticalCenterConstraint: NSLayoutConstraint?

    // MARK: - Properties

    @IBOutlet weak var emailField: LoginTextField!

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComSignupEmail
        }
    }

    private enum ErrorMessage: String {
        case invalidEmail = "invalid_email"
        case availabilityCheckFail = "availability_check_fail"
        case emailUnavailable = "email_unavailable"

        func description() -> String {
            switch self {
            case .invalidEmail:
                return NSLocalizedString("Please enter a valid email address.", comment: "Error message displayed when the user attempts use an invalid email address.")
            case .availabilityCheckFail:
                return NSLocalizedString("Unable to verify the email address. Please try again later.", comment: "Error message displayed when an error occurred checking for email availability.")
            case .emailUnavailable:
                return NSLocalizedString("Sorry, that email address is already being used!", comment: "Error message displayed when the entered email is not available.")
            }
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: nil)
        localizeControls()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureViewForEditingIfNeeded()
        configureSubmitButton(animating: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }

    private func localizeControls() {
        instructionLabel?.text = NSLocalizedString("To create your new WordPress.com account, please enter your email address.", comment: "Text instructing the user to enter their email address.")

        emailField.placeholder = NSLocalizedString("Email address", comment: "Placeholder for a textfield. The user may enter their email address.")
        emailField.accessibilityIdentifier = "Email address"
        emailField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: UIControlState())
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)
        submitButton?.accessibilityIdentifier = "Next Button"
    }

    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    private func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            emailField.becomeFirstResponder()
        }
    }

    override func enableSubmit(animating: Bool) -> Bool {
        return !animating && validEmail()
    }

    // MARK: - Keyboard Notifications

    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }

    // MARK: - Email Validation

    private func validateForm() {

        // Hide the error label.
        displayError(message: "")

        // If the email address is invalid, display appropriate message.
        if !validEmail() {
            displayError(message: ErrorMessage.invalidEmail.description())
            configureSubmitButton(animating: false)
            return
        }

        checkEmailAvailability() { available in
            if available {
                // TODO: send Magic Link email via new endpoint.
                self.loginFields.username = self.loginFields.emailAddress
                self.loginFields.meta.emailMagicLinkSource = .signup
                self.performSegue(withIdentifier: "showLinkMailView", sender: nil)
            }
            self.configureSubmitButton(animating: false)
        }
    }

    private func validEmail() -> Bool {
        return EmailFormatValidator.validate(string: loginFields.emailAddress)
    }

    // MARK: - Email Availability

    private func checkEmailAvailability(completion:@escaping (Bool) -> ()) {

        // If cannot get Remote, display generic error message.
        guard let remote = AccountServiceRemoteREST(wordPressComRestApi: WordPressComRestApi()) else {
            DDLogError("Error creating AccountServiceRemoteREST instance.")
            self.displayError(message: ErrorMessage.availabilityCheckFail.description())
            completion(false)
            return
        }

        remote.isEmailAvailable(loginFields.emailAddress, success: { available in
            if !available {
                // If email address is unavailable, display appropriate message.
                self.displayError(message: ErrorMessage.emailUnavailable.description())
            }
            completion(available)
        }, failure: { error in
            if let error = error {
                DDLogError("Error checking email availability: \(error.localizedDescription)")
            }
            // If check failed, display generic error message.
            self.displayError(message: ErrorMessage.availabilityCheckFail.description())
            completion(false)
        })
    }

    // MARK: - Action Handling

    @IBAction func handleSubmit() {
        configureSubmitButton(animating: true)
        validateForm()
    }

    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        loginFields.emailAddress = emailField.nonNilTrimmedText()
        configureSubmitButton(animating: false)
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
