import UIKit

/// This is the first screen following the log in prologue screen if the user chooses to log in.
///
class LoginEmailViewController: NUXAbstractViewController, SigninKeyboardResponder, LoginViewController {
    @IBOutlet var instructionLabel: UILabel!
    @IBOutlet var emailTextField: WPWalkthroughTextField!
    @IBOutlet var submitButton: NUXSubmitButton!
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
            return .wpComLogin
        }
    }


    // MARK: Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBarIcon()

        localizeControls()
        setupOnePasswordButtonIfNeeded()
        configureForWPComOnlyIfNeeded()
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
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    // MARK: - Setup and Configuration


    // let the storyboard's style stay
    override func setupStyles() {}


    ///
    ///
    func configureForWPComOnlyIfNeeded() {
        selfHostedSigninButton.isHidden = restrictToWPCom
    }


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        instructionLabel.text = NSLocalizedString("Log in to WordPress.com using an email address to manage all your WordPress sites.", comment: "Instruction text on the login's email addresss screen.")

        emailTextField.placeholder = NSLocalizedString("Email address", comment: "Placeholder for a textfield. The user may enter their email address.")
        emailTextField.accessibilityIdentifier = "Email address"

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton.setTitle(submitButtonTitle, for: UIControlState())
        submitButton.setTitle(submitButtonTitle, for: .highlighted)
        submitButton.accessibilityIdentifier = "Next Button"

        let selfHostedTitle = NSLocalizedString("Log into your site by entering your site address instead.", comment: "A button title.")
        selfHostedSigninButton.setTitle(selfHostedTitle, for: UIControlState())
        selfHostedSigninButton.setTitle(selfHostedTitle, for: .highlighted)
        selfHostedSigninButton.titleLabel?.numberOfLines = 0;
    }


    /// Sets up a 1Password button if 1Password is available.
    ///
    func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(emailTextField,
                                                            target: self,
                                                            selector: #selector(handleOnePasswordButtonTapped(_:)))
    }


    /// Configures the email text field, updating its text based on what's stored
    /// in `loginFields`.
    ///
    func configureEmailField() {
        emailTextField.textInsets = UIEdgeInsetsMake(7, 20, 7, 20)
        emailTextField.text = loginFields.username
    }


    /// Configures whether appearance of the submit button.
    ///
    func configureSubmitButton() {
        submitButton.isEnabled = !loginFields.username.isEmpty
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    func configureViewLoading(_ loading: Bool) {
        emailTextField.isEnabled = !loading
        submitButton.isEnabled = !loading
        submitButton.showActivityIndicator(loading)
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

        signinWithUsernamePassword(false)

        WPAppAnalytics.track(.loginAutoFillCredentialsFilled)
    }


    /// Displays the wpcom sign in form, optionally telling it to immedately make
    /// the call to authenticate with the available credentials.
    ///
    /// - Parameters:
    ///     - immediateSignin: True if the newly loaded controller should immedately attempt
    ///                        to authenticate the user with the available credentails.  Default is `false`.
    ///
    func signinWithUsernamePassword(_ immediateSignin: Bool = false) {
        performSegue(withIdentifier: .showWPComLogin, sender: self)
    }


    /// Displays the self-hosted sign in form.
    ///
    func signinToSelfHostedSite() {
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
        let emailOrUsername = loginFields.username

        guard !emailOrUsername.isEmpty else {
            return
        }

        if emailOrUsername.isValidEmail() {
            validate(email: emailOrUsername)
        } else {
            validate(username: emailOrUsername)
        }
    }

    private func validate(email: String) {
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        configureViewLoading(true)

        service.isEmailAvailable(email,
                                 success: { [weak self] (available: Bool) in
                                    self?.configureViewLoading(false)
                                    if (available) {
                                        // No matching email address found so treat this as a
                                        // self-hosted sign in.
                                        self?.signinToSelfHostedSite()
                                    } else {
                                        self?.requestLink()
                                    }
            },
                                 failure: { [weak self] (error: Error) in
                                    DDLogSwift.logError(error.localizedDescription)
                                    guard let strongSelf = self else {
                                        return
                                    }
                                    strongSelf.configureViewLoading(false)
                                    strongSelf.displayError(error as NSError, sourceTag: strongSelf.sourceTag)
        })
    }

    private func validate(username: String) {
        if SigninHelpers.isWPComDomain(username) {
            signinWithWPComDomain(username)
        } else if !SigninHelpers.isUsernameReserved(username) {
            signinWithUsernamePassword()
        } else if restrictToWPCom {
            // When restricted, show a prompt then let the user enter a new username.
            SigninHelpers.promptForWPComReservedUsername(username, callback: {
                self.loginFields.username = ""
                self.emailTextField.text = ""
                self.emailTextField.becomeFirstResponder()
            })
        } else {
            // Switch to the signin flow when not restricted.
            signinToSelfHostedSite()
        }
    }

    private func signinWithWPComDomain(_ domain: String) {
        let showFailureError = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.displayErrorMessage(NSLocalizedString("Please enter a valid email address", comment: "A short prompt asking the user to properly fill out all login fields."))
        }

        let username = SigninHelpers.extractUsername(from: domain)
        configureViewLoading(true)

        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.isUsernameAvailable(username,
                                    success: { [weak self] (available: Bool) in
                                        guard let strongSelf = self else {
                                            return
                                        }
                                        strongSelf.configureViewLoading(false)
                                        if (available) {
                                            // can't login with a username that doesn't exist
                                            showFailureError()
                                        } else {
                                            strongSelf.loginFields.username = username
                                            strongSelf.signinWithUsernamePassword()
                                        }
            },
                                    failure: { [weak self] (error: Error) in
                                        showFailureError()
                                        if let strongSelf = self {
                                            strongSelf.configureViewLoading(false)
                                        }
        })
    }


    // MARK: - Actions


    @IBAction func handleSubmitForm() {
        validateForm()
    }


    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }


    func handleOnePasswordButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        SigninHelpers.fetchOnePasswordCredentials(self, sourceView: sender, loginFields: loginFields) { [weak self] (loginFields) in
            self?.emailTextField.text = loginFields.username
            self?.signinWithUsernamePassword(true)
        }
    }


    @IBAction func handleSelfHostedButtonTapped(_ sender: UIButton) {
        signinToSelfHostedSite()
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
