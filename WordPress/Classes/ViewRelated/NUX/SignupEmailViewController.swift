import UIKit

class SignupEmailViewController: NUXAbstractViewController, SigninKeyboardResponder {

    // MARK: - SigninKeyboardResponder Properties

    @IBOutlet weak var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet weak var verticalCenterConstraint: NSLayoutConstraint?

    // MARK: - Properties

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var emailField: LoginTextField!
    @IBOutlet weak var nextButton: LoginButton!

    override var sourceTag: SupportSourceTag {
        get {
            return .wpComSignupEmail
        }
    }

    enum AlertMessage: String {
        case invalidEmail = "invalid_email"
        case availabilityCheckFail = "availability_check_fail"
        case emailUnavailable = "email_unavailable"

        func description() -> String {
            switch self {
            case .invalidEmail:
                return NSLocalizedString("Please enter a valid email address.", comment: "Error message displayed when the user attempts use an invalid email address.")
            case .availabilityCheckFail:
                return NSLocalizedString("An error occurred processing the request. Please try again later.", comment: "Error message displayed when an error occurred checking for email availability.")
            case .emailUnavailable:
                return NSLocalizedString("Sorry, that email address is already being used!", comment: "Error message displayed when the entered email is not available.")
            }
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        configureView()
        setupNextButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureViewForEditingIfNeeded()
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

    private func setupNavBar() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                           target: self,
                                           action: #selector(handleCancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton
        addWordPressLogoToNavController()
        _ = addHelpButtonToNavController()
    }

    private func configureView() {
        WPStyleGuide.configureColors(for: view, andTableView: nil)

        instructionLabel.text = NSLocalizedString("To create your new WordPress.com account, please enter your email address.", comment: "Text instructing the user to enter their email address.")

        emailField.placeholder = NSLocalizedString("Email address", comment: "Placeholder for a textfield. The user may enter their email address.")
        emailField.accessibilityIdentifier = "Email address"
    }

    private func setupNextButton() {
        nextButton.isEnabled = false
        let nextButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        nextButton?.setTitle(nextButtonTitle, for: UIControlState())
        nextButton?.setTitle(nextButtonTitle, for: .highlighted)
        nextButton?.accessibilityIdentifier = "Next Button"
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

    // MARK: - Keyboard Notifications

    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }

    // MARK: - Email Validation

    private func validateForm() {

        // If the email address is invalid, display appropriate message.
        if !validEmail(emailField.text) {
            displayErrorAlert(AlertMessage.invalidEmail.description(), sourceTag: sourceTag)
            return
        }

        checkEmailAvailability() { available in
            if available {
                let message = "Email: '\(self.emailField.text!)'\nThis is a work in progress. If you need to create a site, disable the siteCreation feature flag."
                let alertController = UIAlertController(title: nil,
                                                        message: message,
                                                        preferredStyle: .alert)
                alertController.addDefaultActionWithTitle("OK")
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }

    fileprivate func validEmail(_ email: String?) -> Bool {
        guard let email = email else {
            return false
        }
        return EmailFormatValidator.validate(string: email)
    }

    // MARK: - Email Availability

    func checkEmailAvailability(completion:@escaping (Bool) -> ()) {

        // If cannot get Remote, display generic error message.
        guard let remote = AccountServiceRemoteREST(wordPressComRestApi: WordPressComRestApi(oAuthToken: nil, userAgent: nil)) else {
            self.displayErrorAlert(AlertMessage.availabilityCheckFail.description(), sourceTag: sourceTag)
            completion(false)
            return
        }

        remote.isEmailAvailable(emailField.text, success: { available in
            if !available {
                // If email address is unavailable, display appropriate message.
                self.displayErrorAlert(AlertMessage.emailUnavailable.description(), sourceTag: self.sourceTag)
            }
            completion(available)
        }, failure: { error in
            if let error = error {
                DDLogError("Error checking email availability: \(error.localizedDescription)")
            }
            // If check failed, display generic error message.
            self.displayErrorAlert(AlertMessage.availabilityCheckFail.description(), sourceTag: self.sourceTag)
            completion(false)
        })
    }

    // MARK: - Button Handling

    @IBAction func nextButtonPressed(_ sender: Any) {
        view.endEditing(true)
        validateForm()
    }

    @IBAction func handleEmailSubmit() {
        if validEmail(emailField.text) {
            view.endEditing(true)
            validateForm()
        }
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - UITextFieldDelegate

extension SignupEmailViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let updatedString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
        nextButton.isEnabled = validEmail(updatedString)
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        nextButton.isEnabled = validEmail(textField.text)
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        nextButton.isEnabled = validEmail(textField.text)
    }

}
