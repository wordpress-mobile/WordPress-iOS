import UIKit
import WordPressShared


class SignupEmailViewController: LoginViewController, NUXKeyboardResponder {

    // MARK: - NUXKeyboardResponder Properties

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
        case magicLinkRequestFail = "magic_link_request_fail"

        func description() -> String {
            switch self {
            case .invalidEmail:
                return NSLocalizedString("Please enter a valid email address.", comment: "Error message displayed when the user attempts use an invalid email address.")
            case .availabilityCheckFail:
                return NSLocalizedString("Unable to verify the email address. Please try again later.", comment: "Error message displayed when an error occurred checking for email availability.")
            case .emailUnavailable:
                return NSLocalizedString("Sorry, that email address is already being used!", comment: "Error message displayed when the entered email is not available.")
            case .magicLinkRequestFail:
                return NSLocalizedString("We were unable to send you an email at this time. Please try again later.", comment: "Error message displayed when an error occurred sending the magic link email.")
            }
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: nil)
        localizeControls()
        WordPressAuthenticator.track(.createAccountInitiated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureViewForEditingIfNeeded()

        // If email address already exists, pre-populate it.
        emailField.text = loginFields.emailAddress

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
                self.loginFields.username = self.loginFields.emailAddress
                self.loginFields.meta.emailMagicLinkSource = .signup
                self.requestAuthenticationLink()
            }
            self.configureSubmitButton(animating: false)
        }
    }

    private func validEmail() -> Bool {
        return EmailFormatValidator.validate(string: loginFields.emailAddress)
    }

    // MARK: - Email Availability

    private func checkEmailAvailability(completion:@escaping (Bool) -> ()) {

        let remote = AccountServiceRemoteREST(wordPressComRestApi: WordPressComRestApi())

        remote.isEmailAvailable(loginFields.emailAddress, success: { available in
            if !available {
                defer {
                    WPAppAnalytics.track(.signupEmailToLogin)
                }
                // If the user has already signed up redirect to the Login flow
                self.performSegue(withIdentifier: .showEmailLogin, sender: self)
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        // Configure login flow to allow only .com login and prefill the email
        if let destination = segue.destination as? LoginEmailViewController {
            destination.restrictToWPCom = true
            destination.loginFields.username = loginFields.emailAddress
        }
    }

    // MARK: - Send email

    /// Makes the call to request a magic signup link be emailed to the user.
    ///
    private func requestAuthenticationLink() {

        configureSubmitButton(animating: true)

        let service = WordPressComAccountService()
        service.requestSignupLink(for: loginFields.username,
                                  success: { [weak self] in
                                    self?.didRequestSignupLink()
                                    self?.configureSubmitButton(animating: false)

            }, failure: { [weak self] (error: Error) in
                DDLogError("Request for signup link email failed.")
                WordPressAuthenticator.track(.signupMagicLinkFailed)
                self?.displayError(message: ErrorMessage.magicLinkRequestFail.description())
                self?.configureSubmitButton(animating: false)
        })
    }

    private func didRequestSignupLink() {
        WordPressAuthenticator.track(.signupMagicLinkRequested)
        WordPressAuthenticator.storeLoginInfoForTokenAuth(loginFields)
        performSegue(withIdentifier: "showLinkMailView", sender: nil)
    }

    // MARK: - Action Handling

    @IBAction func handleSubmit() {
        displayError(message: "")
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
