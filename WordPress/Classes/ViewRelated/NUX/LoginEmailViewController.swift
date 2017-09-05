import UIKit
import GoogleSignIn

/// This is the first screen following the log in prologue screen if the user chooses to log in.
///
class LoginEmailViewController: LoginViewController, SigninKeyboardResponder {
    @IBOutlet var emailTextField: WPWalkthroughTextField!
    @IBOutlet var selfHostedSigninButton: UIButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint?
    var onePasswordButton: UIButton!

    var didFindSafariSharedCredentials = false
    var didRequestSafariSharedCredentials = false
    override var restrictToWPCom: Bool {
        didSet {
            if isViewLoaded {
                configureForWPComOnlyIfNeeded()
            }
        }
    }

    override var sourceTag: SupportSourceTag {
        get {
            return .loginEmail
        }
    }

    private struct Constants {
        static let googleButtonOffset: CGFloat = 5.0
    }


    // MARK: Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        setupOnePasswordButtonIfNeeded()
        configureForWPComOnlyIfNeeded()
        addGoogleButton()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // The old create account vc hides the nav bar, so make sure its always visible.
        navigationController?.setNavigationBarHidden(false, animated: false)

        // Update special case login fields.
        loginFields.userIsDotCom = true

        configureEmailField()
        configureSubmitButton()
        configureViewForEditingIfNeeded()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        assert(SigninHelpers.controllerWasPresentedFromRootViewController(self),
               "Only present parts of the magic link signin flow from the application's root vc.")

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

        WPAppAnalytics.track(.loginEmailFormViewed)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    // MARK: - Setup and Configuration


    /// Hides the self-hosted login option.
    ///
    func configureForWPComOnlyIfNeeded() {
        if restrictToWPCom {
            selfHostedSigninButton.isEnabled = false
            selfHostedSigninButton.alpha = 0.0
        } else {
            selfHostedSigninButton.isEnabled = true
            selfHostedSigninButton.alpha = 1.0
        }
    }


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        instructionLabel?.text = NSLocalizedString("Log in to WordPress.com using an email address to manage all your WordPress sites.", comment: "Instruction text on the login's email addresss screen.")

