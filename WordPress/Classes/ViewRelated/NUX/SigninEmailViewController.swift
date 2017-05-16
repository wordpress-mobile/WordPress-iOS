import UIKit
import WordPressComAnalytics
import WordPressShared

/// This vc is the entry point for the normal sign in flow.
///
/// - Note: The sign in flow should be managed b ya NUXNavigationController for
/// appearance reasons.
/// By convention the NUXNavigationController should be presented
/// from UIApplication.sharedApplication.keyWindow.rootViewController to ensure
/// that the final step in the magic link auth flow can be performed correctly.
///
@objc class SigninEmailViewController: NUXAbstractViewController, SigninKeyboardResponder {

    @IBOutlet var emailTextField: WPWalkthroughTextField!
    @IBOutlet var submitButton: NUXSubmitButton!
    @IBOutlet var createSiteButton: UIButton!
    @IBOutlet var selfHostedSigninButton: UIButton!
    @IBOutlet var safariPasswordButton: UIButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint!
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint!
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

    /// A convenience method for obtaining an instance of the controller from a storyboard.
    ///
    /// - Parameter loginFields: Optional. A LoginFields instance containing any prefilled credentials.
    ///
    class func controller(_ loginFields: LoginFields? = nil) -> SigninEmailViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "SigninEmailViewController") as! SigninEmailViewController
        controller.loginFields = loginFields == nil ? LoginFields() : loginFields!
        return controller
    }


    // MARK: Lifecycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        setupOnePasswordButtonIfNeeded()
        configureSafariPasswordButton(false)
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

        registerForKeyboardEvents(keyboardWillShowAction: #selector(SigninEmailViewController.handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(SigninEmailViewController.handleKeyboardWillHide(_:)))
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    // MARK: - Setup and Configuration


    ///
    ///
    func configureForWPComOnlyIfNeeded() {
        selfHostedSigninButton.isHidden = restrictToWPCom
    }


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        emailTextField.placeholder = NSLocalizedString("Email or username", comment: "Placeholder for a textfield. The user may enter their email address or their username.")
        emailTextField.accessibilityIdentifier = "Email or username"

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be uppercase.").localizedUppercase
        submitButton.setTitle(submitButtonTitle, for: UIControlState())
        submitButton.setTitle(submitButtonTitle, for: .highlighted)
        submitButton.accessibilityIdentifier = "Next Button"

        let safariButtonTitle = NSLocalizedString("Log in with Safari saved password", comment: "`Safari saved password` is the name of the iOS feature for saving a password for the Safari browser to use later.")
        safariPasswordButton.setTitle(safariButtonTitle, for: UIControlState())
        safariPasswordButton.setTitle(safariButtonTitle, for: .highlighted)

        let createSiteTitle = NSLocalizedString("Create a site", comment: "A button title")
        createSiteButton.setTitle(createSiteTitle, for: UIControlState())
        createSiteButton.setTitle(createSiteTitle, for: .highlighted)

        let selfHostedTitle = NSLocalizedString("Add a self-hosted WordPress site", comment: "A button title.")
        selfHostedSigninButton.setTitle(selfHostedTitle, for: UIControlState())
        selfHostedSigninButton.setTitle(selfHostedTitle, for: .highlighted)
    }


    /// Sets up a 1Password button if 1Password is available.
    ///
    func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(emailTextField,
                                                            target: self,
                                                            selector: #selector(SigninEmailViewController.handleOnePasswordButtonTapped(_:)))
    }


    /// Configures the button for requesting Safari stored credentials.
    /// The button should only be visible if Safari stored credentials are available.
    ///
    func configureSafariPasswordButton(_ animated: Bool) {
        if safariPasswordButton.isHidden != didFindSafariSharedCredentials {
            return
        }

        if !animated {
            safariPasswordButton.isHidden = !didFindSafariSharedCredentials
            return
        }

        UIView.animate(withDuration: 0.2,
                                   delay: 0.0,
                                   options: .beginFromCurrentState,
                                   animations: {
                                        self.safariPasswordButton.isHidden = !self.didFindSafariSharedCredentials
                                    },
                                   completion: nil)
    }


    /// Configures the email text field, updating its text based on what's stored
    /// in `loginFields`.
    ///
    func configureEmailField() {
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
        configureSafariPasswordButton(true)

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
        let controller = SigninWPComViewController.controller(loginFields, immediateSignin: immediateSignin)
        controller.dismissBlock = dismissBlock
        controller.restrictToWPCom = restrictToWPCom
        navigationController?.pushViewController(controller, animated: true)
    }


    /// Displays the self-hosted sign in form.
    ///
    func signinToSelfHostedSite() {
        let controller = SigninSelfHostedViewController.controller(loginFields)
        controller.dismissBlock = dismissBlock
        navigationController?.pushViewController(controller, animated: true)
    }


    /// Proceeds along the "magic link" sign-in flow, showing a form that let's
    /// the user request a magic link.
    ///
    func requestLink() {
        let controller = SigninLinkRequestViewController.controller(loginFields)
        controller.dismissBlock = dismissBlock
        controller.restrictToWPCom = restrictToWPCom
        navigationController?.pushViewController(controller, animated: true)
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
            strongSelf.displayErrorMessage(NSLocalizedString("Please enter a valid username or email address", comment: "A short prompt asking the user to properly fill out all login fields."))
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


    @IBAction func handleCreateSiteButtonTapped(_ sender: UIButton) {
        let controller = SignupViewController.controller()
        navigationController?.pushViewController(controller, animated: true)

        WPAppAnalytics.track(.createAccountInitiated)
    }


    @IBAction func handleSafariPasswordButtonTapped(_ sender: UIButton) {
        fetchSharedWebCredentialsIfAvailable()
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
