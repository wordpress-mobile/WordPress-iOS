import UIKit

class LoginWPComViewController: SigninWPComViewController, LoginViewController {
    @IBOutlet var emailLabel: UILabel?

    // let the storyboard's style stay
    override func setupStyles() {}

    override func dismiss() {
        self.performSegue(withIdentifier: .showEpilogue, sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarIcon()
        usernameField.isHidden = true
        selfHostedButton.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(SigninEmailViewController.handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(SigninEmailViewController.handleKeyboardWillHide(_:)))

        passwordField.becomeFirstResponder()
    }

    override func configureTextFields() {
        super.configureTextFields()
        passwordField.textInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        emailLabel?.text = usernameField.text
    }

    override func needsMultifactorCode() {
        configureStatusLabel("")
        configureViewLoading(false)

        WPAppAnalytics.track(.twoFactorCodeRequested)
        self.performSegue(withIdentifier: .show2FA, sender: self)
    }

    override func localizeControls() {
        passwordField.placeholder = NSLocalizedString("Password", comment: "Password placeholder")
        passwordField.accessibilityIdentifier = "Password"

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton.setTitle(submitButtonTitle, for: UIControlState())
        submitButton.setTitle(submitButtonTitle, for: .highlighted)
        submitButton.accessibilityIdentifier = "Log In Button"

        let forgotPasswordTitle = NSLocalizedString("Lost your password?", comment: "Title of a button. ")
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: UIControlState())
        forgotPasswordButton.setTitle(forgotPasswordTitle, for: .highlighted)
    }

    /// Sets the text of the error label.
    /// - Note: this should become part of LoginViewController -nh
    ///
    func displayError(message: String) {
        statusLabel.text = message
    }

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    override func validateForm() {
        view.endEditing(true)
        displayError(message: "")

        // Is everything filled out?
        if !SigninHelpers.validateFieldsPopulatedForSignin(loginFields) {
            let errorMsg = NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields.")
            displayError(message: errorMsg)

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

    override func displayLoginMessage(_ message: String!) {
        // no-op
    }

    override func displayRemoteError(_ error: Error!) {
        configureViewLoading(false)

        guard (error as NSError).code != 403 else {
            let message = NSLocalizedString("It seems like you've entered an incorrect password. Want to give it another try?", comment: "An error message shown when a wpcom user provides the wrong password.")
            displayError(message: message)
            return
        }

        displayError(error as NSError, sourceTag: sourceTag)
    }
}
