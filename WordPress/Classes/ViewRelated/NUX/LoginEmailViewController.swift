import UIKit

/// This is the first screen following the log in prologue screen if the user chooses to log in.
///
class LoginEmailViewController: NUXAbstractViewController, SigninKeyboardResponder, LoginViewController {
    @IBOutlet var instructionLabel: UILabel!
    @IBOutlet var errorLabel: UILabel!
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

        WPAppAnalytics.track(.loginEmailFormViewed)
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


    /// Let the storyboard's style stay
    /// TODO: Nuke this and the super implementation once the old signin controllers
    /// go away. 2017.06.13 - Aerych
    override func setupStyles() {}


    /// Hides the self-hosted login option.
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
        selfHostedSigninButton.titleLabel?.numberOfLines = 0
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
        emailTextField.textInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        emailTextField.text = loginFields.username
    }


    /// Configures whether appearance of the submit button.
    ///
    func configureSubmitButton() {
        submitButton.isEnabled = canSubmit()
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

        loginWithUsernamePassword(false)

        WPAppAnalytics.track(.loginAutoFillCredentialsFilled)
    }


    /// Displays the wpcom sign in form, optionally telling it to immedately make
    /// the call to authenticate with the available credentials.
    ///
    /// - Parameters:
    ///     - immediately: True if the newly loaded controller should immedately attempt
    ///                        to authenticate the user with the available credentails.  Default is `false`.
    ///
    func loginWithUsernamePassword(_ immediately: Bool = false) {
        // TODO: Need to implement the `immediately` portion of this once one wpcom controllers are done.
        performSegue(withIdentifier: .showWPComLogin, sender: self)
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
        guard loginFields.username.isValidEmail() else {
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


    /// Sets the text of the error label.
    ///
    func displayError(message: String) {
        errorLabel.text = message
    }


    /// Whether the form can be submitted.
    ///
    func canSubmit() -> Bool {
        return loginFields.username.isValidEmail()
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
            self?.loginWithUsernamePassword(true)
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