        emailTextField.placeholder = NSLocalizedString("Email address", comment: "Placeholder for a textfield. The user may enter their email address.")
        emailTextField.accessibilityIdentifier = "Email address"

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: UIControlState())
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)
        submitButton?.accessibilityIdentifier = "Next Button"

        let selfHostedTitle = NSLocalizedString("Log into your site by entering your site address instead.", comment: "A button title.")
        selfHostedSigninButton.setTitle(selfHostedTitle, for: UIControlState())
        selfHostedSigninButton.setTitle(selfHostedTitle, for: .highlighted)
        selfHostedSigninButton.titleLabel?.numberOfLines = 0
    }


    /// Sets up a 1Password button if 1Password is available.
    ///
    func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(emailTextField,
                                                            target: self,
                                                            selector: #selector(handleOnePasswordButtonTapped(_:)))
    }

    /// Add the log in with Google button to the view
    func addGoogleButton() {
        guard Feature.enabled(.googleLogin) else {
            return
        }

        let button = UIButton.googleLoginButton()
        view.addSubview(button)
        button.addTarget(self, action: #selector(googleLoginTapped), for: .touchUpInside)

        view.addConstraints([
            button.topAnchor.constraint(equalTo: self.emailTextField.bottomAnchor, constant: Constants.googleButtonOffset),
            button.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            button.centerXAnchor.constraint(equalTo: emailTextField.centerXAnchor)
        ])
    }

    func googleLoginTapped() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().clientID = ApiCredentials.googleLoginClientId()

        GIDSignIn.sharedInstance().signIn()
    }


    /// Configures the email text field, updating its text based on what's stored
    /// in `loginFields`.
    ///
    func configureEmailField() {
        emailTextField.textInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        emailTextField.text = loginFields.username
    }


    /// Configures whether appearance of the submit button.
    ///
    func configureSubmitButton() {
        submitButton?.isEnabled = canSubmit()
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override func configureViewLoading(_ loading: Bool) {
        emailTextField.isEnabled = !loading
        submitButton?.isEnabled = !loading
        submitButton?.showActivityIndicator(loading)
    }


    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            emailTextField.becomeFirstResponder()
        }
    }


    // MARK: - Instance Methods


    /// Makes the call to retrieve Safari shared credentials if they exist.
    ///
    func fetchSharedWebCredentialsIfAvailable() {
        didRequestSafariSharedCredentials = true
        SigninHelpers.requestSharedWebCredentials { [weak self] (found, username, password) in
            self?.handleFetchedWebCredentials(found, username: username, password: password)
        }
    }


    /// Handles Safari shared credentials if any where found.
    ///
    /// - Parameters:
    ///     - found: True if credentails were found.
    ///     - username: The selected username or nil.
    ///     - password: The selected password or nil.
    ///
    func handleFetchedWebCredentials(_ found: Bool, username: String?, password: String?) {
        didFindSafariSharedCredentials = found

        guard let username = username, let password = password else {
            return
        }

        // Update the login fields
        loginFields.username = username
        loginFields.password = password

        // Persist credentials as autofilled credentials so we can update them later if needed.
        loginFields.safariStoredUsernameHash = username.hash
        loginFields.safariStoredPasswordHash = password.hash

        loginWithUsernamePassword(immediately: true)

        WPAppAnalytics.track(.loginAutoFillCredentialsFilled)
    }


    /// Displays the wpcom sign in form, optionally telling it to immedately make
    /// the call to authenticate with the available credentials.
    ///
    /// - Parameters:
    ///     - immediately: True if the newly loaded controller should immedately attempt
    ///                        to authenticate the user with the available credentails.  Default is `false`.
    ///
    func loginWithUsernamePassword(immediately: Bool = false) {
        if (immediately) {
            validateFormAndLogin()
        } else {
            performSegue(withIdentifier: .showWPComLogin, sender: self)
        }
    }


    /// Displays the self-hosted sign in form.
    ///
    func loginToSelfHostedSite() {
        performSegue(withIdentifier: .showSelfHostedLogin, sender: self)
    }


    /// Proceeds along the "magic link" sign-in flow, showing a form that let's
    /// the user request a magic link.
    ///
    func requestLink() {
        performSegue(withIdentifier: .startMagicLinkFlow, sender: self)
    }


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    func validateForm() {
        displayError(message: "")
        guard EmailFormatValidator.validate(string: loginFields.username) else {
            assertionFailure("Form should not be submitted unless there is a valid looking email entered.")
            return
        }

        configureViewLoading(true)
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.isPasswordlessAccount(loginFields.username,
                                      success: { [weak self] (passwordless: Bool) in
                                        self?.configureViewLoading(false)
                                        self?.loginFields.passwordless = passwordless
                                        self?.requestLink()
            },
                                      failure: { [weak self] (error: Error) in
                                        WPAppAnalytics.track(.loginFailed, error: error)
                                        DDLogError(error.localizedDescription)
                                        guard let strongSelf = self else {
                                            return
                                        }
                                        strongSelf.configureViewLoading(false)

                                        let userInfo = (error as NSError).userInfo
                                        if let errorCode = userInfo[WordPressComRestApi.ErrorKeyErrorCode] as? String, errorCode == "unknown_user" {
                                            let msg = NSLocalizedString("This email address is not registered on WordPress.com.",
                                                                        comment: "An error message informing the user the email address they entered did not match a WordPress.com account.")
                                            self?.displayError(message: msg)
                                        } else {
                                            strongSelf.displayError(error as NSError, sourceTag: strongSelf.sourceTag)
                                        }
        })
    }

    override func displayRemoteError(_ error: Error!) {
        configureViewLoading(false)

        errorToPresent = error
        performSegue(withIdentifier: .showWPComLogin, sender: self)
    }


    /// Whether the form can be submitted.
    ///
    func canSubmit() -> Bool {
        return EmailFormatValidator.validate(string: loginFields.username)
    }


    // MARK: - Actions


    @IBAction func handleSubmitForm() {
        if canSubmit() {
            validateForm()
        }
    }


    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }


    func handleOnePasswordButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        SigninHelpers.fetchOnePasswordCredentials(self, sourceView: sender, loginFields: loginFields) { [weak self] (loginFields) in
            self?.emailTextField.text = loginFields.username
            self?.loginWithUsernamePassword(immediately: true)
        }
    }


    @IBAction func handleSelfHostedButtonTapped(_ sender: UIButton) {
        loginToSelfHostedSite()
    }


    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        loginFields.username = emailTextField.nonNilTrimmedText()
        configureSubmitButton()
    }


    @IBAction func handleTextFieldEditingDidBegin(_ sender: UITextField) {
        if !didRequestSafariSharedCredentials {
            fetchSharedWebCredentialsIfAvailable()
        }
    }


    // MARK: - Keyboard Notifications


    func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }

}

extension LoginEmailViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        let alert = UIAlertController(title: "Login Success", message: "You successfully logged in with Google", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok, Great. Thanks.", style: .default, handler: { [weak self] (action) in
            self?.dismiss(animated: true){}
        }))
    }
}

extension LoginEmailViewController: GIDSignInUIDelegate {
}
